import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../data/shop_model.dart';
import '../screens/product_list.dart';

class ShopCard extends StatelessWidget {
  final ShopModel shop;
  final int index;
  final String customerId;

  const ShopCard({
    super.key,
    required this.shop,
    required this.index,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductList(
            shopName: shop.name,
            shopId: shop.id,
            customerId: customerId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  imageUrl: shop.imageUrl ?? "",
                  height: 160,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text("${shop.rating}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shop.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Text("1.2 km away", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            SizedBox(width: 12),
                            Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Text("25 mins", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1),
    );
  }
}
