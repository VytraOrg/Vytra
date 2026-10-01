import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Product, ProductDocument } from './schemas/product.schema';
import { CacheService } from '../cache/cache.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { ProductQueryDto } from './dto/product-query.dto';
import { SynonymsService } from './services/synonyms.service';
import { SpellcheckService } from './services/spellcheck.service';

@Injectable()
export class ProductsService {
  constructor(
    @InjectModel(Product.name) private productModel: Model<ProductDocument>,
    private cacheService: CacheService,
    private synonymsService: SynonymsService,
    private spellcheckService: SpellcheckService,
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
    if (search && search.trim()) {
      const tokens = search.trim().split(/\s+/).filter((t) => t.length > 0);
      const tokenGroups = this.synonymsService.expandTokens(tokens);

      filter.$and = tokenGroups.map((group) => {
        const orClauses: any[] = [];
        for (const word of group) {
          const escaped = word.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
          orClauses.push(
            { name: { $regex: escaped, $options: 'i' } },
            { description: { $regex: escaped, $options: 'i' } },
            { category: { $regex: escaped, $options: 'i' } },
          );
        }
        return { $or: orClauses };
      });
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
    const cached = await this.cacheService.get(cacheKey);
    if (cached) {
      try {
        return JSON.parse(cached);
      } catch (_) {}
    }

    const product = await this.productModel.findById(id).populate('shop').exec();
    if (!product) throw new NotFoundException('Product not found');
    
    await this.cacheService.set(cacheKey, JSON.stringify(product), 3600);
    return product;
  }

  async create(createProductDto: CreateProductDto) {
    const created = new this.productModel(createProductDto);
    const saved = await created.save();
    await this.cacheService.clearPattern('products:*');
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

  private getCategoryRegex(cat: string): RegExp | null {
    const c = cat.toLowerCase().trim();
    if (!c || c === 'all') return null;

    if (c === 'staples') {
      return /staple|grocery|grain|atta|rice|dal|salt|oil|sugar|wheat|flour|pulse|spice|masala/i;
    }
    if (c === 'dairy') {
      return /dairy|milk|butter|cheese|curd|paneer|ghee|dahi|yogurt|bakery/i;
    }
    if (c === 'veggies') {
      return /veggie|vegetable|fruit|potato|onion|tomato|apple|banana|fresh/i;
    }
    if (c === 'snacks') {
      return /snack|chip|kurkure|lays|biscuit|cookie|namkeen|bhujia|crisp|chocolate|candy/i;
    }
    if (c === 'household') {
      return /household|cleaning|soap|detergent|sanitizer|cleaner|shampoo|toothpaste|wash/i;
    }

    return new RegExp(cat.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&'), 'i');
  }

  private buildPipeline(search?: string, category?: string, shopType?: string, lat?: number, lng?: number): any[] {
    const trimmed = (search || '').trim();
    const tokens = trimmed.length > 0 ? trimmed.split(/\s+/).filter((t) => t.length > 0) : [];
    const tokenGroups = tokens.length > 0 ? this.synonymsService.expandTokens(tokens) : [];

    const tokenMatches = tokenGroups.map((group) => {
      const orClauses: any[] = [];
      for (const word of group) {
        const escaped = word.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
        orClauses.push(
          { name: { $regex: escaped, $options: 'i' } },
          { category: { $regex: escaped, $options: 'i' } },
          { description: { $regex: escaped, $options: 'i' } },
        );
      }
      return { $or: orClauses };
    });

    const matchConditions: any[] = [{ isAvailable: true }];

    if (tokenMatches.length > 0) {
      matchConditions.push({ $and: tokenMatches });
    }

    const catRegex = this.getCategoryRegex(category || '');
    if (catRegex) {
      matchConditions.push({
        $or: [
          { category: { $regex: catRegex } },
          { name: { $regex: catRegex } },
          { description: { $regex: catRegex } },
        ],
      });
    }

    const pipeline: any[] = [
      {
        $match: matchConditions.length === 1 ? matchConditions[0] : { $and: matchConditions },
      },
      {
        $addFields: {
          shopObjectId: {
            $convert: {
              input: '$shop',
              to: 'objectId',
              onError: null,
              onNull: null,
            },
          },
        },
      },
      {
        $lookup: {
          from: 'shops',
          localField: 'shopObjectId',
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

    if (trimmed.length > 0) {
      const escapedFull = trimmed.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
      pipeline.push({
        $addFields: {
          score: {
            $add: [
              { $cond: [{ $regexMatch: { input: '$name', regex: `^${escapedFull}`, options: 'i' } }, 10, 0] },
              { $cond: [{ $regexMatch: { input: '$name', regex: escapedFull, options: 'i' } }, 5, 0] },
              { $cond: [{ $regexMatch: { input: '$category', regex: escapedFull, options: 'i' } }, 3, 0] },
            ],
          },
        },
      });
    } else {
      pipeline.push({
        $addFields: {
          score: 1,
        },
      });
    }

    if (lat !== undefined && lng !== undefined && !isNaN(Number(lat)) && !isNaN(Number(lng))) {
      const latitude = Number(lat);
      const longitude = Number(lng);

      const latDiff = { $subtract: [{ $arrayElemAt: ['$shopInfo.location.coordinates', 1] }, latitude] };
      const lngDiff = { $subtract: [{ $arrayElemAt: ['$shopInfo.location.coordinates', 0] }, longitude] };

      pipeline.push({
        $addFields: {
          distanceKm: {
            $cond: [
              { $and: [{ $isArray: '$shopInfo.location.coordinates' }, { $gte: [{ $size: '$shopInfo.location.coordinates' }, 2] }] },
              {
                $round: [
                  {
                    $multiply: [
                      111.32,
                      {
                        $sqrt: {
                          $add: [
                            { $pow: [latDiff, 2] },
                            { $pow: [lngDiff, 2] },
                          ],
                        },
                      },
                    ],
                  },
                  1,
                ],
              },
              null,
            ],
          },
        },
      });

      pipeline.push({
        $addFields: {
          score: {
            $add: [
              '$score',
              {
                $cond: [
                  { $and: [{ $ne: ['$distanceKm', null] }, { $lte: ['$distanceKm', 5] }] },
                  5,
                  {
                    $cond: [
                      { $and: [{ $ne: ['$distanceKm', null] }, { $lte: ['$distanceKm', 15] }] },
                      2,
                      0,
                    ],
                  },
                ],
              },
            ],
          },
        },
      });
    }

    pipeline.push({ $sort: { score: -1, createdAt: -1 } });
    pipeline.push({ $limit: 30 });

    return pipeline;
  }

  async searchGlobal(search?: string, category?: string, shopType?: string, lat?: number, lng?: number) {
    const hasSearch = search && search.trim().length > 0;
    const hasCategory = category && category.trim().length > 0 && category.toLowerCase().trim() !== 'all';

    if (!hasSearch && !hasCategory) {
      return { items: [], isAutoCorrected: false, originalQuery: '', correctedQuery: '' };
    }

    const queryText = search ? search.trim() : '';
    const pipeline = this.buildPipeline(queryText, category, shopType, lat, lng);
    let items = await this.productModel.aggregate(pipeline).exec();

    let isAutoCorrected = false;
    let correctedQuery = '';
    let didYouMean: string | undefined = undefined;

    // If query returned 0 items and search text was provided, attempt spelling correction
    if (items.length === 0 && hasSearch) {
      const correction = this.spellcheckService.correctPhrase(queryText);
      if (correction.wasChanged) {
        didYouMean = correction.corrected;
        const correctedPipeline = this.buildPipeline(correction.corrected, category, shopType, lat, lng);
        const correctedItems = await this.productModel.aggregate(correctedPipeline).exec();
        if (correctedItems.length > 0) {
          items = correctedItems;
          isAutoCorrected = true;
          correctedQuery = correction.corrected;
        }
      }
    }

    return {
      items,
      isAutoCorrected,
      originalQuery: queryText,
      correctedQuery: isAutoCorrected ? correctedQuery : queryText,
      didYouMean,
    };
  }

  async getSuggestions(search: string, shopType?: string) {
    if (!search || search.trim().length < 2) {
      return { suggestions: [], categories: [], didYouMean: null };
    }

    const synonyms = this.synonymsService.getSynonyms(search.trim());
    const orClauses = synonyms.flatMap((word) => {
      const escaped = word.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
      return [
        { name: { $regex: escaped, $options: 'i' } },
        { category: { $regex: escaped, $options: 'i' } },
      ];
    });

    const pipeline: any[] = [
      {
        $match: {
          isAvailable: true,
          $or: orClauses,
        },
      },
      {
        $addFields: {
          shopObjectId: {
            $convert: {
              input: '$shop',
              to: 'objectId',
              onError: null,
              onNull: null,
            },
          },
        },
      },
      {
        $lookup: {
          from: 'shops',
          localField: 'shopObjectId',
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

    pipeline.push({ $limit: 15 });
    pipeline.push({
      $project: {
        name: 1,
        category: 1,
      },
    });

    const results = await this.productModel.aggregate(pipeline).exec();
    const productNames = Array.from(new Set(results.map((r: any) => r.name))).slice(0, 5);
    const categories = Array.from(new Set(results.map((r: any) => r.category))).slice(0, 3);
    const correction = this.spellcheckService.correctPhrase(search);

    return {
      suggestions: productNames,
      categories,
      didYouMean: correction.wasChanged ? correction.corrected : null,
    };
  }

  async remove(id: string) {
    const deleted = await this.productModel.findByIdAndDelete(id);
    if (!deleted) throw new NotFoundException('Product not found');
    
    await this.cacheService.delete(`product:${id}`);
    await this.cacheService.clearPattern('products:*');
    return { success: true, message: 'Product deleted successfully' };
  }
}
