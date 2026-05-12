import 'package:flutter/material.dart';
import '../../../../core/design_system.dart';

class DistributorList extends StatelessWidget {
  const DistributorList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Stock Partners", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        itemCount: 4,
        itemBuilder: (context, index) {
          final List<String> distributors = [
            "Global Foods Wholesaler",
            "Metro Electronics Dist.",
            "City Beverages Ltd.",
            "Sunrise Grains Corp."
          ];
          
          final List<String> categories = ["Groceries", "Electronics", "Beverages", "Grains"];
          final List<Color> accentColors = [AppColors.primary, AppColors.secondary, AppColors.organicAmber, AppColors.skyBlue];

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
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.textPrimary),
                          ),
                          const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.md),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSmallInfo(Icons.local_shipping_outlined, "2 Day Delivery"),
                          _buildSmallInfo(Icons.star_rounded, "4.9 Rating"),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Opening $name Catalog...")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("View Bulk Catalog"),
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
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}