import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateDistributorProductDto {
  @ApiProperty({ example: 'Fortune Sunflower Oil' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'Staples' })
  @IsString()
  @IsNotEmpty()
  category: string;

  @ApiProperty({ example: '1 L' })
  @IsString()
  @IsNotEmpty()
  unit: string;

  @ApiProperty({ example: 142 })
  @IsNumber()
  @Min(0)
  rate: number;

  @ApiProperty({ example: 120 })
  @IsNumber()
  @Min(0)
  stock: number;

  @ApiPropertyOptional({ example: 5, default: 5 })
  @IsNumber()
  @IsOptional()
  gstPercent?: number;

  @ApiPropertyOptional({ example: 1, default: 1 })
  @IsNumber()
  @IsOptional()
  minOrderQty?: number;

  @ApiPropertyOptional({ default: true })
  @IsBoolean()
  @IsOptional()
  isAvailable?: boolean;
}

export class UpdateDistributorProductDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  category?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  unit?: string;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  @Min(0)
  rate?: number;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  @Min(0)
  stock?: number;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  gstPercent?: number;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  minOrderQty?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isAvailable?: boolean;
}

export class BatchUpdateRatesDto {
  @ApiProperty({ description: 'Map of productId -> new rate', example: { 'prod_1': 145, 'prod_2': 250 } })
  rates: Record<string, number>;
}

