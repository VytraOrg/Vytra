import 'package:flutter/material.dart';

class DistributorList extends StatelessWidget {
  const DistributorList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for contrast
      appBar: AppBar(
        title: const Text("Stock Partners", 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        itemCount: 4,
        itemBuilder: (context, index) {
          final List<String> distributors = [
            "Global Foods Wholesaler",
            "Metro Electronics Dist.",
            "City Beverages Ltd.",
            "Sunrise Grains Corp."
          ];
          
          final List<String> categories = ["Groceries", "Electronics", "Beverages", "Grains"];
          final List<Color> accentColors = [Colors.purple, Colors.blue, Colors.orange, Colors.teal];

          return _buildDistributorCard(
            context, 
            distributors[index], 
            categories[index], 
            accentColors[index]
          );
        },
      ),
    );
  }

  Widget _buildDistributorCard(BuildContext context, String name, String category, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Color Indicator (Side Bar)
              Container(width: 6, color: color),
              
              // 2. Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          const Icon(Icons.verified_rounded, color: Colors.blue, size: 20),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 15),
                      
                      // B2B Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSmallInfo(Icons.local_shipping_outlined, "2 Day Delivery"),
                          _buildSmallInfo(Icons.star_rounded, "4.9 Rating"),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Opening $name Catalog...")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[900], // Dark for professional look
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("View Bulk Catalog", 
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}