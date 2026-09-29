import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/services/location_service.dart';
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
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../orders/presentation/screens/orders_page.dart';
import '../../../../shared/widgets/floating_pill_nav_bar.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _recentSearches = [];
  double? _userLat;
  double? _userLng;
  
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
    _loadRecentSearches();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
    _initLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _initLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (mounted && loc != null) {
      setState(() {
        _userLat = loc.latitude;
        _userLng = loc.longitude;
      });
      _loadData();
    }
  }

  void _loadRecentSearches() {
    setState(() {
      _recentSearches = CacheManager.getRecentSearches();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static const Map<String, String> _categorySearchMap = {
    'Staples': 'rice dal salt atta',
    'Dairy': 'milk butter curd cheese',
    'Veggies': 'apple banana veggie fresh',
    'Snacks': 'lays kurkure chips biscuit',
    'Household': 'sanitizer soap detergent',
  };

  Future<void> _loadData({bool forceRefresh = false}) async {
    final user = context.read<AuthController>().currentUser;
    final isShopkeeper = user?.role == 'Shopkeeper';
    final shopType = isShopkeeper ? 'Distributor' : 'Retailer';
    final effectiveQuery = _searchQuery.trim();

    final shopController = context.read<ShopController>();
    
    // 1. Fetch shops
    final shopsFuture = shopController.fetchShops(
      shopType: shopType,
      search: effectiveQuery.isNotEmpty ? effectiveQuery : null,
      category: selectedCategory != 'All' ? selectedCategory : null,
      lat: _userLat,
      lng: _userLng,
      forceRefresh: forceRefresh,
    );

    // 2. Fetch products for global search/category
    final productQuery = effectiveQuery.isNotEmpty 
        ? effectiveQuery 
        : (selectedCategory != 'All' ? (_categorySearchMap[selectedCategory] ?? selectedCategory) : '');

    final productsFuture = shopController.searchGlobal(
      productQuery,
      shopType: isShopkeeper ? 'Distributor' : 'Retailer',
      lat: _userLat,
      lng: _userLng,
      forceRefresh: forceRefresh,
    );

    if (effectiveQuery.isNotEmpty) {
      shopController.fetchSuggestions(effectiveQuery, shopType: isShopkeeper ? 'Distributor' : 'Retailer');
    } else {
      shopController.clearSuggestions();
    }

    await Future.wait([shopsFuture, productsFuture]);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _searchQuery = query;
        _loadData();
      });
    });
  }

  void _selectSearchTerm(String term) {
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(TextPosition(offset: term.length));
    _searchFocusNode.unfocus();
    CacheManager.addRecentSearch(term).then((_) => _loadRecentSearches());
    setState(() {
      _searchQuery = term;
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final shopController = context.watch<ShopController>();
    final cartController = context.watch<CartController>();
    final isShopkeeper = user?.role == 'Shopkeeper';

    final cartCount = cartController.cart?.items.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;

    final pages = [
      _buildHomeView(user, isShopkeeper, shopController),
      const OrdersPage(isTab: true),
      const WishlistPage(isTab: true),
      AccountPage(customerId: widget.customerId, user: user, isTab: true),
      const CartPage(isTab: true),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          // Smooth progressive backdrop blur & fade gradient layer behind floating nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 140,
            child: IgnorePointer(
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradual blur without hard edges
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.7),
                            Colors.black,
                          ],
                          stops: const [0.0, 0.28, 0.65, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // Gradual color fade into screen background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.background.withValues(alpha: 0.0),
                            AppColors.background.withValues(alpha: 0.25),
                            AppColors.background.withValues(alpha: 0.7),
                            AppColors.background.withValues(alpha: 0.95),
                          ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Pill Nav Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: FloatingPillNavBar(
                currentIndex: _currentIndex,
                cartCount: cartCount,
                onTabSelected: (index) {
                  setState(() => _currentIndex = index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeView(UserEntity? user, bool isShopkeeper, ShopController shopController) {
    return Stack(
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
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => _loadData(forceRefresh: true),
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverToBoxAdapter(
                    child: _buildHeader(user, isShopkeeper),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverToBoxAdapter(child: _buildSearchBar(shopController)),
                ),

                if (_searchQuery.isEmpty && _recentSearches.isNotEmpty)
                  SliverToBoxAdapter(child: _buildRecentSearchesSection()),

                if (_searchQuery.isNotEmpty && shopController.isAutoCorrected)
                  SliverToBoxAdapter(child: _buildSpellCorrectionBanner(shopController)),

                if (_searchQuery.isNotEmpty && shopController.suggestions.isNotEmpty)
                  SliverToBoxAdapter(child: _buildSuggestionsChips(shopController)),

                if (_searchQuery.isEmpty) ...[
                  SliverToBoxAdapter(child: _buildPromoCarousel()),
                  SliverToBoxAdapter(child: _buildCategoryList()),
                ],

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _searchQuery.isNotEmpty 
                            ? "Results for \"$_searchQuery\"" 
                            : (isShopkeeper ? "Top Distributors" : "Nearby Stores"),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Text(
                            "${shopController.shops.length + shopController.searchResults.length} found",
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ),

                if (shopController.isLoading && shopController.shops.isEmpty && shopController.searchResults.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (shopController.shops.isEmpty && shopController.searchResults.isEmpty)
                  _buildEmptyState(shopController)
                else
                  _buildResultsList(shopController),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearchesSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    "Recent Searches",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  await CacheManager.clearRecentSearches();
                  if (mounted) {
                    setState(() {
                      _recentSearches = [];
                    });
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "Clear All",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _recentSearches.map((term) {
              return InputChip(
                label: Text(term, style: const TextStyle(fontSize: 13)),
                backgroundColor: AppColors.background,
                onPressed: () => _selectSearchTerm(term),
                onDeleted: () async {
                  await CacheManager.removeRecentSearch(term);
                  if (mounted) {
                    _loadRecentSearches();
                  }
                },
                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05);
  }

  Widget _buildSuggestionsChips(ShopController controller) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = controller.suggestions[index];
          return ActionChip(
            avatar: const Icon(Icons.search_rounded, size: 14, color: AppColors.primary),
            label: Text(suggestion, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            backgroundColor: AppColors.primary.withOpacity(0.08),
            side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            onPressed: () => _selectSearchTerm(suggestion),
          );
        },
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildSpellCorrectionBanner(ShopController controller) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.organicAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.organicAmber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_fix_high_rounded, size: 16, color: AppColors.organicAmber),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                children: [
                  const TextSpan(text: "Showing results for "),
                  TextSpan(
                    text: controller.correctedQuery,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const TextSpan(text: " (auto-corrected from \""),
                  TextSpan(text: _searchQuery, style: const TextStyle(fontStyle: FontStyle.italic)),
                  const TextSpan(text: "\")"),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildEmptyState(ShopController controller) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              child: Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty
                  ? "No results for \"$_searchQuery\""
                  : "No items or shops available",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            if (controller.didYouMean != null && controller.didYouMean!.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _selectSearchTerm(controller.didYouMean!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.spellcheck_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        "Did you mean: ${controller.didYouMean}?",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? "Check spelling or explore popular categories below"
                  : "Try changing your category or check back later",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: categories.where((c) => c['name'] != 'All').map((c) {
                return ActionChip(
                  avatar: Icon(c['icon'] as IconData, size: 14, color: AppColors.primary),
                  label: Text(c['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  backgroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  onPressed: () {
                    setState(() {
                      selectedCategory = c['name'] as String;
                      _searchController.clear();
                      _searchQuery = '';
                    });
                    _loadData();
                  },
                );
              }).toList(),
            ),
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
          onTap: () => setState(() => _currentIndex = 3),
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

  Widget _buildSearchBar(ShopController controller) {
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
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (term) {
                _searchFocusNode.unfocus();
                final t = term.trim();
                if (t.isNotEmpty) {
                  if (t.length >= 2) {
                    CacheManager.addRecentSearch(t).then((_) => _loadRecentSearches());
                  }
                  _onSearchChanged(t);
                }
              },
              decoration: const InputDecoration(
                hintText: "Search items, brands, or stores...",
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller.isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          else if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary),
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
}