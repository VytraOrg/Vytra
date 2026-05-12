import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../../orders/presentation/controllers/order_controller.dart';
import '../../../orders/presentation/screens/orders_page.dart';
import '../controllers/cart_controller.dart';

import '../../domain/cart_model.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartController>().fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartController = context.watch<CartController>();
    final cart = cartController.cart;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Cart"),
        centerTitle: true,
      ),
      body: cartController.isLoading && cart == null
          ? const Center(child: CircularProgressIndicator())
          : cart == null || cart.items.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return _buildCartItem(context, item, index);
                        },
                      ),
                    ),
                    _buildCheckoutSection(context, cart),
                  ],
                ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: AppSpacing.lg),
          const Text("Your cart is empty", style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Go Shopping"),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItemModel item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("₹${item.price} per unit", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              _buildQtyBtn(Icons.remove, () {
                if (item.quantity > 1) {
                  context.read<CartController>().addToCart(item.productId, quantity: -1);
                } else {
                  context.read<CartController>().removeFromCart(item.productId);
                }
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              _buildQtyBtn(Icons.add, () {
                context.read<CartController>().addToCart(item.productId, quantity: 1);
              }),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, dynamic cart) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount", style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              Text("₹${cart.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () async {
              final orderController = context.read<OrderController>();
              final success = await orderController.placeOrder({
                'address': '123 Green Valley, Sector 5, Kolkata',
              });
              if (success && mounted) {
                context.read<CartController>().fetchCart(); // Clear local cart
                _showOrderSuccess(context);
              }
            },
            child: context.watch<OrderController>().isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Checkout Now"),
          ),
        ],
      ),
    );
  }

  void _showOrderSuccess(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 100),
            const SizedBox(height: 20),
            const Text("Order Placed!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Your items are on their way to you.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close sheet
                Navigator.pop(context); // Go back home
                Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersPage()));
              },
              child: const Text("Track Order"),
            ),
          ],
        ),
      ),
    );
  }
}