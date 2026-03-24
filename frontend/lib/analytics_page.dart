import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Performance Insights", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. QUICK STATS SUMMARY
            _buildQuickInsights(),
            const SizedBox(height: 32),

            const Text("Weekly Sales Trend", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // 2. MODERN GRADIENT BAR CHART
            _buildModernChart(),
            
            const SizedBox(height: 35),
            const Text("Top Selling Inventory", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // 3. CLEAN PRODUCT RANKING
            _buildProductRank("1", "Organic Basmati Rice", "120 Units", Colors.amber),
            _buildProductRank("2", "Farm Fresh Milk", "95 Units", Colors.grey.shade400),
            _buildProductRank("3", "Whole Wheat Atta", "80 Units", Colors.brown.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSmallInsightCard("Growth", "+12.5%", Icons.trending_up, Colors.green),
        _buildSmallInsightCard("Visitors", "1.2k", Icons.people_outline, Colors.blue),
        // FIXED: Lowercase 'a' in assignment
        _buildSmallInsightCard("Refunds", "0.2%", Icons.assignment_return_outlined, Colors.red),
      ],
    );
  }

  Widget _buildSmallInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // FIXED: Used withValues to avoid deprecation warnings
            color: Colors.black.withValues(alpha: 0.03), 
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildModernChart() {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildModernBar("M", 0.4),
          _buildModernBar("T", 0.7),
          _buildModernBar("W", 0.5),
          _buildModernBar("T", 0.9),
          _buildModernBar("F", 0.6),
          _buildModernBar("S", 1.0),
          _buildModernBar("S", 0.8),
        ],
      ),
    );
  }

  Widget _buildModernBar(String label, double heightFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 25,
          height: 150 * heightFactor,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade300, Colors.teal.shade700],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProductRank(String rank, String name, String sales, Color rankColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02), 
            blurRadius: 10,
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(color: rankColor.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Center(
            child: Text(rank, style: TextStyle(color: rankColor, fontWeight: FontWeight.bold)),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: Text(sales, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
      ),
    );
  }
}