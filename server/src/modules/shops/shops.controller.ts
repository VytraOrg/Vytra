import { Controller, Get, Post, Body, Query } from '@nestjs/common';
import { ShopsService } from './shops.service';

@Controller('shops')
export class ShopsController {
  constructor(private readonly shopsService: ShopsService) {}

  @Get()
  async getShops(
    @Query('category') category?: string,
    @Query('shopType') shopType?: string,
    @Query('search') search?: string,
  ) {
    return this.shopsService.findFiltered(category, shopType, search);
  }

  @Post()
  async createShop(@Body() shopData: any) {
    return this.shopsService.create(shopData);
  }
}
