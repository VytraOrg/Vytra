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
      backgroundColor: Colors.grey[50], // Light grey background for Neumorphism
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. GLASSMORPHISM HEADER WITH BACK BUTTON
            _buildGlassHeader(context),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Business Overview",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 15),
                  
                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard("Total Orders", "25", Colors.orange),
                      const SizedBox(width: 15),
                      _buildStatCard("Revenue", "₹12,450", Colors.green),
                    ],
                  ),

                  const SizedBox(height: 35),
                  const Text(
                    "Management Tools", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                  ),
                  const SizedBox(height: 15),

                  // 2. NEUMORPHIC ACTION GRID
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _buildMenuCard(
                        Icons.inventory_2_rounded, "Manage Stock", Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryPage())),
                      ),
                      _buildMenuCard(
                        Icons.local_shipping_rounded, "Distributors", Colors.purple,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DistributorList())),
                      ),
                      _buildMenuCard(
                        Icons.analytics_rounded, "Sales Report", Colors.teal,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsPage())),
                      ),
                      _buildMenuCard(
                        Icons.verified_user_rounded, "Verification", Colors.red,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VerificationPage())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildGlassHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 25, bottom: 35),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Glass Styled Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome back,", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 4),
                  Text("Store Manager", 
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 10,
              offset: Offset(-5, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              label, 
              textAlign: TextAlign.center, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14, 
                color: Colors.grey.shade800
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03), 
              blurRadius: 15, 
              offset: const Offset(0, 8)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, 
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3)
            ),
            const SizedBox(height: 10),
            Text(
              value, 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }
}