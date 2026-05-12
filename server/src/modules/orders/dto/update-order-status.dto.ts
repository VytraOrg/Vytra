import { IsEnum, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateOrderStatusDto {
  @ApiProperty({ enum: ['Placed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'] })
  @IsNotEmpty()
  @IsEnum(['Placed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'])
  status: string;
}
