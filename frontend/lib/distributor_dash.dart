import 'package:flutter/material.dart';
import 'distributor_orders_page.dart';
import 'distributor_inventory_page.dart';
import 'distributor_sales_report.dart';

class DistributorDash extends StatelessWidget {
  const DistributorDash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAgencyHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Business Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  // Summary Cards from your notes
                  Row(
                    children: [
                      _buildSummaryCard(context, "Total Items", "150+", Icons.inventory, Colors.blue),
                      const SizedBox(width: 12),
                      _buildSummaryCard(context, "Order Value", "₹45k", Icons.currency_rupee, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(context, "Monthly Sales", "₹1.2L", Icons.bar_chart, Colors.purple, isFullWidth: true),
                  
                  const SizedBox(height: 30),
                  const Text("Core Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  _buildActionTile(context, "Incoming Orders", Icons.assignment_late_outlined, "Manage shopkeeper requests"),
                  _buildActionTile(context, "Update Inventory", Icons.edit_calendar_outlined, "Add/Remove/Update stock rates"),
                  _buildActionTile(context, "Delivery Tracking", Icons.local_shipping_outlined, "Notify shopkeepers on dispatch"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgencyHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: Colors.indigo[900],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.only(top: 80, left: 25, right: 25),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo.shade900, Colors.indigo.shade700]),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Distributor", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("Owner: ", style: TextStyle(color: Colors.white70)),
              Text("GST: ", style: TextStyle(color: Colors.white70)),
              Text("Area: ", style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    Widget card = Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
      child: Column(children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );

    return isFullWidth 
      ? GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DistributorSalesReport())),
          child: card) 
      : Expanded(child: card);
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon, String sub) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          if (title == "Incoming Orders") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DistributorOrdersPage()));
          } else if (title == "Update Inventory") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DistributorInventoryPage()));
          }
        },
      ),
    );
  }
}