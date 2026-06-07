import * as dns from 'dns';
dns.setServers(['8.8.8.8', '8.8.4.4']);

import { NestFactory } from '@nestjs/core';
import { ValidationPipe, VersioningType, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import compression from 'compression';
import helmet from 'helmet';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // 1. Security & Optimization
  app.use(helmet());
  app.use(compression());
  app.enableCors();

  // 2. Global Prefix & Versioning
  app.setGlobalPrefix('api');
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // 3. Global Filters & Pipes
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // 4. Swagger Documentation
  const config = new DocumentBuilder()
    .setTitle('Local Commerce API')
    .setDescription('The Enterprise-Grade Backend API for Local Commerce App')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);

  const configService = app.get(ConfigService);

  const port =
    process.env.PORT ||
    configService.get<number>('PORT', 5001);

  logger.log(`PORT from env: ${process.env.PORT}`);

  await app.listen(Number(port), '0.0.0.0');

  logger.log(`🚀 Server running on port ${port}`);
  logger.log(`📝 Swagger documentation: /docs`);
}
bootstrap();
