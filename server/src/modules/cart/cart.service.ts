import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Cart, CartDocument } from './schemas/cart.schema';
import { Product, ProductDocument } from '../products/schemas/product.schema';

@Injectable()
export class CartService {
  constructor(
    @InjectModel(Cart.name) private cartModel: Model<CartDocument>,
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
  ) {}

  async getCart(userId: string, session?: any) {
    const userObjId = new Types.ObjectId(userId);
    let cart = await this.cartModel.findOne({ userId: userObjId }).session(session);
    if (!cart) {
      cart = new this.cartModel({ userId: userObjId, items: [] });
      await cart.save({ session });
      return cart;
    }
    return this.deduplicateCart(cart);
  }

  async addItem(userId: string, productId: string, quantity: number) {
    const product = await this.productModel.findById(productId);
    if (!product) throw new NotFoundException('Product not found');

    const userObjId = new Types.ObjectId(userId);
    const productObjId = new Types.ObjectId(productId);

    // Ensure cart exists
    await this.getCart(userId);

    // Handle decrement
    if (quantity < 0) {
      const updated = await this.cartModel.findOneAndUpdate(
        { userId: userObjId, 'items.productId': productObjId },
        { $inc: { 'items.$.quantity': quantity } },
        { new: true },
      );

      if (updated) {
        // Automatically remove any item whose quantity is 0 or negative
        const cleaned = await this.cartModel.findOneAndUpdate(
          { userId: userObjId },
          { $pull: { items: { quantity: { $lte: 0 } } } as any },
          { new: true },
        );
        return cleaned || updated;
      }
      return this.getCart(userId);
    }

    // Atomic Step 1: Increment if product already in cart
    const updated = await this.cartModel.findOneAndUpdate(
      { userId: userObjId, 'items.productId': productObjId },
      { $inc: { 'items.$.quantity': quantity } },
      { new: true },
    );

    if (updated) {
      return this.deduplicateCart(updated);
    }

    // Atomic Step 2: Push new item only if it does NOT already exist
    const pushed = await this.cartModel.findOneAndUpdate(
      { userId: userObjId, 'items.productId': { $ne: productObjId } },
      {
        $push: {
          items: {
            productId: productObjId,
            name: product.name,
            price: product.price,
            quantity,
          },
        },
      },
      { new: true },
    );

    if (pushed) {
      return pushed;
    }

    // Fallback: If a concurrent request inserted the item in between, increment it
    const fallbackUpdated = await this.cartModel.findOneAndUpdate(
      { userId: userObjId, 'items.productId': productObjId },
      { $inc: { 'items.$.quantity': quantity } },
      { new: true },
    );

    return fallbackUpdated || (await this.getCart(userId));
  }

  async removeItem(userId: string, productId: string) {
    const userObjId = new Types.ObjectId(userId);
    const productObjId = new Types.ObjectId(productId);
    const cart = await this.cartModel.findOneAndUpdate(
      { userId: userObjId },
      { $pull: { items: { productId: productObjId } } as any },
      { new: true },
    );
    return cart || (await this.getCart(userId));
  }

  async clearCart(userId: string, session?: any) {
    const userObjId = new Types.ObjectId(userId);
    const cart = await this.cartModel.findOneAndUpdate(
      { userId: userObjId },
      { $set: { items: [] } },
      { new: true, session },
    );
    return cart || (await this.getCart(userId, session));
  }

  private async deduplicateCart(cart: CartDocument): Promise<CartDocument> {
    if (!cart.items || cart.items.length <= 1) return cart;

    const seen = new Map<string, any>();
    let hasDuplicates = false;

    for (const item of cart.items) {
      const pId = item.productId.toString();
      if (seen.has(pId)) {
        hasDuplicates = true;
        seen.get(pId).quantity += item.quantity;
      } else {
        seen.set(pId, {
          productId: item.productId,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
        });
      }
    }

    if (hasDuplicates) {
      cart.items = Array.from(seen.values()) as any;
      return cart.save();
    }

    return cart;
  }
}
