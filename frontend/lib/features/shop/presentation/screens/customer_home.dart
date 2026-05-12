import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../../../widgets/common/app_network_image.dart';
import '../../domain/shop_repository.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/data/user_model.dart';
import '../../../account/presentation/screens/account_page.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../cart/presentation/screens/cart_page.dart';
import '../../../orders/presentation/screens/orders_page.dart';
import 'product_list.dart';

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

  late Future<List<Map<String, dynamic>>> _shopsFuture;
  Future<List<Map<String, dynamic>>>? _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Maps category tab names to product search keywords (matched to actual DB product names)
  static const Map<String, String> _categorySearchMap = {
    'Staples': 'rice dal salt atta',
    'Dairy': 'milk butter curd cheese',
    'Veggies': 'apple banana veggie fresh',
    'Snacks': 'lays kurkure chips biscuit',
    'Household': 'sanitizer soap detergent',
  };

  void _loadShops() {
    final user = context.read<AuthController>().currentUser;
    final isShopkeeper = user?.role == 'Shopkeeper';
    final shopType = isShopkeeper ? 'Distributor' : 'Retailer';

    // Effective search = user typed query
    final effectiveQuery = _searchQuery.trim();

    // 1. Fetch filtered shops if searching, or all shops if not
    _shopsFuture = context.read<ShopRepository>().getShops(
      shopType: shopType,
      search: effectiveQuery.isNotEmpty ? effectiveQuery : null,
      category: selectedCategory != 'All' ? selectedCategory : null,
    );

    // 2. Fetch products if there's a search query OR a category selected
    final productQuery = effectiveQuery.isNotEmpty 
        ? effectiveQuery 
        : (selectedCategory != 'All' ? (_categorySearchMap[selectedCategory] ?? selectedCategory) : '');

    if (productQuery.isNotEmpty) {
      _productsFuture = context.read<ShopRepository>().searchGlobalProducts(
        query: productQuery,
      );
    } else {
      _productsFuture = null;
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
        _loadShops();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final isShopkeeper = user?.role == 'Shopkeeper';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/bg_image.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // GLASSMORPHISM BLUR LAYER
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
            // 1. DYNAMIC HEADER
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: _buildHeader(user?.name ?? "Guest", isShopkeeper),
              ),
            ),

            // 2. SEARCH BAR
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: _buildSearchBar(),
              ),
            ),

            // 3. PROMO BANNERS (Carousel)
            SliverToBoxAdapter(
              child: _buildPromoCarousel(),
            ),

            // 4. CATEGORIES (Horizontal Bubbles)
            SliverToBoxAdapter(
              child: _buildCategoryList(),
            ),

            // 5. SEARCH RESULTS OR SHOP SECTION HEADER
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _searchQuery.isNotEmpty 
                        ? "Items matching \"$_searchQuery\"" 
                        : (isShopkeeper ? "Top Distributors" : "Nearby Stores"),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                    if (_searchQuery.isEmpty)
                      TextButton(
                        onPressed: () {},
                        child: const Text("See All", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),

            // 6. DYNAMIC LIST (Vertical Cards)
            FutureBuilder(
              future: Future.wait([
                _shopsFuture,
                _productsFuture ?? Future.value(<Map<String, dynamic>>[]),
              ]),
              builder: (context, AsyncSnapshot<List<List<Map<String, dynamic>>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                  );
                }
                
                final shops = snapshot.data?[0] ?? [];
                final products = snapshot.data?[1] ?? [];
                
                if (shops.isEmpty && products.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text("No results found for \"$_searchQuery\"", style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  );
                }

                // Merge results: Shops first, then Products
                final List<Map<String, dynamic>> combined = [];
                for (var s in shops) combined.add({...s, 'isShop': true});
                for (var p in products) combined.add({...p, 'isShop': false});

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = combined[index];
                        if (item['isShop'] == true) {
                          return _buildShopCard(item, index);
                        } else {
                          return _buildGlobalProductCard(item, index);
                        }
                      },
                      childCount: combined.length,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    ],
  ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartPage()),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning,";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon,";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening,";
    } else {
      return "Good Night,";
    }
  }

  Widget _buildHeader(String name, bool isShopkeeper) {
    final user = context.read<AuthController>().currentUser;
    final nameParts = name.trim().split(' ');
    final initials = name.isEmpty ? 'C'
        : nameParts.length >= 2
            ? (nameParts[0][0] + nameParts[1][0]).toUpperCase()
            : name[0].toUpperCase();
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isShopkeeper ? "B2B Sourcing" : _getGreeting(),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountPage(customerId: widget.customerId, user: user))),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: "Search for eggs, milk, bread...",
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            height: 35,
            width: 35,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildPromoCarousel() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: PageView(
        children: [
          _buildPromoCard(
            "Get 50% OFF",
            "On your first fresh veggie order",
            AppColors.freshGreen,
            "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=800",
          ),
          _buildPromoCard(
            "Free Delivery",
            "On orders above ₹500 today!",
            AppColors.skyBlue,
            "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&q=80&w=800",
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildPromoCard(String title, String sub, Color color, String img) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        color: color,
      ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text("LIMITED OFFER", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
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
      height: 110,
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
                _loadShops();
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: 300.ms,
                    height: 65,
                    width: 65,
                    decoration: BoxDecoration(
                      color: isSelected ? cat['color'] : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? AppShadows.premium : AppShadows.soft,
                      border: isSelected ? null : Border.all(color: Colors.grey.shade100, width: 2),
                    ),
                    child: Icon(cat['icon'], color: isSelected ? Colors.white : cat['color'], size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['name'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildShopCard(Map<String, dynamic> shop, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductList(
            shopName: shop['name'],
            shopId: shop['_id'] ?? shop['id'] ?? '',
            customerId: widget.customerId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.soft),
        child: Column(
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  imageUrl: shop['imageUrl'] ?? "",
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
                        Text("${shop['rating'] ?? 4.5}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                        Text(shop['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            const Text("1.2 km away", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            const Text("25 mins", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
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

  Widget _buildGlobalProductCard(Map<String, dynamic> item, int index) {
    final shop = item['shopInfo'] as Map<String, dynamic>;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductList(
            shopName: shop['name'],
            shopId: shop['_id'] ?? shop['id'] ?? '',
            customerId: widget.customerId,
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
          // PRODUCT IMAGE
          AppNetworkImage(
            imageUrl: (item['images'] != null && (item['images'] as List).isNotEmpty) ? item['images'][0] : "",
            height: 90,
            width: 90,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          const SizedBox(width: AppSpacing.md),
          
          // PRODUCT & SHOP INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      shop['name'],
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.freshGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.freshGreen, size: 12),
                          const SizedBox(width: 2),
                          Text("${shop['rating'] ?? 4.0}", style: const TextStyle(color: AppColors.freshGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${item['price']} / ${item['unit']}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.freshGreen),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final cartController = context.read<CartController>();
                        await cartController.addToCart(item['_id'] ?? item['id'], quantity: 1);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item['name']} added to cart'),
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

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, Icons.home_rounded, "Home"),
            _buildNavItem(1, Icons.assignment_outlined, "Orders"),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(2, Icons.favorite_border_rounded, "Saved"),
            _buildNavItem(3, Icons.person_outline_rounded, "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final user = context.read<AuthController>().currentUser;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrdersPage(),
            ),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AccountPage(
                customerId: widget.customerId,
                user: user,
              ),
            ),
          );
        } else {
          setState(() => _currentIndex = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted),
          Text(label, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textMuted, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}