import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Product, ProductDocument } from './schemas/product.schema';
import { CacheService } from '../cache/cache.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { ProductQueryDto } from './dto/product-query.dto';

@Injectable()
export class ProductsService {
  constructor(
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
    private cacheService: CacheService,
  ) {}

  async findAll(query: ProductQueryDto) {
    const { page = 1, limit = 10, category, shopId, search } = query;
    const skip = (page - 1) * limit;

    const filter: any = { isAvailable: true };
    if (category) filter.category = category;
    if (shopId) {
      const shopIds: any[] = [shopId];
      try {
        shopIds.push(new Types.ObjectId(shopId));
      } catch (e) {}
      filter.shop = { $in: shopIds };
    }
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
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

  async create(createProductDto: CreateProductDto) {
    const productData = { ...createProductDto };
    try {
      productData.shop = new Types.ObjectId(createProductDto.shop) as any;
    } catch (e) {}
    const product = new this.productModel(productData);
    const saved = await product.save();
    await this.cacheService.clearPattern('products:*'); // Invalidate list cache
    return saved;
  }

  async update(id: string, updateProductDto: UpdateProductDto) {
    const updateData: any = { ...updateProductDto };
    if (updateData.shop) {
      try {
        updateData.shop = new Types.ObjectId(updateData.shop);
      } catch (e) {}
    }
    const updated = await this.productModel.findByIdAndUpdate(id, updateData, { new: true });
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
      {
        $match: {
          'shopInfo.status': 'Open',
        },
      },
    ];

    if (shopType) {
      pipeline.push({
        $match: { 'shopInfo.shopType': shopType },
      });
    }

    pipeline.push({ $limit: 20 });

    return this.productModel.aggregate(pipeline).exec();
  }

  async remove(id: string) {
    const deleted = await this.productModel.findByIdAndDelete(id);
    if (!deleted) throw new NotFoundException('Product not found');
    
    await this.cacheService.delete(`product:${id}`);
    await this.cacheService.clearPattern('products:*');
    return { success: true, message: 'Product deleted successfully' };
  }
}
