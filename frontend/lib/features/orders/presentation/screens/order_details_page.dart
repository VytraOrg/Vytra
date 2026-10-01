import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../domain/order_model.dart';
import '../controllers/order_controller.dart';

class OrderDetailsPage extends StatefulWidget {
  final OrderModel order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool _isCancelling = false;

  Future<void> _handleCancelOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Cancel Order?"),
        content: Text(
          "Are you sure you want to cancel Order #${order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0).toUpperCase()}? The reserved items will be returned to store stock.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text("Keep Order"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text("Yes, Cancel Order"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    final error = await context.read<OrderController>().cancelOrder(order.id);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order cancelled successfully"),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderController = context.watch<OrderController>();
    final order = orderController.orders.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );

    final statusLower = order.status.trim().toLowerCase();
    final canCancel = ['placed', 'processing', 'preparing'].contains(statusLower);
    final isDispatched = ['dispatched', 'shipped', 'out for delivery'].contains(statusLower);
    final isDelivered = statusLower == 'delivered';
    final isCancelled = statusLower == 'cancelled';

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
            _buildStatusCard(order, isDelivered, isCancelled, isDispatched),
            const SizedBox(height: AppSpacing.lg),
            _buildItemsList(order),
            const SizedBox(height: AppSpacing.lg),
            _buildDeliveryInfo(order),
            const SizedBox(height: AppSpacing.lg),
            _buildPaymentSummary(order),
            if (canCancel) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isCancelling ? null : () => _handleCancelOrder(order),
                  icon: _isCancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                        )
                      : const Icon(Icons.cancel_outlined, color: AppColors.error),
                  label: Text(
                    _isCancelling ? "Cancelling Order..." : "Cancel Order",
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ),
            ] else if (isDispatched) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade800, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        "This order has been dispatched and can no longer be cancelled.",
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isCancelled) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        "This order was cancelled. Reserved items have been returned to inventory.",
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Need Help?"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(OrderModel order, bool isDelivered, bool isCancelled, bool isDispatched) {
    String statusTitle;
    String statusSub;
    IconData icon;
    Color cardColor;

    if (isDelivered) {
      statusTitle = "Order Delivered";
      statusSub = "Thank you for shopping with us!";
      icon = Icons.check_circle_outline;
      cardColor = AppColors.success;
    } else if (isCancelled) {
      statusTitle = "Order Cancelled";
      statusSub = "This order was cancelled.";
      icon = Icons.cancel_outlined;
      cardColor = AppColors.error;
    } else if (isDispatched) {
      statusTitle = "Order Dispatched";
      statusSub = "Your package is on its way to you.";
      icon = Icons.local_shipping_outlined;
      cardColor = AppColors.skyBlue;
    } else {
      statusTitle = "Order is ${order.status}";
      statusSub = "Your order is being processed.";
      icon = Icons.inventory_2_outlined;
      cardColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
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
            child: Text(
              order.status.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildItemsList(OrderModel order) {
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

  Widget _buildDeliveryInfo(OrderModel order) {
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
            order.deliveryAddress is Map
                ? ((order.deliveryAddress as Map)['address'] ?? (order.deliveryAddress as Map)['street'] ?? order.deliveryAddress.toString())
                : (order.deliveryAddress?.toString() ?? "Default Address"),
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildPaymentSummary(OrderModel order) {
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
