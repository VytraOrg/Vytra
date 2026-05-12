import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system.dart';
import '../../domain/order_model.dart';

class OrderDetailsPage extends StatelessWidget {
  final OrderModel order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Order #${order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0).toUpperCase()}"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildItemsList(),
            const SizedBox(height: AppSpacing.lg),
            _buildDeliveryInfo(),
            const SizedBox(height: AppSpacing.lg),
            _buildPaymentSummary(),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Need Help?"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    String statusTitle;
    String statusSub;
    IconData icon;

    switch (order.status) {
      case 'Delivered':
        statusTitle = "Order Delivered";
        statusSub = "Thank you for shopping with us!";
        icon = Icons.check_circle_outline;
        break;
      case 'Cancelled':
        statusTitle = "Order Cancelled";
        statusSub = "This order was cancelled.";
        icon = Icons.cancel_outlined;
        break;
      default:
        statusTitle = "Order is ${order.status}";
        statusSub = "Your order is being processed.";
        icon = Icons.local_shipping_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.premium,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text(statusSub, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: const Text("Tracking", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Items Ordered", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
        const SizedBox(height: AppSpacing.md),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: order.items.length,
          itemBuilder: (context, index) {
            final item = order.items[index];
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("${item.quantity} x ${item.unit}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text("₹${(item.price * item.quantity).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text("Delivery Address", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.deliveryAddress?.toString() ?? "Default Address",
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subtotal", style: TextStyle(color: AppColors.textSecondary)),
              Text("₹${order.totalAmount.toStringAsFixed(2)}"),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Delivery Fee", style: TextStyle(color: AppColors.textSecondary)),
              Text("FREE", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("₹${order.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}
