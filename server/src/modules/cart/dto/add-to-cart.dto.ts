import { IsNotEmpty, IsString, IsNumber, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AddToCartDto {
  @ApiProperty({ example: '6a00bf3393b2dda8d14afe5a' })
  @IsNotEmpty()
  @IsString()
  productId: string;

  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @IsNumber()
  quantity: number;
}
