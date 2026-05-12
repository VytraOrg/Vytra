import { IsNotEmpty, IsString, IsOptional, IsEnum, IsArray, IsNumber } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateShopDto {
  @ApiProperty({ example: 'Fresh Mart' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ example: '6a00bf3393b2dda8d14afe5a' })
  @IsNotEmpty()
  @IsString()
  owner: string;

  @ApiProperty({ example: 'Grocery' })
  @IsNotEmpty()
  @IsString()
  category: string;

  @ApiProperty({ enum: ['Retailer', 'Distributor'], default: 'Retailer' })
  @IsEnum(['Retailer', 'Distributor'])
  shopType: string;

  @ApiProperty({ example: 'All your daily needs in one place' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 'https://image.url' })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiProperty({
    example: { type: 'Point', coordinates: [88.3639, 22.5726] },
  })
  @IsOptional()
  location?: {
    type: string;
    coordinates: number[];
  };
}
