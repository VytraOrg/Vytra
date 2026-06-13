import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Shop, ShopDocument } from './schemas/shop.schema';
import { CreateShopDto } from './dto/create-shop.dto';

@Injectable()
export class ShopsService {
  constructor(
    @InjectModel(Shop.name) private shopModel: Model<ShopDocument>,
  ) {}

  async findAll() {
    return this.shopModel.find().exec();
  }

  async findFiltered(category?: string, shopType?: string, search?: string) {
    const filter: any = {};
    if (category) filter.category = category;
    if (shopType) filter.shopType = shopType;
    if (search) {
      filter.name = { $regex: search, $options: 'i' };
    }
    return this.shopModel.find(filter).exec();
  }

  async findOne(id: string) {
    const shop = await this.shopModel.findById(id).exec();
    if (!shop) throw new NotFoundException('Shop not found');
    return shop;
  }

  async create(createShopDto: CreateShopDto) {
    const shop = new this.shopModel(createShopDto);
    return shop.save();
  }

  async findByOwner(ownerId: string) {
    return this.shopModel.findOne({ owner: ownerId }).exec();
  }

  async verifyShop(ownerId: string, gstCertificateUrl: string, tradeLicenseUrl: string) {
    const shop = await this.shopModel.findOne({ owner: ownerId }).exec();
    if (!shop) throw new NotFoundException('Shop not found');
    shop.gstCertificateUrl = gstCertificateUrl;
    shop.tradeLicenseUrl = tradeLicenseUrl;
    shop.verificationStatus = 'Pending';
    return shop.save();
  }
}
