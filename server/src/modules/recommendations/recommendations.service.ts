import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Product, ProductDocument } from '../products/schemas/product.schema';
import { Order, OrderDocument } from '../orders/schemas/order.schema';
import { CacheService } from '../cache/cache.service';

export interface CartRecommendationOptions {
  shopId?: string;
  productIds?: string[];
  limit?: number;
}

@Injectable()
export class RecommendationsService {
  private readonly logger = new Logger(RecommendationsService.name);

  // Complementary category mapping for quick-commerce cold start
  private readonly complementaryCategories: Record<string, string[]> = {
    dairy: ['bakery', 'snacks', 'beverages', 'staples', 'breakfast'],
    milk: ['bakery', 'snacks', 'beverages', 'tea', 'coffee', 'biscuits'],
    bakery: ['dairy', 'beverages', 'spreads', 'snacks', 'jam'],
    bread: ['dairy', 'butter', 'jam', 'eggs', 'cheese'],
    snacks: ['beverages', 'cold drinks', 'chocolates', 'sweets', 'namkeen'],
    chips: ['beverages', 'cold drinks', 'dips', 'chocolates'],
    beverages: ['snacks', 'biscuits', 'namkeen', 'ice cream'],
    tea: ['biscuits', 'milk', 'sugar', 'rusk', 'snacks'],
    coffee: ['biscuits', 'milk', 'sugar', 'cookies'],
    vegetables: ['staples', 'spices', 'fruits', 'oils', 'onions', 'potatoes'],
    fruits: ['vegetables', 'dairy', 'beverages', 'juices'],
    staples: ['spices', 'oils', 'pulses', 'vegetables', 'rice', 'atta'],
    atta: ['oil', 'ghee', 'salt', 'dal'],
    rice: ['dal', 'ghee', 'spices', 'oil'],
    spices: ['staples', 'oils', 'vegetables'],
    household: ['personal care', 'cleaning', 'staples', 'detergent'],
    cleaning: ['household', 'detergent', 'disinfectant'],
  };

  constructor(
    @InjectModel(Product.name) private readonly productModel: Model<ProductDocument>,
    @InjectModel(Order.name) private readonly orderModel: Model<OrderDocument>,
    private readonly cacheService: CacheService,
  ) {}

  /**
   * Generates intelligent, real-time cart recommendations:
   * 1. Check Redis cache for instant sub-10ms response.
   * 2. Historical order co-occurrence ("Frequently bought together").
   * 3. Complementary category affinities (Cold-start solution).
   * 4. High-stock top-rated shop bestsellers fallback.
   */
  async getCartRecommendations(options: CartRecommendationOptions): Promise<Product[]> {
    const limit = options.limit && options.limit > 0 ? Math.min(options.limit, 20) : 6;
    const shopId = options.shopId;
    const rawProductIds = options.productIds || [];
    const validProductIds = rawProductIds.filter((id) => Types.ObjectId.isValid(id));

    // 1. Check Redis Cache
    const sortedProductKey = [...validProductIds].sort().join(',');
    const cacheKey = `rec:cart:${shopId || 'all'}:${sortedProductKey || 'empty'}:${limit}`;
    try {
      const cached = await this.cacheService.get(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }
    } catch (err: any) {
      this.logger.warn(`Redis cache read failed for ${cacheKey}: ${err.message}`);
    }

    const recommendedMap = new Map<string, any>();
    const excludeIdSet = new Set<string>(validProductIds);

    // Filter base: must be in-stock and actively available
    const baseFilter: any = {
      isAvailable: true,
      stockQuantity: { $gt: 0 },
    };
    if (shopId && Types.ObjectId.isValid(shopId)) {
      baseFilter.shop = new Types.ObjectId(shopId);
    }

    // 2. STRATEGY A: Historical Order Co-occurrence ("Frequently Bought Together")
    if (validProductIds.length > 0) {
      try {
        const objectIdList = validProductIds.map((id) => new Types.ObjectId(id));
        const coOccurrenceResults = await this.orderModel.aggregate([
          { $match: { 'items.productId': { $in: objectIdList } } },
          { $unwind: '$items' },
          { $match: { 'items.productId': { $nin: objectIdList } } },
          {
            $group: {
              _id: '$items.productId',
              coCount: { $sum: 1 },
            },
          },
          { $sort: { coCount: -1 } },
          { $limit: limit * 2 },
        ]);

        if (coOccurrenceResults.length > 0) {
          const candidateIds = coOccurrenceResults.map((r) => r._id);
          const products = await this.productModel
            .find({
              _id: { $in: candidateIds },
              ...baseFilter,
            })
            .populate('shop', 'name logo isVerified address')
            .lean()
            .exec();

          // Order candidates by highest co-occurrence frequency
          const freqMap = new Map<string, number>(
            coOccurrenceResults.map((r) => [r._id.toString(), r.coCount]),
          );
          products.sort(
            (a, b) => (freqMap.get(b._id.toString()) || 0) - (freqMap.get(a._id.toString()) || 0),
          );

          for (const product of products) {
            const idStr = product._id.toString();
            if (!excludeIdSet.has(idStr) && recommendedMap.size < limit) {
              recommendedMap.set(idStr, product);
              excludeIdSet.add(idStr);
            }
          }
        }
      } catch (err: any) {
        this.logger.warn(`Co-occurrence aggregation failed: ${err.message}`);
      }
    }

    // 3. STRATEGY B: Complementary Category Matrix
    if (recommendedMap.size < limit && validProductIds.length > 0) {
      try {
        const cartProducts = await this.productModel
          .find({
            _id: { $in: validProductIds.map((id) => new Types.ObjectId(id)) },
          })
          .select('category name')
          .lean()
          .exec();

        const cartCategories = cartProducts
          .map((p) => p.category?.toLowerCase().trim())
          .filter(Boolean);

        const targetCategorySet = new Set<string>();
        for (const cat of cartCategories) {
          for (const [key, complements] of Object.entries(this.complementaryCategories)) {
            if (cat.includes(key) || key.includes(cat)) {
              complements.forEach((c) => targetCategorySet.add(c));
            }
          }
        }

        if (targetCategorySet.size > 0) {
          const regexList = Array.from(targetCategorySet).map((c) => new RegExp(c, 'i'));
          const complementProducts = await this.productModel
            .find({
              _id: { $nin: Array.from(excludeIdSet).map((id) => new Types.ObjectId(id)) },
              category: { $in: regexList },
              ...baseFilter,
            })
            .populate('shop', 'name logo isVerified address')
            .sort({ stockQuantity: -1 })
            .limit(limit - recommendedMap.size)
            .lean()
            .exec();

          for (const product of complementProducts) {
            const idStr = product._id.toString();
            if (!excludeIdSet.has(idStr) && recommendedMap.size < limit) {
              recommendedMap.set(idStr, product);
              excludeIdSet.add(idStr);
            }
          }
        }
      } catch (err: any) {
        this.logger.warn(`Category complement recommendation failed: ${err.message}`);
      }
    }

    // 4. STRATEGY C: Top In-Stock Bestseller Fallback
    if (recommendedMap.size < limit) {
      try {
        const fallbackProducts = await this.productModel
          .find({
            _id: { $nin: Array.from(excludeIdSet).map((id) => new Types.ObjectId(id)) },
            ...baseFilter,
          })
          .populate('shop', 'name logo isVerified address')
          .sort({ stockQuantity: -1, createdAt: -1 })
          .limit(limit - recommendedMap.size)
          .lean()
          .exec();

        for (const product of fallbackProducts) {
          const idStr = product._id.toString();
          if (!excludeIdSet.has(idStr) && recommendedMap.size < limit) {
            recommendedMap.set(idStr, product);
            excludeIdSet.add(idStr);
          }
        }
      } catch (err: any) {
        this.logger.warn(`Bestseller fallback recommendation failed: ${err.message}`);
      }
    }

    const finalRecommendations = Array.from(recommendedMap.values());

    // 5. Store in Redis Cache for 10 minutes (600 seconds)
    try {
      await this.cacheService.set(cacheKey, JSON.stringify(finalRecommendations), 600);
    } catch (err: any) {
      this.logger.warn(`Redis cache write failed: ${err.message}`);
    }

    return finalRecommendations;
  }
}
