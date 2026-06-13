import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ShopsController } from './shops.controller';
import { ShopsService } from './shops.service';
import { Shop, ShopSchema } from './schemas/shop.schema';
import { CloudinaryService } from './cloudinary.service';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Shop.name, schema: ShopSchema }]),
  ],
  controllers: [ShopsController],
  providers: [ShopsService, CloudinaryService],
  exports: [ShopsService, CloudinaryService],
})
export class ShopsModule {}
