import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../shop/data/product_model.dart';

class InventoryPage extends StatefulWidget {
  final String? shopId;
  const InventoryPage({super.key, this.shopId});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (widget.shopId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Shop details not ready yet. Please return to the Dashboard.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.get('/products?shopId=${widget.shopId}&limit=100');
      
      final List<dynamic> items = response is Map
          ? (response['items'] as List? ?? [])
          : (response as List? ?? []);

      setState(() {
        _products = items.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addProduct(String name, String description, double price, String category, String unit, int stockQuantity) async {
    if (widget.shopId == null) return;
    
    try {
      final apiClient = context.read<ApiClient>();
      await apiClient.post('/products', {
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'unit': unit,
        'stockQuantity': stockQuantity,
        'shop': widget.shopId,
        'isAvailable': true,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully'), backgroundColor: Colors.green),
      );
      _loadProducts();
    } catch (e) {
      debugPrint('Error adding product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _editProduct(String id, String name, String description, double price, String category, String unit, int stockQuantity, bool isAvailable) async {
    try {
      final apiClient = context.read<ApiClient>();
      await apiClient.put('/products/$id', {
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'unit': unit,
        'stockQuantity': stockQuantity,
        'isAvailable': isAvailable,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully'), backgroundColor: Colors.green),
      );
      _loadProducts();
    } catch (e) {
      debugPrint('Error updating product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update product: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _updateStock(String id, int stockQuantity) async {
    try {
      final apiClient = context.read<ApiClient>();
      await apiClient.put('/products/$id', {
        'stockQuantity': stockQuantity,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock updated successfully'), backgroundColor: Colors.green),
      );
      _loadProducts();
    } catch (e) {
      debugPrint('Error updating stock: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update stock: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deleteProduct(String id) async {
    try {
      final apiClient = context.read<ApiClient>();
      await apiClient.delete('/products/$id');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully'), backgroundColor: Colors.green),
      );
      _loadProducts();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Inventory Manager", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF38240D),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProducts,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38240D)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 50, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF38240D)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProducts,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38240D)),
                          child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : _products.isEmpty
                  ? const Center(
                      child: Text(
                        "No products in inventory yet.\nTap 'Add Item' to start listing products.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        final bool isLowStock = product.stockQuantity < 10;
                        return _buildInventoryCard(context, product, isLowStock);
                      },
                    ),
      floatingActionButton: widget.shopId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddProductSheet(context),
              backgroundColor: const Color(0xFF38240D),
              label: const Text("Add Item", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, ProductModel product, bool isLowStock) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF38240D).withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF38240D)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF38240D)),
              ),
            ),
            if (!product.isAvailable)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "Draft/Inactive",
                  style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Price: ₹${product.price.toStringAsFixed(2)} per ${product.unit} • ${product.category}",
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isLowStock ? const Color(0xFFC05800).withOpacity(0.1) : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${product.stockQuantity} ${product.unit} left",
                style: TextStyle(
                  color: isLowStock ? const Color(0xFFC05800) : Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
          onSelected: (value) {
            if (value == 'Edit') {
              _showEditProductSheet(context, product);
            } else if (value == 'Stock') {
              _showUpdateStockDialog(context, product);
            } else if (value == 'Delete') {
              _showDeleteConfirmDialog(context, product);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Edit', child: Text('Edit Product', style: TextStyle(fontWeight: FontWeight.w500))),
            const PopupMenuItem(value: 'Stock', child: Text('Update Stock', style: TextStyle(fontWeight: FontWeight.w500))),
            const PopupMenuItem(
              value: 'Delete', 
              child: Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();
    final TextEditingController unitController = TextEditingController();
    final TextEditingController stockController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 30, left: 25, right: 25,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add New Product", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF38240D), letterSpacing: -0.5),
              ),
              const SizedBox(height: 25),
              _buildSheetTextField("Product Name", Icons.edit_note_rounded, nameController),
              const SizedBox(height: 15),
              _buildSheetTextField("Description (Optional)", Icons.description_outlined, descController),
              const SizedBox(height: 15),
              _buildSheetTextField("Category (e.g. Grocery, Snacks)", Icons.category_rounded, categoryController),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildSheetTextField("Price (₹)", Icons.currency_rupee_rounded, priceController, keyboardType: TextInputType.number)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildSheetTextField("Unit (e.g. kg, packet)", Icons.scale_rounded, unitController)),
                ],
              ),
              const SizedBox(height: 15),
              _buildSheetTextField("Initial Stock Quantity", Icons.layers_outlined, stockController, keyboardType: TextInputType.number),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 58),
                  backgroundColor: const Color(0xFF38240D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  final name = nameController.text.trim();
                  final desc = descController.text.trim();
                  final category = categoryController.text.trim();
                  final price = double.tryParse(priceController.text) ?? 0.0;
                  final unit = unitController.text.trim();
                  final stock = int.tryParse(stockController.text) ?? 0;

                  if (name.isEmpty || category.isEmpty || price <= 0 || unit.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill out all required fields with valid details'), backgroundColor: Colors.redAccent),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  _addProduct(name, desc, price, category, unit, stock);
                },
                child: const Text("Add to Inventory", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProductSheet(BuildContext context, ProductModel product) {
    final TextEditingController nameController = TextEditingController(text: product.name);
    final TextEditingController descController = TextEditingController(text: product.description ?? '');
    final TextEditingController priceController = TextEditingController(text: product.price.toString());
    final TextEditingController categoryController = TextEditingController(text: product.category);
    final TextEditingController unitController = TextEditingController(text: product.unit);
    final TextEditingController stockController = TextEditingController(text: product.stockQuantity.toString());
    bool isAvailable = product.isAvailable;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 30, left: 25, right: 25,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Edit Product Details", 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF38240D), letterSpacing: -0.5),
                ),
                const SizedBox(height: 25),
                _buildSheetTextField("Product Name", Icons.edit_note_rounded, nameController),
                const SizedBox(height: 15),
                _buildSheetTextField("Description (Optional)", Icons.description_outlined, descController),
                const SizedBox(height: 15),
                _buildSheetTextField("Category", Icons.category_rounded, categoryController),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildSheetTextField("Price (₹)", Icons.currency_rupee_rounded, priceController, keyboardType: TextInputType.number)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildSheetTextField("Unit", Icons.scale_rounded, unitController)),
                  ],
                ),
                const SizedBox(height: 15),
                _buildSheetTextField("Stock Quantity", Icons.layers_outlined, stockController, keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                SwitchListTile(
                  title: const Text("Available for purchase", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  value: isAvailable,
                  activeColor: const Color(0xFF38240D),
                  onChanged: (val) {
                    setSheetState(() {
                      isAvailable = val;
                    });
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 58),
                    backgroundColor: const Color(0xFF38240D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final desc = descController.text.trim();
                    final category = categoryController.text.trim();
                    final price = double.tryParse(priceController.text) ?? 0.0;
                    final unit = unitController.text.trim();
                    final stock = int.tryParse(stockController.text) ?? 0;

                    if (name.isEmpty || category.isEmpty || price <= 0 || unit.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill out all required fields with valid details'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    _editProduct(product.id, name, desc, price, category, unit, stock, isAvailable);
                  },
                  child: const Text("Update Product", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdateStockDialog(BuildContext context, ProductModel product) {
    final TextEditingController stockController = TextEditingController(text: product.stockQuantity.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Update Stock: ${product.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter the new stock level for this item:"),
            const SizedBox(height: 16),
            _buildSheetTextField("Stock Units", Icons.layers_outlined, stockController, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final stock = int.tryParse(stockController.text) ?? -1;
              if (stock < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid stock level'), backgroundColor: Colors.redAccent),
                );
                return;
              }
              Navigator.pop(context);
              _updateStock(product.id, stock);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38240D)),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete '${product.name}'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(product.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetTextField(String label, IconData icon, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: const Color(0xFF38240D)),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF38240D), width: 1.5),
        ),
      ),
    );
  }
}