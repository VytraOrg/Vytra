import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/design_system.dart';
import '../../../cart/presentation/screens/cart_page.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../../api_config.dart';

class ProductList extends StatefulWidget {
  final String shopName;
  final String shopId;
  final String customerId;

  const ProductList({
    super.key,
    required this.shopName,
    required this.shopId,
    required this.customerId,
  });

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  late Future<List<ProductItem>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<ProductItem>> _fetchProducts() async {
    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.get('/products?shopId=${widget.shopId}');
      
      final List<dynamic> list = (response is Map && response.containsKey('items')) 
          ? response['items'] 
          : (response is List ? response : []);
          
      return list
          .map((item) => ProductItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Future<void> _addToCart(ProductItem product) async {
    try {
      final cartController = context.read<CartController>();
      await cartController.addToCart(product.id, quantity: 1);

      if (!mounted) return;

      if (cartController.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${cartController.error}'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 1. DYNAMIC HERO HEADER
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.shopName,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: Hero(
                tag: "shop_image_${widget.shopName}",
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.store_mall_directory_rounded,
                      size: 100,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartPage()),
                ),
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
          ),

          // 2. SEARCH & FILTER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: AppShadows.soft,
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Search in shop...",
                          prefixIcon: Icon(Icons.search, size: 20),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),

          // 3. PRODUCT GRID
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: FutureBuilder<List<ProductItem>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildSkeletonCard(),
                      childCount: 4,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text("Error: ${snapshot.error}")),
                  );
                }

                final products = snapshot.data ?? [];
                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.lg,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildProductCard(context, products[index]),
                    childCount: products.length,
                  ),
                );
              },
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductItem product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.fastfood_rounded, size: 48, color: AppColors.primary),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      radius: 16,
                      child: const Icon(Icons.favorite_border_rounded, size: 18, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product.unit,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${product.price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _addToCart(product),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 80, color: Colors.grey.shade100),
                const SizedBox(height: 8),
                Container(height: 10, width: 40, color: Colors.grey.shade100),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(height: 16, width: 40, color: Colors.grey.shade100),
                    Container(height: 24, width: 24, decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.5));
  }
}

class ProductItem {
  final String id;
  final String name;
  final String description;
  final String unit;
  final double price;

  ProductItem({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.price,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Unnamed Product').toString(),
      description: (json['description'] ?? 'No description').toString(),
      unit: (json['unit'] ?? '1 pc').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}