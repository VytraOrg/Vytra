import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class CartPage extends StatefulWidget {
  final String customerId;

  const CartPage({super.key, required this.customerId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<CartItem>> _cartFuture;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _cartFuture = _fetchCart();
  }

  Future<List<CartItem>> _fetchCart() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/api/cart/${widget.customerId}'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load cart (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (decoded['items'] as List<dynamic>? ?? [])
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return items;
  }

  Future<void> _removeFromCart(String productId) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl/api/cart/${widget.customerId}/items/$productId'),
    );

    if (!mounted) {
      return;
    }

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove item (${response.statusCode})')),
      );
      return;
    }

    setState(() {
      _cartFuture = _fetchCart();
    });
  }

  Future<void> _placeOrder() async {
    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'customerId': widget.customerId}),
      );

      if (!mounted) {
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 201) {
        final error = (body['error'] ?? 'Could not place order').toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 12),
                const Text(
                  'Order placed successfully',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order ID: ${(body['id'] ?? '').toString()}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _cartFuture = _fetchCart();
                    });
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place order: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  double _subtotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: FutureBuilder<List<CartItem>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load cart: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          final subtotal = _subtotal(items);

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final refreshed = _fetchCart();
                    setState(() {
                      _cartFuture = refreshed;
                    });
                    await refreshed;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        title: Text(item.name),
                        subtitle: Text('Qty: ${item.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rs ${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            IconButton(
                              tooltip: 'Remove item',
                              onPressed: () => _removeFromCart(item.productId),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('Rs ${subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isPlacingOrder ? null : _placeOrder,
                        child: _isPlacingOrder
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Confirm & Place Order'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CartItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final quantity = int.tryParse((json['quantity'] ?? '1').toString()) ?? 1;
    final price = double.tryParse((json['price'] ?? '0').toString()) ?? 0;

    return CartItem(
      productId: (json['productId'] ?? '').toString(),
      name: (json['name'] ?? 'Product').toString(),
      price: price,
      quantity: quantity < 1 ? 1 : quantity,
    );
  }
}
