import 'distributor_list.dart';
import 'verification_page.dart';
import 'inventory_page.dart';
import 'analytics_page.dart';
import 'package:flutter/material.dart';

class ShopkeeperDash extends StatelessWidget {
  const ShopkeeperDash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean off-white background
      body: Stack(
        children: [
          // 1. WAVY HEADER IMAGE (Local Asset)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.40,
            child: Image.asset(
              'assets/bg_image.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. FOREGROUND CONTENT
          SafeArea(
            child: Column(
              children: [
                // 1. CUSTOM TOP APP BAR
                _buildTopBar(context),

                // 2. SCROLLABLE CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        // Welcome Section
                        _buildWelcomeSection(),
                        
                        const SizedBox(height: 30),
                        
                        // Stats Row
                        Row(
                          children: [
                            // Using Rust/Orange for Orders
                            _buildStatCard("25 Orders", "Total this month", Icons.inventory_2_outlined, const Color(0xFFC05800)),
                            const SizedBox(width: 15),
                            // Using Elegant Green for Revenue
                            _buildStatCard("₹12,450", "Revenue", Icons.payments_outlined, Colors.green.shade700),
                          ],
                        ),

                        const SizedBox(height: 35),
                        
                        // Management Tools Header
                        Row(
                          children: [
                            const Text(
                              "Management Tools", 
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.w900, 
                                letterSpacing: -0.5,
                                color: Color(0xFF38240D), // Dark Chocolate
                              )
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 4, 
                              width: 35, 
                              decoration: BoxDecoration(
                                color: const Color(0xFFC05800), // Rust accent line
                                borderRadius: BorderRadius.circular(2)
                              )
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 3. MANAGEMENT GRID (Clean, no overlap)
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.1,
                          children: [
                            _buildMenuCard(
                              Icons.inventory_2_rounded, "Manage Stock", const Color(0xFF38240D), // Dark Chocolate
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryPage())),
                            ),
                            _buildMenuCard(
                              Icons.local_shipping_rounded, "Distributors", const Color(0xFFC05800), // Rust/Orange
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DistributorList())),
                            ),
                            _buildMenuCard(
                              Icons.bar_chart_rounded, "Sales Report", const Color(0xFFC05800), // Rust/Orange
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsPage())),
                            ),
                            _buildMenuCard(
                              Icons.verified_user_rounded, "Verification", const Color(0xFF38240D), // Dark Chocolate
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VerificationPage())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                // 4. CUSTOM BOTTOM NAVIGATION
                _buildBottomNav(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF38240D), size: 20), // Dark Chocolate
            ),
          ),
          // Branding
          const Text(
            "Vycen", 
            style: TextStyle(
              color: Color(0xFF38240D), // Dark Chocolate
              fontSize: 22, 
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5
            )
          ),
          // Invisible placeholder to keep 'Vycen' perfectly centered
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back 👋", style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              "Your Store", 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Color(0xFF38240D))
            ),
          ],
        ),
        // Avatar with Online Indicator
        Stack(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF38240D), // Dark Chocolate
              child: Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                height: 16,
                width: 16,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStatCard(String primaryText, String subText, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05), 
              blurRadius: 20, 
              offset: const Offset(0, 10)
            )
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Colored Top Edge Accent
            Positioned(
              top: -20,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5)
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 16),
                Text(
                  primaryText, 
                  style: TextStyle(
                    fontSize: primaryText.contains('₹') ? 22 : 24, 
                    fontWeight: FontWeight.w900, 
                    color: const Color(0xFF38240D), // Always Dark Chocolate for numbers
                    letterSpacing: -0.5,
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  subText, 
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)
                ),
              ],
            ),
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              label, 
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14, 
                color: Color(0xFF38240D), // Dark Chocolate text
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Active Tab
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF38240D), // Dark Chocolate active state
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dashboard_rounded, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text("DASHBOARD", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
          
          // Inactive Tabs
          _buildInactiveNavIcon(Icons.inventory_2_outlined, "INVENTORY"),
          _buildInactiveNavIcon(Icons.bar_chart_outlined, "REPORTS"),
          _buildInactiveNavIcon(Icons.person_outline_rounded, "ACCOUNT"),
        ],
      ),
    );
  }

  Widget _buildInactiveNavIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 26),
        const SizedBox(height: 4),
        Text(
          label, 
          style: TextStyle(
            color: Colors.grey.shade600, 
            fontSize: 10, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 0.5
          )
        ),
      ],
    );
  }
}