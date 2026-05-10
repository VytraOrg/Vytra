import { IsEmail, IsNotEmpty, IsString, MinLength, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({ example: 'John Doe' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ example: 'john@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'password123', minLength: 6 })
  @IsNotEmpty()
  @MinLength(6)
  password: string;

  @ApiProperty({ enum: ['Customer', 'Shopkeeper', 'Distributor'], default: 'Customer' })
  @IsEnum(['Customer', 'Shopkeeper', 'Distributor'])
  role: string;

  @ApiProperty({ example: 'My Awesome Shop', required: false })
  @IsOptional()
  @IsString()
  businessName?: string;
}
