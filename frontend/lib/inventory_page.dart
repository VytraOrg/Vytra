import 'package:flutter/material.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean off-white background
      appBar: AppBar(
        title: const Text(
          "Inventory Manager", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF38240D), // Dark Chocolate
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 8,
        itemBuilder: (context, index) {
          // Logic for simulation
          final int stockLevel = index * 5 + 2;
          final bool isLowStock = stockLevel < 10;

          return _buildInventoryCard(context, index, stockLevel, isLowStock);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductSheet(context),
        backgroundColor: const Color(0xFF38240D), // Dark Chocolate
        label: const Text("Add Item", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, int index, int stock, bool isLowStock) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
            color: const Color(0xFF38240D).withValues(alpha: 0.05), // Subtle chocolate tint
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF38240D)),
        ),
        title: Text(
          "Product Item #${index + 1}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF38240D)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Price: ₹${(index + 1) * 20}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            // Stock Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                // Using the theme's Rust/Orange for low stock warning instead of generic red
                color: isLowStock ? const Color(0xFFC05800).withValues(alpha: 0.1) : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$stock Units left",
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$value on Item ${index + 1}")),
            );
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add New Product", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF38240D), letterSpacing: -0.5),
            ),
            const SizedBox(height: 25),
            _buildSheetTextField("Product Name", Icons.edit_note_rounded),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildSheetTextField("Price", Icons.currency_rupee_rounded)),
                const SizedBox(width: 15),
                Expanded(child: _buildSheetTextField("Stock", Icons.layers_outlined)),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 58),
                backgroundColor: const Color(0xFF38240D), // Dark Chocolate
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Add to Inventory", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetTextField(String label, IconData icon) {
    return TextField(
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: const Color(0xFF38240D)), // Dark Chocolate
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