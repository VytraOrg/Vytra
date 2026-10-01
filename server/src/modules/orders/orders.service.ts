import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { InjectModel, InjectConnection } from '@nestjs/mongoose';
import { Model, Types, Connection } from 'mongoose';
import { Order, OrderDocument } from './schemas/order.schema';
import { CartService } from '../cart/cart.service';
import { ShopsService } from '../shops/shops.service';
import { Product, ProductDocument } from '../products/schemas/product.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { MailService } from '../mail/mail.service';

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  constructor(
    @InjectModel(Order.name) private orderModel: Model<OrderDocument>,
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectConnection() private readonly connection: Connection,
    private cartService: CartService,
    private shopsService: ShopsService,
    private mailService: MailService,
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

      // Dispatch confirmation email asynchronously (fire-and-forget so order flow is never blocked)
      this.sendOrderConfirmationEmail(savedOrder, userId).catch((err) => {
        this.logger.error(`Failed to send order confirmation email: ${err.message}`);
      });

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
    const updatedOrder = await this.orderModel
      .findByIdAndUpdate(id, { status }, { new: true })
      .populate('userId', 'name email');

    if (updatedOrder && (updatedOrder.userId as any)?.email) {
      this.mailService
        .sendOrderStatusUpdate((updatedOrder.userId as any).email, {
          orderId: updatedOrder._id.toString(),
          customerName: (updatedOrder.userId as any).name || 'Customer',
          status,
        })
        .catch((err) => {
          this.logger.error(`Failed to send order status email: ${err.message}`);
        });
    }

    return updatedOrder;
  }

  private async sendOrderConfirmationEmail(order: OrderDocument, userId: string) {
    try {
      const user = await this.userModel.findById(userId).select('name email');
      if (!user || !user.email) return;

      const itemsSummary = (order.items || []).map((item) => ({
        name: item.name,
        quantity: item.quantity,
        price: item.price,
      }));

      await this.mailService.sendOrderConfirmation(user.email, {
        orderId: order._id.toString(),
        customerName: user.name || 'Valued Customer',
        items: itemsSummary,
        totalAmount: order.totalAmount,
        deliveryAddress: order.deliveryAddress,
      });
    } catch (e: any) {
      this.logger.warn(`Could not dispatch order confirmation email: ${e.message}`);
    }
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
