import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { ThrottlerModule } from '@nestjs/throttler';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { ShopsModule } from './modules/shops/shops.module';
import { ProductsModule } from './modules/products/products.module';
import { OrdersModule } from './modules/orders/orders.module';
import { CacheModule } from './modules/cache/cache.module';
import { CartModule } from './modules/cart/cart.module';

@Module({
  imports: [
    // 1. Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // 2. Security (Rate Limiting)
    ThrottlerModule.forRoot([{
      ttl: 60000,
      limit: 100,
    }]),

    // 3. Database Connection
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri: configService.get<string>('MONGODB_URI'),
        family: 4, // Force IPv4 to avoid DNS resolution issues
        serverSelectionTimeoutMS: 15000,
        connectTimeoutMS: 15000,
      }),
      inject: [ConfigService],
    }),

    // 4. Feature Modules
    AuthModule,
    UsersModule,
    ShopsModule,
    ProductsModule,
    OrdersModule,
    CacheModule,
    CartModule,
  ],
})
export class AppModule {}
