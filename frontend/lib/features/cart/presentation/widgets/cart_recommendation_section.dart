import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../shop/data/product_model.dart';
import '../../data/recommendations_service.dart';
import '../controllers/cart_controller.dart';

class CartRecommendationSection extends StatefulWidget {
  final List<String> cartProductIds;

  const CartRecommendationSection({
    super.key,
    required this.cartProductIds,
  });

  @override
  State<CartRecommendationSection> createState() => _CartRecommendationSectionState();
}

class _CartRecommendationSectionState extends State<CartRecommendationSection> {
  final RecommendationsService _recommendationsService = RecommendationsService();
  List<ProductModel> _recommendations = [];
  bool _isLoading = false;
  String _lastFetchedKey = '';

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  @override
  void didUpdateWidget(covariant CartRecommendationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentKey = [...widget.cartProductIds]..sort();
    final oldKey = [...oldWidget.cartProductIds]..sort();
    if (currentKey.join(',') != oldKey.join(',')) {
      _fetchRecommendations();
    }
  }

  Future<void> _fetchRecommendations() async {
    final currentKey = ([...widget.cartProductIds]..sort()).join(',');
    if (currentKey == _lastFetchedKey && _recommendations.isNotEmpty) return;

    setState(() => _isLoading = true);
    try {
      final items = await _recommendationsService.getCartRecommendations(
        productIds: widget.cartProductIds,
        limit: 8,
      );
      if (mounted) {
        setState(() {
          _recommendations = items;
          _lastFetchedKey = currentKey;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final cartController = context.watch<CartController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequently Bought Together',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Pairs well with items in your cart',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 228,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _recommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final product = _recommendations[index];
              return _buildRecommendationCard(context, product, cartController, index);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    ProductModel product,
    CartController cartController,
    int index,
  ) {
    final quantity = cartController.getProductQuantity(product.id);
    final isPending = cartController.isProductPending(product.id);

    return Container(
      width: 148,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primaryLight, width: 1.2),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Stack(
                children: [
                  Center(
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? AppNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          )
                        : const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 36),
                  ),
                  if (product.stockQuantity <= 5 && product.stockQuantity > 0)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Only ${product.stockQuantity} left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Product Name
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.2,
            ),
          ),

          // Unit
          Text(
            product.unit,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),

          // Price & Add / Stepper Button Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${product.price.toInt()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              if (isPending)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                )
              else if (quantity > 0)
                // Active Quantity Stepper
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (quantity > 1) {
                            cartController.addToCart(product.id, quantity: -1);
                          } else {
                            cartController.removeFromCart(product.id);
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.remove, size: 14, color: Colors.white),
                        ),
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          cartController.addToCart(product.id, quantity: 1);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.add, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Instant + ADD Button
                GestureDetector(
                  onTap: () {
                    cartController.addToCart(product.id, quantity: 1);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accent, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 13, color: AppColors.primary),
                        SizedBox(width: 2),
                        Text(
                          'ADD',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.05);
  }
}
