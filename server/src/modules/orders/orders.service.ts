import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Order, OrderDocument } from './schemas/order.schema';
import { CartService } from '../cart/cart.service';
import { ShopsService } from '../shops/shops.service';
import { Product, ProductDocument } from '../products/schemas/product.schema';

@Injectable()
export class OrdersService {
  constructor(
    @InjectModel(Order.name) private orderModel: Model<OrderDocument>,
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
    private cartService: CartService,
    private shopsService: ShopsService,
  ) {}

  async createOrder(userId: string, deliveryAddress: any) {
    const cart = await this.cartService.getCart(userId);
    if (!cart.items || cart.items.length === 0) {
      throw new BadRequestException('Cart is empty');
    }

    const totalAmount = cart.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);

    const order = new this.orderModel({
      userId: new Types.ObjectId(userId),
      items: cart.items,
      totalAmount,
      deliveryAddress,
      status: 'Placed',
    });

    const savedOrder = await order.save();
    await this.cartService.clearCart(userId);
    return savedOrder;
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
