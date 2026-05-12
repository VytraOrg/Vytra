import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../domain/order_model.dart';
import '../controllers/order_controller.dart';
import 'order_details_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderController>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderController = context.watch<OrderController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Orders"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => orderController.fetchOrders(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: orderController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderController.error != null
              ? Center(child: Text("Error: ${orderController.error}"))
              : orderController.orders.isEmpty
                  ? const Center(child: Text("No orders found yet."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: orderController.orders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(context, orderController.orders[index], index);
                      },
                    ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, int index) {
    Color statusColor;
    switch (order.status) {
      case 'Delivered':
        statusColor = AppColors.success;
        break;
      case 'Cancelled':
        statusColor = AppColors.error;
        break;
      case 'Processing':
      case 'Shipped':
        statusColor = AppColors.skyBlue;
        break;
      default:
        statusColor = AppColors.organicAmber;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order #${order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0).toUpperCase()}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "Placed on ${order.createdAt.day} ${_getMonth(order.createdAt.month)}, ${order.createdAt.year}",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Items", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text("${order.items.length} Items", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Amount", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text("₹${order.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsPage(order: order),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text("Details", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
