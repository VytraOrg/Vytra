import 'package:flutter/material.dart';
import '../../../orders/domain/order_model.dart';
import '../../../shop/data/product_model.dart';

class AnalyticsPage extends StatelessWidget {
  final List<OrderModel> orders;
  final List<ProductModel> products;

  const AnalyticsPage({super.key, required this.orders, required this.products});

  @override
  Widget build(BuildContext context) {
    // Dynamic Top Selling Ranking
    final Map<String, int> productSales = {};
    for (final order in orders.where((o) => o.status == 'Delivered')) {
      for (final item in order.items) {
        productSales[item.name] = (productSales[item.name] ?? 0) + item.quantity;
      }
    }
    
    final sortedSales = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Dynamic Weekly Trend Calculation
    final today = DateTime.now();
    final List<double> weeklyData = List.filled(7, 0.0);
    final List<String> days = [];
    final List<String> daysShort = ["M", "T", "W", "T", "F", "S", "S"];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      days.add(daysShort[day.weekday - 1]);

      final dailyTotal = orders
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
            _buildQuickInsights(totalWeeklySales),
            const SizedBox(height: 32),

            const Text("Weekly Sales Trend", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // 2. MODERN GRADIENT BAR CHART
            _buildModernChart(weeklyData, days, maxDailyTotal),
            
            const SizedBox(height: 35),
            const Text("Top Selling Inventory", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // 3. CLEAN PRODUCT RANKING
            if (sortedSales.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("No completed order sales yet", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              )
            else ...[
              if (sortedSales.length > 0)
                _buildProductRank("1", sortedSales[0].key, "${sortedSales[0].value} Units", Colors.amber),
              if (sortedSales.length > 1)
                _buildProductRank("2", sortedSales[1].key, "${sortedSales[1].value} Units", Colors.grey.shade400),
              if (sortedSales.length > 2)
                _buildProductRank("3", sortedSales[2].key, "${sortedSales[2].value} Units", Colors.brown.shade300),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights(double weeklySales) {
    String growthText = "+0.0%";
    if (orders.isNotEmpty) {
      growthText = weeklySales > 0 ? "+12.5%" : "+0.0%";
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSmallInsightCard("Weekly Sales", "₹${weeklySales.toStringAsFixed(0)}", Icons.trending_up, Colors.green),
        _buildSmallInsightCard("Orders", "${orders.length}", Icons.people_outline, Colors.blue),
        _buildSmallInsightCard("Active Items", "${products.length}", Icons.inventory_2_outlined, Colors.purple),
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
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildModernChart(List<double> weeklyData, List<String> days, double maxDailyTotal) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final heightFactor = maxDailyTotal > 0 ? weeklyData[index] / maxDailyTotal : 0.0;
          return _buildModernBar(days[index], heightFactor);
        }),
      ),
    );
  }

  Widget _buildModernBar(String label, double heightFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 25,
          height: 150 * (heightFactor > 0 ? heightFactor : 0.05),
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
            color: Colors.black.withOpacity(0.02), 
            blurRadius: 10,
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(color: rankColor.withOpacity(0.2), shape: BoxShape.circle),
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