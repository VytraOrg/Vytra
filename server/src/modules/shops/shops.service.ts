import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Shop, ShopDocument } from './schemas/shop.schema';

@Injectable()
export class ShopsService {
  constructor(
    @InjectModel(Shop.name) private shopModel: Model<ShopDocument>,
  ) {}

  async findFiltered(category?: string, shopType?: string, search?: string) {
    const query: any = {};
    if (category && category !== 'All') {
      query.category = category;
    }
    if (shopType) {
      query.shopType = shopType;
    }
    if (search && search.trim() !== '') {
      query.name = { $regex: search, $options: 'i' };
    }
    return this.shopModel.find(query).sort({ name: 1 }).exec();
  }

  async findByOwner(ownerId: string) {
    return this.shopModel.findOne({ owner: ownerId }).exec();
  }

  async create(shopData: any) {
    const shop = new this.shopModel(shopData);
    return shop.save();
  }
}
