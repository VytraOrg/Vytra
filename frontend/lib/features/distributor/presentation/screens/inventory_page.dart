import 'package:flutter/material.dart';
import '../../../../core/design_system.dart';
import '../../../../core/network/api_client.dart';

class DistributorInventoryPage extends StatefulWidget {
  const DistributorInventoryPage({super.key});

  @override
  State<DistributorInventoryPage> createState() => _DistributorInventoryPageState();
}

class _DistributorInventoryPageState extends State<DistributorInventoryPage> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _products = [];
  dynamic _myShop;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // 1. Get current user's shop info
      final shop = await _apiClient.get('/shops/my');
      _myShop = shop;
      
      // 2. Fetch products associated with this shop
      final shopId = shop['id'] ?? shop['_id'];
      final response = await _apiClient.get('/products?shopId=$shopId');
      
      setState(() {
        // Backend returns paginated { items: [...], meta: {...} }
        if (response is Map) {
          _products = (response['items'] as List<dynamic>? ?? []);
        } else if (response is List) {
          _products = response;
        } else {
          _products = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addProduct(String name, String unit) async {
    if (_myShop == null) return;
    try {
      final shopId = _myShop['id'] ?? _myShop['_id'];
      await _apiClient.post('/products', {
        'name': name,
        'unit': unit,
        'category': 'Grocery', // Required default category
        'price': 0.0,          // Required default price
        'shop': shopId,
        'stockQuantity': 100,  // Optional default stock
      });
      _loadData(); // Reload items from DB after adding
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: $e')),
        );
      }
    }
  }

  Future<void> _updateProduct(String id, String name, String unit) async {
    try {
      await _apiClient.put('/products/$id', {
        'name': name,
        'unit': unit,
      });
      _loadData(); // Reload items from DB after updating
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Stock Control", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(AppRadius.xl),
            bottomRight: Radius.circular(AppRadius.xl),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          )
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _myShop == null ? null : () => _showAddDialog(context),
        backgroundColor: _myShop == null ? Colors.grey : AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text("Retry"),
              )
            ],
          ),
        ),
      );
    }
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: AppSpacing.md),
            const Text(
              "No stock items found.",
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              "Tap '+' to add your first agency product.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: AppColors.primary.withOpacity(0.1), width: 1),
          ),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
            ),
            title: Text(
              product['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
            ),
            subtitle: Text(
              "Unit: ${product['unit'] ?? ''}",
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => _showAddDialog(context, product: product),
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, {dynamic product}) {
    final TextEditingController nameController = TextEditingController(text: product?['name'] ?? '');
    final TextEditingController unitController = TextEditingController(text: product?['unit'] ?? '');
    final bool isEdit = product != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                isEdit ? "Edit Agency Stock" : "Add Agency Stock", 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: nameController,
              style: const TextStyle(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: "Product Name",
                labelStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: unitController,
              style: const TextStyle(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: "Unit (e.g. Bag/Case)",
                labelStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.layers_outlined, color: AppColors.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final unit = unitController.text.trim();
                if (name.isNotEmpty && unit.isNotEmpty) {
                  if (isEdit) {
                    _updateProduct(product['_id'] ?? product['id'], name, unit);
                  } else {
                    _addProduct(name, unit);
                  }
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out all fields.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: Text(isEdit ? "Update Stock" : "Add Stock", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}