import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Shop, ShopDocument } from '../shops/schemas/shop.schema';
import { Product, ProductDocument } from '../products/schemas/product.schema';
import { Order, OrderDocument } from '../orders/schemas/order.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { UpdateDistributorProfileDto } from './dto/distributor-profile.dto';
import { UpdateDistributorStatusDto } from './dto/distributor-status.dto';
import { CreateDistributorProductDto, UpdateDistributorProductDto } from './dto/distributor-inventory.dto';

@Injectable()
export class DistributorsService {
  private readonly logger = new Logger(DistributorsService.name);

  constructor(
    @InjectModel(Shop.name) private readonly shopModel: Model<ShopDocument>,
    @InjectModel(Product.name) private readonly productModel: Model<ProductDocument>,
    @InjectModel(Order.name) private readonly orderModel: Model<OrderDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
  ) {}

  /**
   * Helper to resolve or auto-create the Distributor Shop for a user
   */
  async getOrCreateDistributorShop(userId: string): Promise<ShopDocument> {
    let shop = await this.shopModel.findOne({ owner: new Types.ObjectId(userId) });
    if (!shop) {
      const user = await this.userModel.findById(userId);
      const name = user?.businessName || user?.name || 'Distributor Agency';
      shop = new this.shopModel({
        owner: new Types.ObjectId(userId),
        name: name,
        category: 'Grocery',
        shopType: 'Distributor',
        rating: 4.8,
        status: 'Open',
        agencyStatus: 'open',
        isOpen: true,
        isAcceptingOrders: true,
        isUpdatingRates: false,
        ownerName: user?.name,
        ownerPhone: user?.phone,
        address: (user?.addresses && user.addresses.length > 0 ? (typeof user.addresses[0] === 'string' ? user.addresses[0] : (user.addresses[0].street || user.addresses[0].address || '')) : '') || 'Distribution Warehouse',
      });
      await shop.save();
    }
    return shop;
  }

  /**
   * Fetch current distributor profile & agency status
   */
  async getProfile(userId: string) {
    const shop = await this.getOrCreateDistributorShop(userId);
    const user = await this.userModel.findById(userId).select('email phone name businessName');

    const isOpen = shop.isOpen ?? (shop.status === 'Open');
    const isAcceptingOrders = shop.isAcceptingOrders ?? true;
    const isUpdatingRates = shop.isUpdatingRates ?? false;

    let computedStatus = 'open';
    if (!isOpen) {
      computedStatus = 'closed';
    } else if (isUpdatingRates) {
      computedStatus = 'updating';
    } else if (!isAcceptingOrders) {
      computedStatus = 'paused';
    }

    return {
      agencyName: shop.name || user?.businessName || user?.name || 'My Distribution Agency',
      ownerName: shop.ownerName || user?.name || '',
      email: user?.email || '',
      phone: shop.ownerPhone || user?.phone || '',
      address: shop.address || '',
      gstNo: shop.gstNumber || '',
      tradeLicenseNo: shop.tradeLicenseNumber || '',
      fssaiNo: shop.fssaiNumber || '',
      isOpen,
      isAcceptingOrders,
      isUpdatingRates,
      status: computedStatus,
    };
  }

  /**
   * Update distributor profile info
   */
  async updateProfile(userId: string, dto: UpdateDistributorProfileDto) {
    const shop = await this.getOrCreateDistributorShop(userId);

    if (dto.agencyName) shop.name = dto.agencyName;
    if (dto.ownerName !== undefined) shop.ownerName = dto.ownerName;
    if (dto.phone !== undefined) shop.ownerPhone = dto.phone;
    if (dto.address !== undefined) shop.address = dto.address;
    if (dto.gstNo !== undefined) shop.gstNumber = dto.gstNo;
    if (dto.tradeLicenseNo !== undefined) shop.tradeLicenseNumber = dto.tradeLicenseNo;
    if (dto.fssaiNo !== undefined) shop.fssaiNumber = dto.fssaiNo;

    await shop.save();

    // Also update User record phone if provided
    if (dto.phone) {
      await this.userModel.findByIdAndUpdate(userId, { phone: dto.phone });
    }

    return this.getProfile(userId);
  }

  /**
   * Update agency status (isOpen, isAcceptingOrders, isUpdatingRates)
   */
  async updateStatus(userId: string, dto: UpdateDistributorStatusDto) {
    const shop = await this.getOrCreateDistributorShop(userId);

    if (dto.isOpen !== undefined) {
      shop.isOpen = dto.isOpen;
      shop.status = dto.isOpen ? 'Open' : 'Closed';
    }
    if (dto.isAcceptingOrders !== undefined) {
      shop.isAcceptingOrders = dto.isAcceptingOrders;
    }
    if (dto.isUpdatingRates !== undefined) {
      shop.isUpdatingRates = dto.isUpdatingRates;
    }
    if (dto.status) {
      shop.agencyStatus = dto.status;
      if (dto.status === 'closed') {
        shop.isOpen = false;
        shop.status = 'Closed';
      } else if (dto.status === 'open') {
        shop.isOpen = true;
        shop.isAcceptingOrders = true;
        shop.isUpdatingRates = false;
        shop.status = 'Open';
      } else if (dto.status === 'paused') {
        shop.isOpen = true;
        shop.isAcceptingOrders = false;
      } else if (dto.status === 'updating') {
        shop.isUpdatingRates = true;
      }
    }

    await shop.save();
    return this.getProfile(userId);
  }

  /**
   * Get all inventory items for this distributor
   */
  async getInventory(userId: string) {
    const shop = await this.getOrCreateDistributorShop(userId);
    const products = await this.productModel
      .find({ shop: shop._id })
      .sort({ createdAt: -1 })
      .exec();

    return products.map((p) => ({
      id: p._id.toString(),
      name: p.name,
      category: p.category,
      unit: p.unit,
      rate: p.price,
      stock: p.stockQuantity,
      isAvailable: p.isAvailable,
      gstPercent: p.gstPercent ?? 5,
      minOrderQty: p.minOrderQty ?? 1,
    }));
  }

  /**
   * Add a new product to distributor catalog
   */
  async addInventoryItem(userId: string, dto: CreateDistributorProductDto) {
    const shop = await this.getOrCreateDistributorShop(userId);
    const product = new this.productModel({
      shop: shop._id,
      name: dto.name,
      category: dto.category,
      unit: dto.unit,
      price: dto.rate,
      stockQuantity: dto.stock,
      gstPercent: dto.gstPercent ?? 5,
      minOrderQty: dto.minOrderQty ?? 1,
      isAvailable: dto.isAvailable ?? true,
      images: [],
    });

    const saved = await product.save();
    return {
      id: saved._id.toString(),
      name: saved.name,
      category: saved.category,
      unit: saved.unit,
      rate: saved.price,
      stock: saved.stockQuantity,
      isAvailable: saved.isAvailable,
      gstPercent: saved.gstPercent,
      minOrderQty: saved.minOrderQty,
    };
  }

  /**
   * Update an individual inventory item
   */
  async updateInventoryItem(userId: string, productId: string, dto: UpdateDistributorProductDto) {
    const shop = await this.getOrCreateDistributorShop(userId);
    const updateData: any = {};
    if (dto.name !== undefined) updateData.name = dto.name;
    if (dto.category !== undefined) updateData.category = dto.category;
    if (dto.unit !== undefined) updateData.unit = dto.unit;
    if (dto.rate !== undefined) updateData.price = dto.rate;
    if (dto.stock !== undefined) updateData.stockQuantity = dto.stock;
    if (dto.isAvailable !== undefined) updateData.isAvailable = dto.isAvailable;
    if (dto.gstPercent !== undefined) updateData.gstPercent = dto.gstPercent;
    if (dto.minOrderQty !== undefined) updateData.minOrderQty = dto.minOrderQty;

    const updated = await this.productModel.findOneAndUpdate(
      { _id: new Types.ObjectId(productId), shop: shop._id },
      { $set: updateData },
      { new: true },
    );

    if (!updated) throw new NotFoundException('Inventory product not found');

    return {
      id: updated._id.toString(),
      name: updated.name,
      category: updated.category,
      unit: updated.unit,
      rate: updated.price,
      stock: updated.stockQuantity,
      isAvailable: updated.isAvailable,
      gstPercent: updated.gstPercent,
      minOrderQty: updated.minOrderQty,
    };
  }

  /**
   * Set product availability toggle
   */
  async setProductAvailable(userId: string, productId: string, isAvailable: boolean) {
    return this.updateInventoryItem(userId, productId, { isAvailable });
  }

  /**
   * Batch update rates for multiple inventory items
   */
  async batchUpdateRates(userId: string, rates: Record<string, number>) {
    const shop = await this.getOrCreateDistributorShop(userId);
    const bulkOps = Object.entries(rates).map(([productId, rate]) => ({
      updateOne: {
        filter: { _id: new Types.ObjectId(productId), shop: shop._id },
        update: { $set: { price: rate } },
      },
    }));

    if (bulkOps.length > 0) {
      await this.productModel.bulkWrite(bulkOps);
    }

    // Unlock rate update mode on shop
    shop.isUpdatingRates = false;
    await shop.save();

    return this.getInventory(userId);
  }

  /**
   * Delete an inventory item
   */
  async deleteInventoryItem(userId: string, productId: string) {
    const shop = await this.getOrCreateDistributorShop(userId);
    const deleted = await this.productModel.findOneAndDelete({
      _id: new Types.ObjectId(productId),
      shop: shop._id,
    });
    if (!deleted) throw new NotFoundException('Product not found');
    return { success: true };
  }

  /**
   * Fetch all orders placed for this distributor's inventory
   */
  async getOrders(userId: string) {
    const shop = await this.getOrCreateDistributorShop(userId);
    const products = await this.productModel.find({ shop: shop._id }).select('_id');
    const productIds = products.map((p) => p._id);

    const orders = await this.orderModel
      .find({ 'items.productId': { $in: productIds } })
      .populate('userId', 'name email phone businessName address')
      .sort({ createdAt: -1 })
      .exec();

    return orders.map((o) => {
      const user = o.userId as any;
      const delivery = o.deliveryAddress || {};

      // Map backend status to DeliveryStatus
      let mappedStatus = 'pending';
      const raw = (o.status || '').toLowerCase();
      if (raw === 'placed' || raw === 'pending') mappedStatus = 'pending';
      else if (raw === 'accepted' || raw === 'processing') mappedStatus = 'accepted';
      else if (raw === 'dispatched' || raw === 'shipped') mappedStatus = 'dispatched';
      else if (raw === 'delivered') mappedStatus = 'delivered';
      else if (raw === 'cancelled') mappedStatus = 'cancelled';

      return {
        id: o._id.toString(),
        shopName: delivery.shopName || user?.businessName || user?.name || 'Retail Store',
        ownerName: delivery.ownerName || user?.name || 'Shopkeeper',
        address: delivery.address || (user?.addresses && user.addresses.length > 0 ? (typeof user.addresses[0] === 'string' ? user.addresses[0] : (user.addresses[0].street || user.addresses[0].address || '')) : '') || 'Local Market',
        phone: delivery.phone || user?.phone || '',
        placedAt: (o as any).createdAt,
        status: mappedStatus,
        items: (o.items || []).map((it) => ({
          name: it.name,
          unit: (it as any).unit || 'Unit',
          qty: it.quantity,
          rate: it.price,
          gstPercent: (it as any).gstPercent ?? 5,
        })),
      };
    });
  }

  /**
   * Update the status of an incoming order
   */
  async updateOrderStatus(userId: string, orderId: string, status: string) {
    // Map distributor status back to order schema enum
    let dbStatus = 'Processing';
    const s = status.toLowerCase();
    if (s === 'pending') dbStatus = 'Placed';
    else if (s === 'accepted') dbStatus = 'Accepted';
    else if (s === 'dispatched') dbStatus = 'Dispatched';
    else if (s === 'delivered') dbStatus = 'Delivered';
    else if (s === 'cancelled') dbStatus = 'Cancelled';

    const updated = await this.orderModel.findByIdAndUpdate(
      orderId,
      { $set: { status: dbStatus } },
      { new: true },
    );

    if (!updated) throw new NotFoundException('Order not found');

    return {
      orderId: updated._id.toString(),
      status: s,
      dbStatus: updated.status,
    };
  }

  /**
   * List all registered distributors (Public for shopkeepers)
   */
  async listAllDistributors() {
    const distributors = await this.shopModel
      .find({ shopType: 'Distributor' })
      .populate('owner', 'name phone email businessName')
      .exec();

    return distributors.map((d) => ({
      id: d._id.toString(),
      name: d.name,
      category: d.category || 'Wholesale Goods',
      ownerName: d.ownerName || (d.owner as any)?.name || 'Distributor',
      phone: d.ownerPhone || (d.owner as any)?.phone || '',
      address: d.address || '',
      rating: d.rating || 4.8,
      status: d.agencyStatus || (d.status === 'Open' ? 'open' : 'closed'),
      isOpen: d.isOpen ?? (d.status === 'Open'),
    }));
  }
}
