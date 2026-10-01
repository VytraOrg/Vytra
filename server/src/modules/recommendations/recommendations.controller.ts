import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { RecommendationsService } from './recommendations.service';

@ApiTags('Recommendations')
@Controller('recommendations')
export class RecommendationsController {
  constructor(private readonly recommendationsService: RecommendationsService) {}

  @Get('cart')
  @ApiOperation({
    summary: 'Get smart cart recommendations',
    description:
      'Returns frequently co-ordered items and complementary category items based on products currently in the cart and shop context.',
  })
  @ApiQuery({ name: 'shopId', required: false, description: 'Optional shop context ID' })
  @ApiQuery({
    name: 'productIds',
    required: false,
    description: 'Comma-separated product IDs currently in the cart',
  })
  @ApiQuery({ name: 'limit', required: false, description: 'Number of recommendations (default: 6)' })
  @ApiResponse({ status: 200, description: 'List of recommended in-stock products' })
  async getCartRecommendations(
    @Query('shopId') shopId?: string,
    @Query('productIds') productIds?: string,
    @Query('limit') limit?: string,
  ) {
    const parsedProductIds = productIds
      ? productIds
          .split(',')
          .map((id) => id.trim())
          .filter(Boolean)
      : [];
    const parsedLimit = limit ? parseInt(limit, 10) : 6;

    const recommendations = await this.recommendationsService.getCartRecommendations({
      shopId,
      productIds: parsedProductIds,
      limit: parsedLimit,
    });

    return {
      success: true,
      count: recommendations.length,
      data: recommendations,
    };
  }
}
