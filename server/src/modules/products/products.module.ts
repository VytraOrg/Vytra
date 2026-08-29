import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProductsService } from './products.service';
import { ProductsController } from './products.controller';
import { Product, ProductSchema } from './schemas/product.schema';
import { CacheModule } from '../cache/cache.module';
import { SynonymsService } from './services/synonyms.service';
import { SpellcheckService } from './services/spellcheck.service';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Product.name, schema: ProductSchema }]),
    CacheModule,
  ],
  providers: [ProductsService, SynonymsService, SpellcheckService],
  controllers: [ProductsController],
  exports: [ProductsService, SynonymsService, SpellcheckService],
})
export class ProductsModule {}
