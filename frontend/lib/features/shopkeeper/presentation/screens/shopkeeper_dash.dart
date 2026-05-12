import 'package:flutter/material.dart';
import 'package:testapp/core/design_system.dart';
import 'package:testapp/features/distributor/presentation/screens/distributor_list.dart';
import 'package:testapp/features/auth/presentation/screens/verification_page.dart';
import 'inventory_page.dart';
import 'analytics_page.dart';

class ShopkeeperDash extends StatelessWidget {
  const ShopkeeperDash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. WAVY HEADER IMAGE (Local Asset)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.xxl),
                  bottomRight: Radius.circular(AppRadius.xxl),
                ),
              ),
              child: Opacity(
                opacity: 0.1,
                child: Center(child: Icon(Icons.storefront_rounded, size: 150, color: Colors.white)),
              ),
            ),
          ),

          // 2. FOREGROUND CONTENT
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        _buildWelcomeSection(),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        Row(
                          children: [
                            _buildStatCard("25 Orders", "Total this month", Icons.inventory_2_outlined, AppColors.citrusOrange),
                            const SizedBox(width: AppSpacing.md),
                            _buildStatCard("₹12,450", "Revenue", Icons.payments_outlined, AppColors.freshGreen),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),
                        
                        Row(
                          children: [
                            const Text(
                              "Management Tools", 
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.w900, 
                                color: AppColors.textPrimary,
                              )
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 4, 
                              width: 35, 
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2)
                              )
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.1,
                          children: [
                            _buildMenuCard(
                              Icons.inventory_2_rounded, "Manage Stock", AppColors.primary,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryPage())),
                            ),
                            _buildMenuCard(
                              Icons.local_shipping_rounded, "Distributors", AppColors.secondary,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DistributorList())),
                            ),
                            _buildMenuCard(
                              Icons.bar_chart_rounded, "Sales Report", AppColors.organicAmber,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsPage())),
                            ),
                            _buildMenuCard(
                              Icons.verified_user_rounded, "Verification", AppColors.skyBlue,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VerificationPage())),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          const Text(
            "Shop Dashboard", 
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back 👋", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text(
              "Your Store", 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)
            ),
          ],
        ),
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
        )
      ],
    );
  }

  Widget _buildStatCard(String primaryText, String subText, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              primaryText, 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)
            ),
            Text(subText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 14),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
