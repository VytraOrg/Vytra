import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../widgets/global_product_card.dart';
import '../../domain/shop_repository.dart';
import '../../data/product_model.dart';
import '../../../cart/presentation/screens/cart_page.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';

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
  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = context.read<ShopRepository>().getProducts(widget.shopId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.shopName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.store_mall_directory_rounded, size: 80, color: Colors.white.withOpacity(0.1)),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      height: 50,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), boxShadow: AppShadows.soft),
                      child: const TextField(
                        decoration: InputDecoration(hintText: "Search in shop...", prefixIcon: Icon(Icons.search, size: 20), border: InputBorder.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),

          FutureBuilder<List<ProductModel>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())));
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(child: Center(child: Text("Error: ${snapshot.error}")));
              }

              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Text("No products found in this shop")));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => GlobalProductCard(product: products[index], index: index, customerId: widget.customerId),
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}

