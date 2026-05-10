import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Product, ProductDocument } from './schemas/product.schema';
import { CacheService } from '../cache/cache.service';

@Injectable()
export class ProductsService {
  constructor(
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
    private cacheService: CacheService,
  ) {}

  async findAll(query: any) {
    const { page = 1, limit = 10, category, shopId, search } = query;
    const skip = (page - 1) * limit;

    const filter: any = { isAvailable: true };
    if (category) filter.category = category;
    if (shopId) {
      try {
        filter.shop = new Types.ObjectId(shopId);
      } catch (e) {
        filter.shop = shopId;
      }
    }
    if (search) {
      filter.$text = { $search: search };
    }

    const [items, total] = await Promise.all([
      this.productModel.find(filter).skip(skip).limit(limit).sort({ createdAt: -1 }),
      this.productModel.countDocuments(filter),
    ]);

    return {
      items,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findOne(id: string) {
    const cacheKey = `product:${id}`;
    const cachedProduct = await this.cacheService.get(cacheKey);
    
    if (cachedProduct) {
      return JSON.parse(cachedProduct);
    }

    const product = await this.productModel.findById(id).populate('shop', 'name location');
    if (!product) {
      throw new NotFoundException('Product not found');
    }

    await this.cacheService.set(cacheKey, product, 3600); // Cache for 1 hour
    return product;
  }

  async create(createProductDto: any) {
    const product = new this.productModel(createProductDto);
    const saved = await product.save();
    await this.cacheService.clearPattern('products:*'); // Invalidate list cache
    return saved;
  }

  async update(id: string, updateProductDto: any) {
    const updated = await this.productModel.findByIdAndUpdate(id, updateProductDto, { new: true });
    if (!updated) throw new NotFoundException('Product not found');
    
    await this.cacheService.delete(`product:${id}`);
    await this.cacheService.clearPattern('products:*');
    return updated;
  }

  async searchGlobal(search: string, shopType?: string) {
    const pipeline: any[] = [
      {
        $match: {
          isAvailable: true,
          name: { $regex: search, $options: 'i' },
        },
      },
      {
        $lookup: {
          from: 'shops',
          localField: 'shop',
          foreignField: '_id',
          as: 'shopInfo',
        },
      },
      { $unwind: '$shopInfo' },
    ];

    if (shopType) {
      pipeline.push({
        $match: { 'shopInfo.shopType': shopType },
      });
    }

    pipeline.push({ $limit: 20 });

    return this.productModel.aggregate(pipeline).exec();
  }
}
