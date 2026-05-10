import { Controller, Get, Post, Put, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@ApiTags('Orders')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  @ApiOperation({ summary: 'Place a new order from current cart' })
  createOrder(@Request() req, @Body() body: { deliveryAddress: any }) {
    return this.ordersService.createOrder(req.user._id, body.deliveryAddress);
  }

  @Get('my')
  @ApiOperation({ summary: 'Get current user orders' })
  getMyOrders(@Request() req) {
    return this.ordersService.getMyOrders(req.user._id);
  }

  @Put(':id/status')
  @UseGuards(RolesGuard)
  @Roles('Shopkeeper', 'Admin')
  @ApiOperation({ summary: 'Update order status (Shopkeepers/Admin only)' })
  updateStatus(@Param('id') id: string, @Body() body: { status: string }) {
    return this.ordersService.updateOrderStatus(id, body.status);
  }
}
