import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../../auth/data/user_model.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../../welcome_screen.dart';

class AccountPage extends StatefulWidget {
  final String customerId;
  final UserModel? user;

  const AccountPage({super.key, required this.customerId, this.user});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _totalOrders = 0;
  double _totalSpent = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadOrderStats();
  }

  Future<void> _loadOrderStats() async {
    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.get('/orders/my');
      
      final orders = response as List<dynamic>;
      double spent = 0;
      for (final o in orders) {
        spent += (o['totalAmount'] as num?)?.toDouble() ?? 0;
      }
      if (mounted) {
        setState(() {
          _totalOrders = orders.length;
          _totalSpent = spent;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  String get _displayName {
    if (widget.user?.name.isNotEmpty == true) return widget.user!.name;
    if (widget.user?.email.isNotEmpty == true) return widget.user!.email.split('@')[0];
    return 'Customer';
  }

  String get _displayEmail => widget.user?.email ?? '';

  String get _displayPhone => widget.user?.phone ?? '';

  bool get _isProfileComplete =>
      _displayPhone.isNotEmpty;

  String get _initials {
    final name = _displayName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'C';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          _buildHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Personal info card
                _buildInfoCard(),
                const SizedBox(height: AppSpacing.lg),

                _buildSectionTitle('Shopping'),
                _buildMenuTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'My Orders',
                  subtitle: 'Track current & past orders',
                  color: AppColors.freshGreen,
                  delay: 100,
                ),
                _buildMenuTile(
                  icon: Icons.location_on_outlined,
                  title: 'Saved Addresses',
                  subtitle: 'Home, Office & more',
                  color: AppColors.skyBlue,
                  delay: 150,
                ),
                _buildMenuTile(
                  icon: Icons.favorite_border_rounded,
                  title: 'Wishlist',
                  subtitle: 'Items you love',
                  color: AppColors.error,
                  delay: 200,
                ),
                _buildMenuTile(
                  icon: Icons.local_offer_outlined,
                  title: 'Coupons & Offers',
                  subtitle: 'Your available discounts',
                  color: AppColors.organicAmber,
                  delay: 250,
                ),

                const SizedBox(height: AppSpacing.md),
                _buildSectionTitle('Account'),
                _buildMenuTile(
                  icon: Icons.payment_rounded,
                  title: 'Payment Methods',
                  subtitle: 'Cards, UPI & Wallets',
                  color: AppColors.primary,
                  delay: 300,
                ),
                _buildMenuTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Manage alerts & updates',
                  color: AppColors.citrusOrange,
                  delay: 350,
                ),
                _buildMenuTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy & Security',
                  subtitle: 'Password, Biometrics',
                  color: AppColors.secondary,
                  delay: 400,
                ),

                const SizedBox(height: AppSpacing.md),
                _buildSectionTitle('Support'),
                _buildMenuTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: 'FAQs, Contact us',
                  color: AppColors.skyBlue,
                  delay: 450,
                ),
                _buildMenuTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About App',
                  subtitle: 'Version 1.0.0',
                  color: AppColors.textSecondary,
                  delay: 500,
                ),

                const SizedBox(height: AppSpacing.xl),
                _buildLogoutButton(),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          MediaQuery.of(context).padding.top + AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: AppSpacing.xl),

            // Avatar + Name
            Row(
              children: [
                Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ).animate().scale(
                    delay: 100.ms, duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user?.email ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.5)),
                        ),
                        child: const Text(
                          '🛒  Customer',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Stats Row
            _loadingStats
                ? const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : Row(
                    children: [
                      _buildStatCard(
                          '$_totalOrders', 'Orders', Icons.shopping_bag_outlined),
                      _buildStatDivider(),
                      _buildStatCard(
                          '₹${_totalSpent.toStringAsFixed(0)}',
                          'Spent',
                          Icons.currency_rupee_rounded),
                      _buildStatDivider(),
                      _buildStatCard('4.8', 'Rating', Icons.star_rounded),
                    ],
                  ).animate().fadeIn(delay: 350.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _isProfileComplete
            ? AppColors.freshGreen.withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
        border: _isProfileComplete
            ? Border.all(color: AppColors.freshGreen.withOpacity(0.2))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isProfileComplete
                  ? AppColors.freshGreen.withOpacity(0.15)
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              _isProfileComplete
                  ? Icons.check_circle_outline_rounded
                  : Icons.person_outline_rounded,
              color: _isProfileComplete
                  ? AppColors.freshGreen
                  : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isProfileComplete ? 'Profile Complete!' : 'Complete your profile',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _isProfileComplete
                        ? AppColors.freshGreen
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isProfileComplete
                      ? _displayPhone
                      : 'Add phone number to get faster delivery',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(
            _isProfileComplete
                ? Icons.verified_rounded
                : Icons.chevron_right_rounded,
            color: _isProfileComplete
                ? AppColors.freshGreen
                : AppColors.textMuted,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    int delay = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textMuted, size: 20),
        onTap: () {},
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.05);
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        await context.read<AuthController>().logout();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
            Text(
              'Log Out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 550.ms);
  }
}
