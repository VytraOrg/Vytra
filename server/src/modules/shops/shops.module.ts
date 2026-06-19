import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ShopsController } from './shops.controller';
import { ShopsService } from './shops.service';
import { Shop, ShopSchema } from './schemas/shop.schema';
import { User, UserSchema } from '../users/schemas/user.schema';
import { CloudinaryService } from './cloudinary.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Shop.name, schema: ShopSchema },
      { name: User.name, schema: UserSchema },
    ]),
  ],
  controllers: [ShopsController],
  providers: [ShopsService, CloudinaryService],
  exports: [ShopsService, CloudinaryService],
})
export class ShopsModule {}
