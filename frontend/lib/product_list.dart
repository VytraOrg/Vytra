import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cart_page.dart';
import 'api_config.dart';

class ProductList extends StatefulWidget {
  final String shopName;
  final String customerId;

  const ProductList({
    super.key,
    required this.shopName,
    required this.customerId,
  });

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  late Future<List<ProductItem>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<ProductItem>> _fetchProducts() async {
    final uri = Uri.parse('$apiBaseUrl/api/products').replace(
      queryParameters: {'shop': widget.shopName},
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load products (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => ProductItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _addToCart(ProductItem product) async {
    final uri = Uri.parse('$apiBaseUrl/api/cart/${widget.customerId}/items');
    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'productId': product.id, 'quantity': 1}),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add item to cart: $e')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} added to cart')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not add item to cart (${response.statusCode})')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.shopName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Glass-style Cart Button
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.indigo),
              style: IconButton.styleFrom(
                backgroundColor: Colors.indigo.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Chips (Startup UX: Quick Filtering)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildCategoryChip("All Items", true),
                _buildCategoryChip("Popular", false),
                _buildCategoryChip("Discounts", false),
                _buildCategoryChip("New Arrivals", false),
              ],
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<ProductItem>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final message = snapshot.error?.toString() ?? 'unknown error';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load products: $message',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  );
                }

                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Center(
                    child: Text('No products found for this shop'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final refreshed = _fetchProducts();
                    setState(() {
                      _productsFuture = refreshed;
                    });
                    await refreshed;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: products.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      return _buildProductItem(context, products[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.indigo : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, ProductItem product) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Product Placeholder Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.fastfood_rounded, color: Colors.indigo, size: 30),
            ),
            const SizedBox(width: 15),
            
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.description} • ${product.unit}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 18, 
                      color: Colors.indigo
                    ),
                  ),
                ],
              ),
            ),
            
            // Add Button
            ElevatedButton(
              onPressed: () => _addToCart(product),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 15),
              ),
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductItem {
  final String id;
  final String name;
  final String description;
  final String unit;
  final double price;

  ProductItem({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.price,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unnamed Product').toString(),
      description: (json['description'] ?? 'No description').toString(),
      unit: (json['unit'] ?? '1 pc').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}