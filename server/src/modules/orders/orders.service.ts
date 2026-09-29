import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectModel, InjectConnection } from '@nestjs/mongoose';
import { Model, Types, Connection } from 'mongoose';
import { Order, OrderDocument } from './schemas/order.schema';
import { CartService } from '../cart/cart.service';
import { ShopsService } from '../shops/shops.service';
import { Product, ProductDocument } from '../products/schemas/product.schema';

@Injectable()
export class OrdersService {
  constructor(
    @InjectModel(Order.name) private orderModel: Model<OrderDocument>,
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
    @InjectConnection() private readonly connection: Connection,
    private cartService: CartService,
    private shopsService: ShopsService,
  ) {}

  async createOrder(userId: string, deliveryAddress: any) {
    const session = await this.connection.startSession();
    session.startTransaction();

    try {
      const cart = await this.cartService.getCart(userId, session);
      if (!cart.items || cart.items.length === 0) {
        throw new BadRequestException('Cart is empty');
      }

      // Validate stock and decrement transactionally for each item
      for (const item of cart.items) {
        const result = await this.productModel.updateOne(
          {
            _id: item.productId,
            isAvailable: true,
            $or: [
              { stockQuantity: { $gte: item.quantity } },
              { stockQuantity: { $exists: false } },
              { stockQuantity: null },
            ],
          },
          { $inc: { stockQuantity: -item.quantity } },
          { session }
        ).exec();

        if (result.modifiedCount === 0) {
          throw new BadRequestException(`Product '${item.name}' is out of stock or unavailable`);
        }
      }

      const totalAmount = cart.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);

      const order = new this.orderModel({
        userId: new Types.ObjectId(userId),
        items: cart.items,
        totalAmount,
        deliveryAddress,
        status: 'Placed',
      });

      const savedOrder = await order.save({ session });
      await this.cartService.clearCart(userId, session);

      await session.commitTransaction();
      return savedOrder;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async getMyOrders(userId: string) {
    return this.orderModel.find({ userId: new Types.ObjectId(userId) }).sort({ createdAt: -1 });
  }

  async updateOrderStatus(id: string, status: string) {
    return this.orderModel.findByIdAndUpdate(id, { status }, { new: true });
  }

  async getMyShopOrders(ownerId: string) {
    const shop = await this.shopsService.findByOwner(ownerId);
    if (!shop) throw new NotFoundException('Shop not found');

    const products = await this.productModel.find({ shop: shop._id }).select('_id');
    const productIds = products.map(p => p._id);

    return this.orderModel.find({
      'items.productId': { $in: productIds }
    })
    .populate('userId', 'name email phone')
    .sort({ createdAt: -1 })
    .exec();
  }
}
