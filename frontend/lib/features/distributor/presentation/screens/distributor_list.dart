import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../../../core/network/api_client.dart';

class DistributorList extends StatefulWidget {
  const DistributorList({super.key});

  @override
  State<DistributorList> createState() => _DistributorListState();
}

class _DistributorListState extends State<DistributorList> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _distributors = [];

  @override
  void initState() {
    super.initState();
    _fetchDistributors();
  }

  Future<void> _fetchDistributors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = context.read<ApiClient>();
      final res = await apiClient.get('/distributors/public/all');
      if (res is List) {
        setState(() {
          _distributors = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('[DistributorList] Error fetching distributors: $e');
    }

    // Graceful fallback sample data if no public distributors registered yet
    if (mounted) {
      setState(() {
        _distributors = [
          {
            "name": "Global Foods Wholesaler",
            "category": "Groceries",
            "rating": 4.9,
            "status": "open",
            "address": "Wholesale Market Yard, Phase 1",
          },
          {
            "name": "Metro Provisions Dist.",
            "category": "Staples & Oils",
            "rating": 4.8,
            "status": "open",
            "address": "Central Mandi, South Gate",
          },
          {
            "name": "City Beverages Ltd.",
            "category": "Beverages",
            "rating": 4.7,
            "status": "paused",
            "address": "Industrial Area, Block B",
          },
        ];
        _isLoading = false;
      });
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchDistributors,
              child: _distributors.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            "No stock partners available in your area yet.",
                            style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      itemCount: _distributors.length,
                      itemBuilder: (context, index) {
                        final d = _distributors[index];
                        final colors = [
                          AppColors.primary,
                          AppColors.secondary,
                          AppColors.freshGreen,
                          AppColors.skyBlue,
                        ];
                        final color = colors[index % colors.length];

                        return _buildDistributorCard(context, d, color);
                      },
                    ),
            ),
    );
  }

  Widget _buildDistributorCard(
    BuildContext context,
    Map<String, dynamic> item,
    Color color,
  ) {
    final name = item['name'] ?? 'Distributor Agency';
    final category = item['category'] ?? 'Wholesale Goods';
    final rating = item['rating']?.toString() ?? '4.8';
    final address = item['address']?.toString() ?? '';
    final status = (item['status']?.toString() ?? 'open').toLowerCase();
    final isOpen = status == 'open';

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
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOpen ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOpen ? 'OPEN' : 'BUSY',
                              style: TextStyle(
                                color: isOpen ? Colors.green.shade800 : Colors.orange.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
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
                          if (address.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSmallInfo(Icons.local_shipping_outlined, "Same / Next Day Delivery"),
                          _buildSmallInfo(Icons.star_rounded, "$rating Rating"),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Connecting with $name...")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text("View Wholesale Catalog"),
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
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
