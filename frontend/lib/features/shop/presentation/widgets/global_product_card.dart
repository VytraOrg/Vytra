import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../data/product_model.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../screens/product_list.dart';

class GlobalProductCard extends StatelessWidget {
  final ProductModel product;
  final int index;
  final String customerId;
  final bool disableShopNavigation;

  const GlobalProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.customerId,
    this.disableShopNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disableShopNavigation
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductList(
                    shopName: product.shopName ?? 'Store',
                    shopId: product.shopId,
                    customerId: customerId,
                  ),
                ),
              ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            AppNetworkImage(
              imageUrl: product.imageUrl ?? "",
              height: 90,
              width: 90,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        product.shopName ?? 'Local Store',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹${product.price} / ${product.unit}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.freshGreen),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final cartController = context.read<CartController>();
                          await cartController.addToCart(product.id, quantity: 1);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Text(
                            "ADD",
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
  }
}
