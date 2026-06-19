import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Shop, ShopDocument } from './schemas/shop.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { CreateShopDto } from './dto/create-shop.dto';
import { SubmitVerificationDto } from './dto/submit-verification.dto';

@Injectable()
export class ShopsService {
  constructor(
    @InjectModel(Shop.name) private shopModel: Model<ShopDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) {}

  async findAll() {
    return this.shopModel.find().exec();
  }

  async findFiltered(category?: string, shopType?: string, search?: string) {
    const filter: any = { status: 'Open' };
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

  async submitVerification(
    ownerId: string,
    dto: SubmitVerificationDto,
    urls: { gstCertificateUrl: string; tradeLicenseUrl: string; shopImageUrl: string },
  ) {
    let shop = await this.shopModel.findOne({ owner: ownerId }).exec();
    if (!shop) {
      shop = new this.shopModel({
        owner: ownerId,
        shopType: 'Retailer', // default
      });
    }

    // Merge details
    shop.name = dto.name;
    shop.category = dto.category;
    shop.description = dto.description;
    shop.ownerName = dto.ownerName;
    shop.ownerPhone = dto.ownerPhone;
    shop.address = dto.address;
    shop.district = dto.district;
    shop.state = dto.state;
    shop.pincode = dto.pincode;
    shop.gstNumber = dto.gstNumber;
    shop.tradeLicenseNumber = dto.tradeLicenseNumber;

    if (dto.latitude && dto.longitude) {
      shop.location = {
        type: 'Point',
        coordinates: [parseFloat(dto.longitude), parseFloat(dto.latitude)],
      };
    }

    // Merge documents
    shop.gstCertificateUrl = urls.gstCertificateUrl;
    shop.tradeLicenseUrl = urls.tradeLicenseUrl;
    shop.imageUrl = urls.shopImageUrl;

    // Transition state
    shop.verificationStatus = 'Pending';

    // Clear previous rejection details
    shop.verificationRejectedReason = undefined;
    shop.verificationRejectedNotes = undefined;
    shop.verificationNotes = undefined;
    shop.changesRequestedDetails = undefined;

    // Also update User profile
    await this.userModel.findByIdAndUpdate(ownerId, {
      name: dto.ownerName,
      phone: dto.ownerPhone,
    }).exec();

    return shop.save();
  }

  async findAllAdmin() {
    return this.shopModel.find().populate('owner', 'name email').exec();
  }

  async updateVerificationStatus(id: string, status: string, reason?: string, notes?: string) {
    const shop = await this.shopModel.findById(id).exec();
    if (!shop) throw new NotFoundException('Shop not found');
    shop.verificationStatus = status;
    if (status === 'Rejected') {
      shop.verificationRejectedReason = reason;
      shop.verificationRejectedNotes = notes;
    } else if (status === 'Changes Requested') {
      shop.changesRequestedDetails = notes;
    } else {
      shop.verificationRejectedReason = undefined;
      shop.verificationRejectedNotes = undefined;
      shop.changesRequestedDetails = undefined;
    }
    if (notes) {
      shop.verificationNotes = notes;
    }
    return shop.save();
  }

  async updateStatus(ownerId: string, status: string) {
    const shop = await this.shopModel.findOne({ owner: ownerId }).exec();
    if (!shop) throw new NotFoundException('Shop not found');
    shop.status = status;
    return shop.save();
  }

  async fixStatus() {
    const updateResult = await this.shopModel.updateMany(
      { status: { $exists: false } },
      { $set: { status: 'Open' } }
    );
    const ensureResult = await this.shopModel.updateMany(
      { status: { $nin: ['Open', 'Closed'] } },
      { $set: { status: 'Open' } }
    );
    const shops = await this.shopModel.find().exec();
    return {
      updatedMissing: updateResult.modifiedCount,
      enforcedOpen: ensureResult.modifiedCount,
      totalShops: shops.length,
      shops: shops.map(s => ({ id: s._id, name: s.name, status: s.status }))
    };
  }
}
