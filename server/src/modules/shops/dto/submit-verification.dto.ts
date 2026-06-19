import { IsNotEmpty, IsString, Length, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class SubmitVerificationDto {
  @ApiProperty({ example: 'John Doe' })
  @IsNotEmpty()
  @IsString()
  ownerName: string;

  @ApiProperty({ example: '9876543210' })
  @IsNotEmpty()
  @IsString()
  @Length(10, 15)
  ownerPhone: string;

  @ApiProperty({ example: 'Fresh Mart' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ example: 'Grocery' })
  @IsNotEmpty()
  @IsString()
  category: string;

  @ApiProperty({ example: 'All daily needs and fresh produce' })
  @IsNotEmpty()
  @IsString()
  description: string;

  @ApiProperty({ example: '12, M.G. Road, Sector 4' })
  @IsNotEmpty()
  @IsString()
  address: string;

  @ApiProperty({ example: 'Kolkata' })
  @IsNotEmpty()
  @IsString()
  district: string;

  @ApiProperty({ example: 'West Bengal' })
  @IsNotEmpty()
  @IsString()
  state: string;

  @ApiProperty({ example: '700001' })
  @IsNotEmpty()
  @IsString()
  @Length(6, 6)
  @Matches(/^[0-9]+$/, { message: 'Pincode must contain only numbers' })
  pincode: string;

  @ApiProperty({ example: '19AAAAA0000A1Z5' })
  @IsNotEmpty()
  @IsString()
  @Length(15, 15)
  @Matches(/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/, { 
    message: 'Invalid GSTIN format' 
  })
  gstNumber: string;

  @ApiProperty({ example: 'TL-8827361' })
  @IsNotEmpty()
  @IsString()
  tradeLicenseNumber: string;
}
