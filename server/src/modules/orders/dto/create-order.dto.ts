import { IsNotEmpty, IsObject, IsOptional, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateOrderDto {
  @ApiProperty({
    example: {
      street: '123 Main St',
      city: 'Kolkata',
      state: 'WB',
      zip: '700001',
    },
  })
  @IsNotEmpty()
  @IsObject()
  deliveryAddress: any;

  @ApiProperty({ example: 'Special instructions...', required: false })
  @IsOptional()
  @IsString()
  note?: string;
}
