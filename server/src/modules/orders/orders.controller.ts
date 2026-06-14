import { Controller, Get, Post, Put, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';

@ApiTags('Orders')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  @ApiOperation({ summary: 'Place a new order from current cart' })
  createOrder(@Request() req, @Body() createOrderDto: CreateOrderDto) {
    return this.ordersService.createOrder(req.user._id, createOrderDto.deliveryAddress);
  }

  @Get('my')
  @ApiOperation({ summary: 'Get current user orders' })
  getMyOrders(@Request() req) {
    return this.ordersService.getMyOrders(req.user._id);
  }

  @Get('my-shop')
  @UseGuards(RolesGuard)
  @Roles('Shopkeeper', 'Admin')
  @ApiOperation({ summary: 'Get orders for the shop owned by current user' })
  getMyShopOrders(@Request() req) {
    return this.ordersService.getMyShopOrders(req.user._id);
  }

  @Put(':id/status')
  @UseGuards(RolesGuard)
  @Roles('Shopkeeper', 'Admin')
  @ApiOperation({ summary: 'Update order status (Shopkeepers/Admin only)' })
  updateStatus(@Param('id') id: string, @Body() updateOrderStatusDto: UpdateOrderStatusDto) {
    return this.ordersService.updateOrderStatus(id, updateOrderStatusDto.status);
  }
}
