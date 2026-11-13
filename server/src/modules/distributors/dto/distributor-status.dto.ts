import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsIn, IsOptional, IsString } from 'class-validator';

export class UpdateDistributorStatusDto {
  @ApiPropertyOptional({ description: 'Manual ON/OFF toggle' })
  @IsBoolean()
  @IsOptional()
  isOpen?: boolean;

  @ApiPropertyOptional({ description: 'Accepting incoming orders toggle' })
  @IsBoolean()
  @IsOptional()
  isAcceptingOrders?: boolean;

  @ApiPropertyOptional({ description: 'Whether rates are actively being edited' })
  @IsBoolean()
  @IsOptional()
  isUpdatingRates?: boolean;

  @ApiPropertyOptional({ enum: ['open', 'paused', 'updating', 'closed'] })
  @IsString()
  @IsOptional()
  @IsIn(['open', 'paused', 'updating', 'closed'])
  status?: string;
}

