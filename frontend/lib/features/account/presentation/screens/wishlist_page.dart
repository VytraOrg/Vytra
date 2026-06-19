import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../../shop/domain/entities/product_entity.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  // Mock wishlist items using the Product class
  final List<Product> _wishlistItems = [
    Product(
      id: 'prod_banana_123',
      name: 'Fresh Organic Bananas',
      description: 'Sweet and rich in potassium, direct from local farms.',
      category: 'Fruits',
      price: 60,
      unit: '1 kg',
      stockQuantity: 15,
      imageUrl: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&q=80&w=400',
      shopId: '6a258d2d7cd66fc03fe14a3c',
      shopName: 'Fresh Mart',
    ),
    Product(
      id: 'prod_milk_456',
      name: 'Amul Taaza Toned Milk',
      description: 'Fresh homogenized milk, pasteurized for quality.',
      category: 'Dairy',
      price: 54,
      unit: '1 L',
      stockQuantity: 20,
      imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80&w=400',
      shopId: '6a258d2d7cd66fc03fe14a3c',
      shopName: 'Fresh Mart',
    ),
    Product(
      id: 'prod_eggs_789',
      name: 'Farm Fresh Brown Eggs',
      description: 'High-protein, farm fresh brown eggs, pack of 6.',
      category: 'Dairy & Eggs',
      price: 75,
      unit: '6 pcs',
      stockQuantity: 8,
      imageUrl: 'https://images.unsplash.com/photo-1516448620398-c5f44bf9f441?auto=format&fit=crop&q=80&w=400',
      shopId: '6a258d2d7cd66fc03fe14a3c',
      shopName: 'Green Grocery',
    ),
  ];

  void _removeFromWishlist(String id) {
    setState(() {
      _wishlistItems.removeWhere((item) => item.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from Wishlist'),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    final cartController = context.read<CartController>();
    try {
      await cartController.addToCart(product.id, quantity: 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart!'),
            backgroundColor: AppColors.freshGreen,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () => cartController.addToCart(product.id, quantity: -1),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not add to cart: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Wishlist', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _wishlistItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline_rounded, size: 80, color: AppColors.textMuted.withOpacity(0.4)),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Your Wishlist is Empty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Save items you love here to buy them later.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms)
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.65,
              ),
              itemCount: _wishlistItems.length,
              itemBuilder: (context, index) {
                final product = _wishlistItems[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.soft,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                color: AppColors.background,
                                child: product.imageUrl != null
                                    ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                                    : const Icon(Icons.shopping_basket_rounded, size: 40, color: AppColors.textMuted),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.category.toUpperCase(),
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    '${product.unit} | ${product.shopName ?? "Local Shop"}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '₹${product.price}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                                      ),
                                      GestureDetector(
                                        onTap: () => _addToCart(product),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                          child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 16),
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removeFromWishlist(product.id),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                              child: const Icon(Icons.favorite_rounded, color: AppColors.error, size: 16),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 100).ms).scale(begin: const Offset(0.95, 0.95));
              },
            ),
    );
  }
}
