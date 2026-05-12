import { NestFactory } from '@nestjs/core';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import * as compression from 'compression';
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 1. Security & Optimization
  app.use(helmet());
  app.enableCors();

  // Logging Middleware
  app.use((req, res, next) => {
    console.log(`🚀 [${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
    next();
  });

  // 2. Global Prefix & Versioning
  app.setGlobalPrefix('api');
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // 3. Global Validation Pipe
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
  const port = configService.get<number>('PORT', 5001);
  await app.listen(port);
  console.log(`🚀 Server running on: http://localhost:${port}/api/v1`);
  console.log(`📝 Swagger documentation: http://localhost:${port}/docs`);
}
bootstrap();
