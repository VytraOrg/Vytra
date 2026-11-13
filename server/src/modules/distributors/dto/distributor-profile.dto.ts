import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class UpdateDistributorProfileDto {
  @ApiProperty({ description: 'Agency / Business name' })
  @IsString()
  @IsNotEmpty()
  agencyName: string;

  @ApiPropertyOptional({ description: 'Owner name' })
  @IsString()
  @IsOptional()
  ownerName?: string;

  @ApiPropertyOptional({ description: 'Owner phone' })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({ description: 'Owner or agency email' })
  @IsString()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ description: 'Physical address' })
  @IsString()
  @IsOptional()
  address?: string;

  @ApiPropertyOptional({ description: 'GST number' })
  @IsString()
  @IsOptional()
  gstNo?: string;

  @ApiPropertyOptional({ description: 'Trade license number' })
  @IsString()
  @IsOptional()
  tradeLicenseNo?: string;

  @ApiPropertyOptional({ description: 'FSSAI registration number' })
  @IsString()
  @IsOptional()
  fssaiNo?: string;
}

