import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../controllers/shop_controller.dart';
import '../widgets/shop_card.dart';
import '../widgets/global_product_card.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../account/presentation/screens/account_page.dart';
import '../../../account/presentation/screens/wishlist_page.dart';
import '../../../cart/presentation/screens/cart_page.dart';
import '../../../orders/presentation/screens/orders_page.dart';
import '../../data/shop_model.dart';
import '../../data/product_model.dart';

class CustomerHome extends StatefulWidget {
  final String customerId;

  const CustomerHome({super.key, required this.customerId});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _currentIndex = 0;
  String selectedCategory = "All";
  String _searchQuery = "";
  Timer? _debounce;
  
  final List<Map<String, dynamic>> categories = [
    {"name": "All", "icon": Icons.grid_view_rounded, "color": AppColors.skyBlue},
    {"name": "Staples", "icon": Icons.agriculture_rounded, "color": AppColors.organicAmber},
    {"name": "Dairy", "icon": Icons.water_drop_rounded, "color": AppColors.skyBlue},
    {"name": "Veggies", "icon": Icons.eco_rounded, "color": AppColors.freshGreen},
    {"name": "Snacks", "icon": Icons.cookie_rounded, "color": AppColors.citrusOrange},
    {"name": "Household", "icon": Icons.cleaning_services_rounded, "color": AppColors.textSecondary},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  static const Map<String, String> _categorySearchMap = {
    'Staples': 'rice dal salt atta',
    'Dairy': 'milk butter curd cheese',
    'Veggies': 'apple banana veggie fresh',
    'Snacks': 'lays kurkure chips biscuit',
    'Household': 'sanitizer soap detergent',
  };

  void _loadData() {
    final user = context.read<AuthController>().currentUser;
    final isShopkeeper = user?.role == 'Shopkeeper';
    final shopType = isShopkeeper ? 'Distributor' : 'Retailer';
    final effectiveQuery = _searchQuery.trim();

    final shopController = context.read<ShopController>();
    
    // 1. Fetch shops
    shopController.fetchShops(
      shopType: shopType,
      search: effectiveQuery.isNotEmpty ? effectiveQuery : null,
      category: selectedCategory != 'All' ? selectedCategory : null,
    );

    // 2. Fetch products for global search/category
    final productQuery = effectiveQuery.isNotEmpty 
        ? effectiveQuery 
        : (selectedCategory != 'All' ? (_categorySearchMap[selectedCategory] ?? selectedCategory) : '');

    shopController.searchGlobal(productQuery, shopType: isShopkeeper ? 'Distributor' : 'Retailer');
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = query;
        _loadData();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final shopController = context.watch<ShopController>();
    final isShopkeeper = user?.role == 'Shopkeeper';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: Image.asset('assets/bg_image.jpg', fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(color: Colors.black.withOpacity(0.02)),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverToBoxAdapter(
                    child: _buildHeader(user, isShopkeeper),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverToBoxAdapter(child: _buildSearchBar()),
                ),

                SliverToBoxAdapter(child: _buildPromoCarousel()),

                SliverToBoxAdapter(child: _buildCategoryList()),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      _searchQuery.isNotEmpty 
                        ? "Items matching \"$_searchQuery\"" 
                        : (isShopkeeper ? "Top Distributors" : "Nearby Stores"),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ),
                ),

                if (shopController.isLoading && shopController.shops.isEmpty)
                  const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                else if (shopController.shops.isEmpty && shopController.searchResults.isEmpty)
                  _buildEmptyState()
                else
                  _buildResultsList(shopController),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("No results found", style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(ShopController controller) {
    final items = [
      ...controller.shops.map((s) => {'type': 'shop', 'data': s}),
      ...controller.searchResults.map((p) => {'type': 'product', 'data': p}),
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            if (item['type'] == 'shop') {
              return ShopCard(shop: item['data'] as ShopModel, index: index, customerId: widget.customerId);
            } else {
              return GlobalProductCard(product: item['data'] as ProductModel, index: index, customerId: widget.customerId);
            }
          },
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildHeader(UserEntity? user, bool isShopkeeper) {
    final name = user?.name ?? "Guest";
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : (name.isNotEmpty ? name[0].toUpperCase() : 'C');
    
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isShopkeeper ? "B2B Sourcing" : "Welcome,", style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountPage(customerId: widget.customerId, user: user))),
          child: _buildHomeAvatar(user, initials),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildHomeAvatar(UserEntity? user, String initials) {
    final imageUrl = user?.imageUrl ?? '';
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:image') || !imageUrl.startsWith('http')) {
        try {
          final bytes = base64Decode(imageUrl.split(',').last);
          return CircleAvatar(
            radius: 24,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (e) {
          // Fallback
        }
      } else {
        return CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(imageUrl),
        );
      }
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary,
      child: Text(
        initials,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      height: 55,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(hintText: "Search items or stores...", border: InputBorder.none),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildPromoCarousel() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: PageView(
        children: [
          _buildPromoCard("Get 50% OFF", "First veggie order", AppColors.freshGreen, "https://images.unsplash.com/photo-1542838132-92c53300491e?w=800"),
          _buildPromoCard("Free Delivery", "Orders above ₹500", AppColors.skyBlue, "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800"),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildPromoCard(String title, String sub, Color color, String img) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.xl), color: color),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: Image.network(img, fit: BoxFit.cover, color: Colors.black.withOpacity(0.3), colorBlendMode: BlendMode.darken)),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat['name'];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = cat['name'];
                _loadData();
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isSelected ? cat['color'] : Colors.white,
                    child: Icon(cat['icon'], color: isSelected ? Colors.white : cat['color']),
                  ),
                  const SizedBox(height: 4),
                  Text(cat['name'], style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, "Home"),
            _buildNavItem(1, Icons.assignment_outlined, "Orders"),
            const SizedBox(width: 40),
            _buildNavItem(2, Icons.favorite_border_rounded, "Saved"),
            _buildNavItem(3, Icons.person_outline_rounded, "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersPage()));
        else if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage()));
        else if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => AccountPage(customerId: widget.customerId, user: context.read<AuthController>().currentUser)));
        else setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted),
          Text(label, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
 }
}