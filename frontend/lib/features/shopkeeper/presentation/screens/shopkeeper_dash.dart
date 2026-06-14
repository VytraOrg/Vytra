import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/presentation/screens/welcome_screen.dart';
import '../../../distributor/presentation/screens/distributor_list.dart';
import '../../../auth/presentation/screens/verification_page.dart';
import '../../../shop/data/shop_model.dart';
import '../../../shop/data/product_model.dart';
import '../../../orders/domain/order_model.dart';
import 'inventory_page.dart';
import 'analytics_page.dart';

class ShopkeeperDash extends StatefulWidget {
  const ShopkeeperDash({super.key});

  @override
  State<ShopkeeperDash> createState() => _ShopkeeperDashState();
}

class _ShopkeeperDashState extends State<ShopkeeperDash> {
  int _currentIndex = 0;
  bool _isShopOpen = true;
  ShopModel? _myShop;
  bool _isLoadingShop = true;

  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  bool _isLoadingOrders = true;

  double _revenue = 0.0;
  int _totalOrdersCount = 0;
  int _pendingOrdersCount = 0;
  int _lowStockCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingShop = true;
      _isLoadingOrders = true;
    });

    try {
      final apiClient = context.read<ApiClient>();
      
      // 1. Fetch current shop details
      final shopResponse = await apiClient.get('/shops/my');
      final myShop = ShopModel.fromJson(Map<String, dynamic>.from(shopResponse));
      
      setState(() {
        _myShop = myShop;
        _isShopOpen = myShop.status == 'Open';
        _isLoadingShop = false;
      });

      // 2. Fetch products and orders for this shop
      final productsFuture = apiClient.get('/products?shopId=${myShop.id}&limit=100');
      final ordersFuture = apiClient.get('/orders/my-shop');

      final results = await Future.wait([productsFuture, ordersFuture]);

      // Parse products
      final productsResponse = results[0];
      final List<dynamic> productItems = productsResponse is Map
          ? (productsResponse['items'] as List? ?? [])
          : (productsResponse as List? ?? []);
      final products = productItems.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();

      // Parse orders
      final ordersResponse = results[1];
      final List<dynamic> orderItems = ordersResponse is List
          ? ordersResponse
          : (ordersResponse is Map ? (ordersResponse['items'] as List? ?? []) : []);
      final orders = orderItems.map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e))).toList();

      setState(() {
        _products = products;
        _orders = orders;

        // Calculate Stats
        _revenue = orders
            .where((o) => o.status == 'Delivered')
            .fold(0.0, (sum, o) => sum + o.totalAmount);

        _totalOrdersCount = orders.length;

        _pendingOrdersCount = orders
            .where((o) => o.status == 'Placed' || o.status == 'Processing' || o.status == 'Dispatched')
            .length;

        _lowStockCount = products.where((p) => p.stockQuantity < 10).length;

        _isLoadingOrders = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() {
        _isLoadingShop = false;
        _isLoadingOrders = false;
      });
    }
  }

  Future<void> _toggleShopStatus() async {
    if (_myShop == null) return;

    final newStatus = !_isShopOpen ? 'Open' : 'Closed';
    setState(() {
      _isShopOpen = !_isShopOpen;
    });

    try {
      final apiClient = context.read<ApiClient>();
      await apiClient.put('/shops/my/status', {'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shop is now ${newStatus.toUpperCase()} to customers'),
          duration: const Duration(seconds: 2),
          backgroundColor: newStatus == 'Open' ? AppColors.freshGreen : AppColors.error,
        ),
      );
      _loadDashboardData(); // Reload to sync state
    } catch (e) {
      debugPrint('Error toggling shop status: $e');
      setState(() {
        _isShopOpen = !_isShopOpen; // Revert
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update shop status: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _updateOrderStatus(String orderId, String nextStatus) async {
    try {
      final apiClient = context.read<ApiClient>();
      await apiClient.put('/orders/$orderId/status', {'status': nextStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $nextStatus'),
          backgroundColor: AppColors.freshGreen,
        ),
      );
      _loadDashboardData(); // Refresh order details
    } catch (e) {
      debugPrint('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Color _getVerificationColor(String? status) {
    switch (status) {
      case 'Verified':
        return AppColors.freshGreen;
      case 'Pending':
        return AppColors.warning;
      case 'Rejected':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String _getFormattedTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  IconData _getOrderStatusIcon(String status) {
    switch (status) {
      case 'Placed':
        return Icons.shopping_bag_outlined;
      case 'Processing':
        return Icons.sync_rounded;
      case 'Dispatched':
        return Icons.local_shipping_outlined;
      case 'Delivered':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline;
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'Placed':
        return AppColors.citrusOrange;
      case 'Processing':
        return AppColors.accent;
      case 'Dispatched':
        return AppColors.skyBlue;
      case 'Delivered':
        return AppColors.freshGreen;
      default:
        return AppColors.error;
    }
  }

  List<Map<String, dynamic>> _getNotifications() {
    final List<Map<String, dynamic>> list = [];
    
    // Add pending orders
    final pending = _orders.where((o) => o.status == 'Placed').toList();
    for (final order in pending) {
      list.add({
        'title': 'New order received (ID: ${order.id.substring(order.id.length - 6).toUpperCase()})',
        'time': _getFormattedTimeAgo(order.createdAt),
        'unread': true,
      });
    }
    
    // Add low stock alerts
    final lowStock = _products.where((p) => p.stockQuantity < 10).toList();
    for (final p in lowStock) {
      list.add({
        'title': 'Low stock warning: ${p.name} (${p.stockQuantity} remaining)',
        'time': 'Check stock',
        'unread': false,
      });
    }

    if (_myShop?.verificationStatus == 'Pending') {
      list.add({
        'title': 'Shop verification is currently under review',
        'time': 'Reviewing',
        'unread': true,
      });
    } else if (_myShop?.verificationStatus == 'Rejected') {
      list.add({
        'title': 'Shop verification was rejected. Please re-upload documents.',
        'time': 'Action needed',
        'unread': true,
      });
    }

    if (list.isEmpty) {
      list.add({
        'title': 'No new notifications',
        'time': 'Now',
        'unread': false,
      });
    }
    
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    // Dynamic Navigation Page mapping
    final List<Widget> pages = [
      _buildDashboardTab(context, authController),
      _buildOrdersTab(),
      InventoryPage(shopId: _myShop?.id),
      AnalyticsPage(orders: _orders, products: _products),
      _buildProfileTab(context, authController),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoadingShop && _myShop == null
          ? const Center(child: CircularProgressIndicator())
          : pages[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- TAB 0: DASHBOARD CONTENT ---
  Widget _buildDashboardTab(BuildContext context, AuthController authController) {
    final user = authController.currentUser;
    final businessName = _myShop?.name ?? user?.businessName ?? 'Your Store';

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Hero Header Section
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                bottom: AppSpacing.xl,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.xxl),
                  bottomRight: Radius.circular(AppRadius.xxl),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -30,
                    top: -20,
                    child: Opacity(
                      opacity: 0.08,
                      child: const Icon(Icons.storefront_rounded, size: 220, color: Colors.white),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDashboardHeader(context, businessName),
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: _buildWelcomeGreeting(user?.name ?? 'Merchant'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Scrollable Dashboard Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 3. Analytics Cards Grid
                _buildAnalyticsGrid(),
                const SizedBox(height: AppSpacing.lg),

                // 4. Quick Actions
                _buildSectionHeader("Quick Actions"),
                const SizedBox(height: AppSpacing.sm),
                _buildQuickActionsRow(context),
                const SizedBox(height: AppSpacing.xl),

                // 5. Sales Analytics Weekly Chart
                _buildSectionHeader("Sales Analytics"),
                const SizedBox(height: AppSpacing.sm),
                _buildWeeklySalesChart(),
                const SizedBox(height: AppSpacing.xl),

                // 6. Order Overview Progress Tracker
                _buildSectionHeader("Order Status Overview"),
                const SizedBox(height: AppSpacing.sm),
                _buildOrderOverviewTracker(),
                const SizedBox(height: AppSpacing.xl),

                // 7. Management Tools Grid
                _buildSectionHeader("Store Management"),
                const SizedBox(height: AppSpacing.sm),
                _buildManagementToolsGrid(context),
                const SizedBox(height: AppSpacing.xl),

                // 8. Smart Alerts Banner Section
                _buildSectionHeader("Smart Alerts & Insights"),
                const SizedBox(height: AppSpacing.sm),
                _buildSmartAlertsSection(context),
                const SizedBox(height: AppSpacing.xl),

                // 9. Recent Activity Timeline
                _buildSectionHeader("Recent Activity"),
                const SizedBox(height: AppSpacing.sm),
                _buildRecentActivityTimeline(),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- DASHBOARD SUB-WIDGETS ---
  Widget _buildDashboardHeader(BuildContext context, String businessName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                businessName,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              // Notification Icon with Badge
              GestureDetector(
                onTap: () => _showNotificationsBottomSheet(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.citrusOrange,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _getNotifications().where((n) => n['unread'] == true).length.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Circle Avatar for Shop Logo
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.accent,
                child: Text(
                  businessName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeGreeting(String merchantName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome back 👋", 
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              merchantName,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ],
        ),
        // Toggleable Shop Status Indicator Pill
        GestureDetector(
          onTap: _toggleShopStatus,
          child: AnimatedContainer(
            duration: 300.ms,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _isShopOpen ? AppColors.freshGreen : AppColors.error,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: (_isShopOpen ? AppColors.freshGreen : AppColors.error).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  _isShopOpen ? "OPEN" : "CLOSED",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ],
            ),
          ),
        ).animate().scale(delay: 200.ms, duration: 300.ms, curve: Curves.easeOutBack),
      ],
    );
  }

  Widget _buildAnalyticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: [
        _buildStatCard(
          "Revenue",
          "₹${_revenue.toStringAsFixed(0)}",
          "Total sales",
          Icons.payments_outlined,
          AppColors.freshGreen,
          true,
        ),
        _buildStatCard(
          "Total Orders",
          "$_totalOrdersCount Orders",
          "All-time",
          Icons.inventory_2_outlined,
          AppColors.primary,
          true,
        ),
        _buildStatCard(
          "Pending Orders",
          "$_pendingOrdersCount",
          "Action needed",
          Icons.pending_actions_rounded,
          AppColors.citrusOrange,
          false,
        ),
        _buildStatCard(
          "Low Stock",
          "$_lowStockCount Items",
          "Reorder soon",
          Icons.warning_amber_rounded,
          AppColors.error,
          false,
          isAlert: _lowStockCount > 0,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String trendText, IconData icon, Color accentColor, bool isPositiveTrend, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
        border: Border.all(color: isAlert ? AppColors.error.withOpacity(0.2) : Colors.transparent, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              // Trend badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isAlert 
                      ? AppColors.error.withOpacity(0.1) 
                      : (isPositiveTrend ? AppColors.freshGreen.withOpacity(0.1) : AppColors.textMuted.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trendText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isAlert 
                        ? AppColors.error 
                        : (isPositiveTrend ? AppColors.freshGreen : AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.primaryLight.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQuickActionBtn("Add Product", Icons.add_circle_outline_rounded, () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => InventoryPage(shopId: _myShop?.id)));
            _loadDashboardData();
          }),
          _buildQuickActionBtn("New Order", Icons.post_add_rounded, () {
            setState(() {
              _currentIndex = 1; // Switch to Orders Tab
            });
          }),
          _buildQuickActionBtn("Manage Stock", Icons.grid_view_rounded, () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => InventoryPage(shopId: _myShop?.id)));
            _loadDashboardData();
          }),
          _buildQuickActionBtn("Create Offer", Icons.local_offer_outlined, () {
            _showCreateOfferBottomSheet(context);
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppShadows.soft,
              border: Border.all(color: AppColors.primaryLight.withOpacity(0.6), width: 1.2),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySalesChart() {
    final today = DateTime.now();
    final List<double> weeklyData = List.filled(7, 0.0);
    final List<String> days = [];
    final List<String> daysShort = ["M", "T", "W", "T", "F", "S", "S"];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      days.add(daysShort[day.weekday - 1]);

      final dailyTotal = _orders
          .where((o) =>
              o.status == 'Delivered' &&
              o.createdAt.year == day.year &&
              o.createdAt.month == day.month &&
              o.createdAt.day == day.day)
          .fold(0.0, (sum, o) => sum + o.totalAmount);
      weeklyData[6 - i] = dailyTotal;
    }

    final maxDailyTotal = weeklyData.reduce((a, b) => a > b ? a : b);
    final totalWeeklySales = weeklyData.fold(0.0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Weekly Revenue", style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("₹${totalWeeklySales.toStringAsFixed(0)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.freshGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, color: AppColors.freshGreen, size: 12),
                    const SizedBox(width: 4),
                    Text("Live Data", style: TextStyle(color: AppColors.freshGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Chart bar row
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final heightFactor = maxDailyTotal > 0 ? (weeklyData[index] / maxDailyTotal) : 0.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 14,
                      height: 80 * (heightFactor > 0 ? heightFactor : 0.05), // Show a tiny indicator even if 0
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.primary],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[index],
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Recent sales total ₹${totalWeeklySales.toStringAsFixed(0)} over the last 7 days across all delivered orders.",
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.9), fontSize: 11, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderOverviewTracker() {
    final placedCount = _orders.where((o) => o.status == 'Placed').length.toString();
    final processingCount = _orders.where((o) => o.status == 'Processing').length.toString();
    final dispatchedCount = _orders.where((o) => o.status == 'Dispatched').length.toString();
    final deliveredCount = _orders.where((o) => o.status == 'Delivered').length.toString();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrackerNode("Placed", placedCount, Icons.pending_actions_rounded, AppColors.citrusOrange),
              _buildTrackerLine(AppColors.citrusOrange),
              _buildTrackerNode("Processing", processingCount, Icons.sync_rounded, AppColors.accent),
              _buildTrackerLine(AppColors.accent),
              _buildTrackerNode("Dispatched", dispatchedCount, Icons.local_shipping_outlined, AppColors.skyBlue),
              _buildTrackerLine(AppColors.skyBlue),
              _buildTrackerNode("Delivered", deliveredCount, Icons.task_alt_rounded, AppColors.freshGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerNode(String label, String count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          count,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTrackerLine(Color color) {
    return Expanded(
      child: Container(
        height: 2,
        color: color.withOpacity(0.3),
        margin: const EdgeInsets.only(bottom: 24),
      ),
    );
  }

  Widget _buildManagementToolsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.15,
      children: [
        _buildMenuCard(
          Icons.inventory_2_rounded,
          "Manage Stock",
          AppColors.primary,
          badgeText: "$_lowStockCount Low",
          badgeColor: _lowStockCount > 0 ? AppColors.error : AppColors.freshGreen,
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => InventoryPage(shopId: _myShop?.id)));
            _loadDashboardData();
          },
        ),
        _buildMenuCard(
          Icons.local_shipping_rounded,
          "Distributors",
          AppColors.secondary,
          badgeText: "New",
          badgeColor: AppColors.freshGreen,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DistributorList())),
        ),
        _buildMenuCard(
          Icons.bar_chart_rounded,
          "Sales Report",
          AppColors.organicAmber,
          badgeText: "Real-time",
          badgeColor: AppColors.accent,
          onTap: () => setState(() => _currentIndex = 3), // Switch to Reports Tab
        ),
        _buildMenuCard(
          Icons.verified_user_rounded,
          "Verification",
          AppColors.skyBlue,
          badgeText: _isLoadingShop 
              ? "Loading..." 
              : (_myShop?.verificationStatus ?? "Unverified"),
          badgeColor: _isLoadingShop 
              ? AppColors.textMuted 
              : _getVerificationColor(_myShop?.verificationStatus),
          onTap: () async {
            final result = await Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => VerificationPage(initialStatus: _myShop?.verificationStatus))
            );
            if (result == true) {
              _loadDashboardData();
            }
          },
        ),
        _buildMenuCard(
          Icons.star_rounded,
          "Customer Reviews",
          AppColors.citrusOrange,
          badgeText: "4.8 ★",
          badgeColor: AppColors.citrusOrange,
          onTap: () => _showReviewsBottomSheet(context),
        ),
        _buildMenuCard(
          Icons.account_balance_wallet_rounded,
          "Payments",
          AppColors.accent,
          badgeText: "₹${_revenue.toStringAsFixed(0)}",
          badgeColor: AppColors.freshGreen,
          onTap: () => _showPaymentsBottomSheet(context),
        ),
      ],
    );
  }

  Widget _buildMenuCard(IconData icon, String label, Color color, {String? badgeText, Color? badgeColor, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.soft,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            if (badgeText != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.primary).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: badgeColor ?? AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartAlertsSection(BuildContext context) {
    final lowStockItems = _products.where((p) => p.stockQuantity < 10).toList();
    final lowStockDesc = lowStockItems.isEmpty
        ? "All items in your inventory are well stocked!"
        : "${lowStockItems.take(3).map((p) => p.name).join(', ')}${lowStockItems.length > 3 ? ' and others' : ''} are running critically low in stock.";

    return Column(
      children: [
        _buildAlertCard(
          lowStockItems.isEmpty ? "Inventory Healthy" : "Low Stock Warning",
          lowStockDesc,
          lowStockItems.isEmpty ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
          lowStockItems.isEmpty ? AppColors.freshGreen : AppColors.error,
          actionLabel: lowStockItems.isEmpty ? null : "Restock Now",
          onTap: lowStockItems.isEmpty
              ? null
              : () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => InventoryPage(shopId: _myShop?.id)));
                  _loadDashboardData();
                },
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!_isLoadingShop) ...[
          if (_myShop?.verificationStatus == 'Pending')
            _buildAlertCard(
              "Profile Verification Under Review",
              "Your business registration documents are currently under review. This usually takes 24 hours.",
              Icons.hourglass_empty_rounded,
              AppColors.warning,
            )
          else if (_myShop?.verificationStatus == 'Rejected')
            _buildAlertCard(
              "Verification Rejected",
              "Your documents were rejected. Please click here to re-upload valid business credentials.",
              Icons.error_outline_rounded,
              AppColors.error,
              actionLabel: "Re-verify Profile",
              onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => VerificationPage(initialStatus: _myShop?.verificationStatus)));
                if (result == true) {
                  _loadDashboardData();
                }
              },
            )
          else if (_myShop?.verificationStatus != 'Verified')
            _buildAlertCard(
              "Profile Verification Pending",
              "Complete your business registration process to unlock online payments & higher daily limits.",
              Icons.verified_user_outlined,
              AppColors.warning,
              actionLabel: "Verify Profile",
              onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => VerificationPage(initialStatus: _myShop?.verificationStatus)));
                if (result == true) {
                  _loadDashboardData();
                }
              },
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (_orders.isNotEmpty) ...[
          _buildBestSellerAlert(),
        ],
      ],
    );
  }

  Widget _buildBestSellerAlert() {
    final Map<String, int> productSales = {};
    for (final order in _orders.where((o) => o.status == 'Delivered')) {
      for (final item in order.items) {
        productSales[item.name] = (productSales[item.name] ?? 0) + item.quantity;
      }
    }
    if (productSales.isEmpty) {
      return const SizedBox.shrink();
    }
    final sortedSales = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final bestSeller = sortedSales.first;

    return _buildAlertCard(
      "Best Seller Product",
      "${bestSeller.key} is your top-grossing item, generating ${bestSeller.value} units sold.",
      Icons.insights_rounded,
      AppColors.freshGreen,
    );
  }

  Widget _buildAlertCard(String title, String desc, IconData icon, Color color, {String? actionLabel, VoidCallback? onTap}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                ),
                if (actionLabel != null && onTap != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onTap,
                    child: Row(
                      children: [
                        Text(
                          actionLabel,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: color, size: 12),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityTimeline() {
    final recentOrders = _orders.take(4).toList();
    if (recentOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.soft,
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text("No recent activity", style: TextStyle(color: AppColors.textSecondary)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: List.generate(recentOrders.length * 2 - 1, (index) {
          if (index.isOdd) {
            return _buildActivityDivider();
          }
          final orderIndex = index ~/ 2;
          final order = recentOrders[orderIndex];
          final timeStr = _getFormattedTimeAgo(order.createdAt);
          final customerName = order.customerInfo?['name'] ?? 'Customer';
          
          return _buildActivityItem(
            "Order ${order.status}",
            "Order ID: ${order.id.substring(order.id.length - 6).toUpperCase()} from $customerName (${order.items.length} items)",
            timeStr,
            _getOrderStatusIcon(order.status),
            _getOrderStatusColor(order.status),
          );
        }),
      ),
    );
  }

  Widget _buildActivityItem(String title, String desc, String time, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActivityDivider() {
    return Container(
      height: 16,
      margin: const EdgeInsets.only(left: 16),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.primaryLight, width: 2)),
      ),
    );
  }

  // --- TAB 1: ORDERS TAB ---
  Widget _buildOrdersTab() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Incoming Orders", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoadingOrders
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text("No incoming orders yet"))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    Color statusColor = _getOrderStatusColor(order.status);
                    
                    String actionLabel = '';
                    String nextStatus = '';
                    if (order.status == 'Placed') {
                      actionLabel = 'Accept Order';
                      nextStatus = 'Processing';
                    } else if (order.status == 'Processing') {
                      actionLabel = 'Mark Dispatched';
                      nextStatus = 'Dispatched';
                    } else if (order.status == 'Dispatched') {
                      actionLabel = 'Mark Delivered';
                      nextStatus = 'Delivered';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        side: BorderSide(color: AppColors.primaryLight.withOpacity(0.5), width: 1.2),
                      ),
                      elevation: 0,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '#${order.id.substring(order.id.length - 6).toUpperCase()}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    order.status,
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Customer: ${order.customerInfo?['name'] ?? 'Unknown Customer'}",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${order.items.length} items • ${_getFormattedTimeAgo(order.createdAt)}",
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                Text(
                                  "₹${order.totalAmount.toStringAsFixed(0)}",
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _showOrderDetailsDialog(order),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.primaryLight),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: const Text("Details", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ),
                                if (actionLabel.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _updateOrderStatus(order.id, nextStatus),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    child: Text(actionLabel, style: const TextStyle(fontSize: 12, color: Colors.white)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showOrderDetailsDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Order ID: ${order.id.substring(order.id.length - 6).toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.name} x${item.quantity}', style: const TextStyle(fontSize: 13)),
                    Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('₹${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Delivery Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                order.deliveryAddress is Map 
                    ? '${order.deliveryAddress['street'] ?? ''}, ${order.deliveryAddress['city'] ?? ''}, ${order.deliveryAddress['state'] ?? ''} - ${order.deliveryAddress['zipCode'] ?? ''}'
                    : order.deliveryAddress?.toString() ?? 'No address provided',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text('Customer Contact:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Text('Name: ${order.customerInfo?['name'] ?? 'N/A'}', style: const TextStyle(fontSize: 13)),
              Text('Phone: ${order.customerInfo?['phone'] ?? 'N/A'}', style: const TextStyle(fontSize: 13)),
              Text('Email: ${order.customerInfo?['email'] ?? 'N/A'}', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // --- TAB 4: PROFILE TAB ---
  Widget _buildProfileTab(BuildContext context, AuthController authController) {
    final user = authController.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Store Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // User Avatar Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (user?.name.isNotEmpty == true ? user!.name.substring(0, 1) : 'M').toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Merchant Name',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          user?.email ?? 'merchant@store.com',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user?.role ?? 'Shopkeeper',
                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Business Setup Details Card
            _buildProfileSectionHeader("Business Details"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                children: [
                  _buildProfileTile(Icons.storefront_rounded, "Store Name", _myShop?.name ?? user?.businessName ?? 'Merchant Agency'),
                  _buildProfileTile(Icons.category_rounded, "Category", _myShop?.category ?? "Grocery & Staples"),
                  _buildProfileTile(Icons.account_balance_rounded, "Settlement Account", "State Bank of India (•••• 5678)"),
                  _buildProfileTile(Icons.phone_rounded, "Contact Number", user?.phone ?? '+91 98765 43210'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Settings Section
            _buildProfileSectionHeader("Settings"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                children: [
                  _buildProfileSwitchTile(Icons.notifications_active_rounded, "App Alerts & Notifications"),
                  _buildProfileSwitchTile(Icons.fingerprint_rounded, "Biometric Authentication"),
                  _buildProfileNavigationTile(Icons.lock_outline_rounded, "Change Security PIN"),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Logout Button
            GestureDetector(
              onTap: () async {
                await authController.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('Log Out Merchant Account', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 6),
        child: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8),
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, String val) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      trailing: Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  Widget _buildProfileSwitchTile(IconData icon, String title) {
    bool isSwitched = true;
    return StatefulBuilder(
      builder: (context, setTileState) {
        return SwitchListTile(
          secondary: Icon(icon, color: AppColors.primary, size: 20),
          title: Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          value: isSwitched,
          activeColor: AppColors.primary,
          onChanged: (bool value) {
            setTileState(() {
              isSwitched = value;
            });
          },
        );
      },
    );
  }

  Widget _buildProfileNavigationTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
      onTap: () {},
    );
  }

  // --- GENERAL POPUPS/MODAL SHEETS ---
  void _showNotificationsBottomSheet(BuildContext context) {
    final notifications = _getNotifications();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                "Notifications",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: notifications.map((n) {
                  return ListTile(
                    leading: Icon(Icons.notifications_active_rounded, color: n['unread'] ? AppColors.accent : AppColors.textMuted),
                    title: Text(n['title'], style: TextStyle(fontWeight: n['unread'] ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                    trailing: Text(n['time'], style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Dismiss All", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Customer Reviews (4.8 ★)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.lg),
            _buildReviewItem("Sayan P.", "Fast dispatch and products were fresh. 5 stars!", "5.0 ★"),
            const Divider(),
            _buildReviewItem("Rohan S.", "Stock was accurate. Easy shopping flow.", "4.0 ★"),
            const Divider(),
            _buildReviewItem("Sneha K.", "Basmati rice is of exceptional quality.", "5.0 ★"),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String author, String review, String rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text(review, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(rating, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  void _showPaymentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Settlement Ledger", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.lg),
            // Build settlements dynamically based on Delivered orders
            ..._orders.where((o) => o.status == 'Delivered').take(3).map((o) {
              return Column(
                children: [
                  _buildPaymentItem(
                    _getFormattedTimeAgo(o.createdAt),
                    "₹${o.totalAmount.toStringAsFixed(0)} settled",
                    "Completed",
                    AppColors.freshGreen,
                  ),
                  const Divider(),
                ],
              );
            }).toList(),
            if (_orders.where((o) => o.status == 'Delivered').isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("No completed settlements yet.", style: TextStyle(color: AppColors.textSecondary)),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(String date, String amount, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 2),
              Text(amount, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  void _showCreateOfferBottomSheet(BuildContext context) {
    final TextEditingController offerName = TextEditingController();
    final TextEditingController discountVal = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Text("Create Store Offer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: offerName,
              decoration: const InputDecoration(labelText: "Offer Name (e.g. Monsoon Special)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: discountVal,
              decoration: const InputDecoration(labelText: "Discount Percentage (e.g. 10%)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Offer '${offerName.text}' created successfully!")),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Launch Offer", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM NAVIGATION BAR ---
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, "Dashboard"),
              _buildNavItem(1, Icons.shopping_cart_rounded, "Orders"),
              _buildNavItem(2, Icons.inventory_2_rounded, "Products"),
              _buildNavItem(3, Icons.bar_chart_rounded, "Reports"),
              _buildNavItem(4, Icons.person_rounded, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
