import { IsEmail, IsNotEmpty, IsString, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: 'john@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'password123' })
  @IsNotEmpty()
  @IsString()
  password: string;

  @ApiProperty({ enum: ['Customer', 'Shopkeeper', 'Distributor', 'Admin'] })
  @IsEnum(['Customer', 'Shopkeeper', 'Distributor', 'Admin'])
  role: string;
}
