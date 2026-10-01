import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../data/product_model.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../screens/product_list.dart';

class GlobalProductCard extends StatelessWidget {
  final ProductModel product;
  final int index;
  final String customerId;
  final bool disableShopNavigation;
  final bool isTab;

  const GlobalProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.customerId,
    this.disableShopNavigation = false,
    this.isTab = false,
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
                      Expanded(
                        child: Text(
                          product.shopName ?? 'Local Store',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.distanceKm != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 11, color: AppColors.primary),
                              const SizedBox(width: 2),
                              Text(
                                "${product.distanceKm!.toStringAsFixed(1)} km",
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!product.isAvailable || product.stockQuantity <= 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: Colors.red.shade200, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.remove_circle_outline_rounded, size: 11, color: Colors.red.shade700),
                          const SizedBox(width: 3),
                          Text(
                            "Out of stock",
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (product.stockQuantity <= 5) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: const Color(0xFFFFB74D), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, size: 11, color: Color(0xFFE65100)),
                          const SizedBox(width: 3),
                          Text(
                            product.stockQuantity == 1 ? "Only 1 left in stock!" : "Only ${product.stockQuantity} left",
                            style: const TextStyle(
                              color: Color(0xFFE65100),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹${product.price} / ${product.unit}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.freshGreen),
                      ),
                      GestureDetector(
                        onTap: (!product.isAvailable || product.stockQuantity <= 0)
                            ? null
                            : () async {
                                final cartController = context.read<CartController>();
                                await cartController.addToCart(product.id, quantity: 1);
                                if (context.mounted) {
                                  AppNotification.showAddedToCart(
                                    context,
                                    productName: product.name,
                                    priceInfo: '₹${product.price} / ${product.unit}',
                                    isTab: isTab,
                                  );
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: (!product.isAvailable || product.stockQuantity <= 0)
                                ? Colors.grey.shade300
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            (!product.isAvailable || product.stockQuantity <= 0) ? "OUT" : "ADD",
                            style: TextStyle(
                              color: (!product.isAvailable || product.stockQuantity <= 0)
                                  ? Colors.grey.shade600
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
