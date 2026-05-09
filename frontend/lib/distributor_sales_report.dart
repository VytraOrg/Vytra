import 'package:flutter/material.dart';

class DistributorSalesReport extends StatelessWidget {
  const DistributorSalesReport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Sales Analytics", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatTile("Total Order Value", "₹2,45,000", Icons.payments_outlined, Colors.green),
            const SizedBox(height: 15),
            _buildStatTile("Monthly Growth", "+14.2%", Icons.trending_up, Colors.blue),
            const SizedBox(height: 35),
            const Text("Top Performing Shops", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildShopRank("1", "Maa Tara Variety", "₹85,000"),
            _buildShopRank("2", "Joy Guru Stores", "₹62,000"),
            _buildShopRank("3", "Lokenath Dash", "₹41,000"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white, size: 20)),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopRank(String rank, String name, String amount) {
    return ListTile(
      leading: Text("#$rank", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Text(amount, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
    );
  }
}