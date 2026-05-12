import { IsNotEmpty, IsString, IsNumber, IsOptional, IsBoolean, IsArray, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateProductDto {
  @ApiProperty({ example: 'Basmati Rice' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ example: 'Premium quality long grain rice' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 'Grocery' })
  @IsNotEmpty()
  @IsString()
  category: string;

  @ApiProperty({ example: 150 })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  price: number;

  @ApiProperty({ example: '1 kg' })
  @IsNotEmpty()
  @IsString()
  unit: string;

  @ApiProperty({ example: 100 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  stockQuantity?: number;

  @ApiProperty({ example: ['url1', 'url2'], required: false })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];

  @ApiProperty({ example: '6a00bf3393b2dda8d14afe5a' })
  @IsNotEmpty()
  @IsString()
  shop: string;
}
