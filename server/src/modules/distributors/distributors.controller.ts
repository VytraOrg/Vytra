import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { DistributorsService } from './distributors.service';
import { UpdateDistributorProfileDto } from './dto/distributor-profile.dto';
import { UpdateDistributorStatusDto } from './dto/distributor-status.dto';
import {
  CreateDistributorProductDto,
  UpdateDistributorProductDto,
  BatchUpdateRatesDto,
} from './dto/distributor-inventory.dto';

@ApiTags('distributors')
@Controller({ path: 'distributors', version: '1' })
export class DistributorsController {
  constructor(private readonly distributorsService: DistributorsService) {}

  @Get('public/all')
  @ApiOperation({ summary: 'List all distributors (Public for shopkeepers)' })
  async listAll() {
    return this.distributorsService.listAllDistributors();
  }

  @Get('my')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Distributor', 'Admin')
  @ApiOperation({ summary: 'Get current distributor profile and agency status' })
  async getProfile(@Req() req: any) {
    return this.distributorsService.getProfile(req.user._id);
  }

  @Put('my/profile')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Distributor', 'Admin')
  @ApiOperation({ summary: 'Update distributor business details and compliance' })
  async updateProfile(@Req() req: any, @Body() dto: UpdateDistributorProfileDto) {
    return this.distributorsService.updateProfile(req.user._id, dto);
  }

  @Put('my/status')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Distributor', 'Admin')
  @ApiOperation({ summary: 'Update agency open/closed/paused/updating state' })
  async updateStatus(@Req() req: any, @Body() dto: UpdateDistributorStatusDto) {
    return this.distributorsService.updateStatus(req.user._id, dto);
  }

  @Get('inventory')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Distributor', 'Admin')
  @ApiOperation({ summary: 'Get distributor inventory items' })
  async getInventory(@Req() req: any) {
    return this.distributorsService.getInventory(req.user._id);
  }

  @Post('inventory')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Distributor', 'Admin')
  @ApiOperation({ summary: 'Add a new product to inventory' })
  async addInventoryItem(@Req() req: any, @Body() dto: CreateDistributorProductDto) {
    return this.distributorsService.addInventoryItem(req.user._id, dto);
  }

  @Put('inventory/rates')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Distributor', 'Admin')
  @ApiOperation({ summary: 'Batch update wholesale rates' })
  async batchUpdateRates(@Req() req: any, @Body() dto: BatchUpdateRatesDto) {
    return this.distributorsService.batchUpdateRates(req.user._id, dto.rates);
  }

  @Put('inventory/:id')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Distributor', 'Admin')
  @ApiOperation({ summary: 'Update an inventory item' })
  async updateInventoryItem(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateDistributorProductDto,
  ) {
    return this.distributorsService.updateInventoryItem(req.user._id, id, dto);
  }

  @Put('inventory/:id/availability')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Distributor', 'Admin')
  @ApiOperation({ summary: 'Toggle inventory item availability' })
  async setAvailability(
    @Req() req: any,
    @Param('id') id: string,
    @Body() body: { isAvailable: boolean },
  ) {
    return this.distributorsService.setProductAvailable(req.user._id, id, body.isAvailable);
  }

  @Delete('inventory/:id')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Distributor', 'Admin')
  @ApiOperation({ summary: 'Delete an inventory item' })
  async deleteInventoryItem(@Req() req: any, @Param('id') id: string) {
    return this.distributorsService.deleteInventoryItem(req.user._id, id);
  }

  @Get('orders')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Distributor', 'Admin')
  @ApiOperation({ summary: 'Get incoming orders for distributor' })
  async getOrders(@Req() req: any) {
    return this.distributorsService.getOrders(req.user._id);
  }

  @Put('orders/:id/status')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('Distributor', 'Admin')
  @ApiOperation({ summary: 'Update delivery status of an order' })
  async updateOrderStatus(
    @Req() req: any,
    @Param('id') id: string,
    @Body() body: { status: string },
  ) {
    return this.distributorsService.updateOrderStatus(req.user._id, id, body.status);
  }
}

