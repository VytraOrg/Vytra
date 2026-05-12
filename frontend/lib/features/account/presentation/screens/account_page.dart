import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:testapp/core/design_system.dart';
import 'package:testapp/features/auth/data/user_model.dart';
import 'package:testapp/features/auth/presentation/auth_controller.dart';
import 'package:testapp/features/orders/presentation/screens/orders_page.dart';
import 'package:testapp/features/auth/presentation/screens/welcome_screen.dart';
import '../controllers/account_controller.dart';

class AccountPage extends StatefulWidget {
  final String customerId;
  final UserModel? user;

  const AccountPage({super.key, required this.customerId, this.user});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountController>().loadStats();
    });
  }

  String get _displayName {
    if (widget.user?.name.isNotEmpty == true) return widget.user!.name;
    if (widget.user?.email.isNotEmpty == true) return widget.user!.email.split('@')[0];
    return 'Customer';
  }

  String get _initials {
    final name = _displayName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'C';
  }

  @override
  Widget build(BuildContext context) {
    final accountController = context.watch<AccountController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          _buildHeader(accountController),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoCard(),
                const SizedBox(height: AppSpacing.lg),

                _buildSectionTitle('Shopping'),
                _buildMenuTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'My Orders',
                  subtitle: 'Track current & past orders',
                  color: AppColors.freshGreen,
                  delay: 100,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersPage())),
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

  Widget _buildHeader(AccountController controller) {
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
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: AppSpacing.xl),

            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.accent,
                  child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ).animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_displayName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(widget.user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            if (controller.isLoading)
              const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
            else
              Row(
                children: [
                  _buildStatCard('${controller.totalOrders}', 'Orders', Icons.shopping_bag_outlined),
                  _buildStatDivider(),
                  _buildStatCard('₹${controller.totalSpent.toStringAsFixed(0)}', 'Spent', Icons.currency_rupee_rounded),
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
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() => Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2));

  Widget _buildInfoCard() {
    final phone = widget.user?.phone ?? '';
    final isComplete = phone.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.freshGreen.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Icon(isComplete ? Icons.check_circle_outline_rounded : Icons.person_outline_rounded, color: isComplete ? AppColors.freshGreen : AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isComplete ? 'Profile Complete!' : 'Complete your profile', style: TextStyle(fontWeight: FontWeight.bold, color: isComplete ? AppColors.freshGreen : AppColors.textPrimary)),
                Text(isComplete ? phone : 'Add phone to get faster delivery', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, left: 4),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required String subtitle, required Color color, int delay = 0, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.md)), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        onTap: onTap,
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.05);
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        await context.read<AuthController>().logout();
        if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => WelcomeScreen()), (route) => false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.error.withOpacity(0.2))),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 550.ms);
  }
}
