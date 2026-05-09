import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean off-white background
      appBar: AppBar(
        title: const Text(
          "Your Cart", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF38240D), // Dark Chocolate
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // 1. SCROLLABLE CART ITEMS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 3,
              itemBuilder: (context, index) {
                List<String> items = ["Organic Rice", "Fresh Milk", "Whole Wheat Atta"];
                List<int> prices = [250, 60, 180];
                
                return _buildCartItem(context, items[index], prices[index]);
              },
            ),
          ),
          
          // 2. CHECKOUT SUMMARY SECTION
          _buildCheckoutSection(context),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, String title, int price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          // Item Leading
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF38240D).withValues(alpha: 0.05), // Subtle chocolate tint
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF38240D)), // Dark Chocolate
          ),
          const SizedBox(width: 16),
          
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF38240D))),
                const SizedBox(height: 4),
                Text("₹$price", style: const TextStyle(color: Color(0xFF38240D), fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          
          // Quantity Adjuster
          Row(
            children: [
              _buildQtyBtn(Icons.remove),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text("1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF38240D))),
              ),
              _buildQtyBtn(Icons.add),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Icon(icon, size: 16, color: const Color(0xFF38240D)),
    );
  }

  Widget _buildCheckoutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Subtotal", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                Text("₹490", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF38240D))),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Delivery Fee", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                Text("FREE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18.0),
              child: Divider(color: Color(0xFFF8F9FA), thickness: 1.5),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Amount", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF38240D))),
                Text("₹490", 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF38240D))), // Dark Chocolate
              ],
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: const Color(0xFF38240D), // Dark Chocolate
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed: () => _showOrderSuccess(context),
              child: const Text("Confirm & Place Order", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderSuccess(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 24),
            const Text("Order Successful!", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF38240D), letterSpacing: -0.5)),
            const SizedBox(height: 12),
            Text(
              "Your order has been sent to the shopkeeper. You'll be notified once it's out for delivery.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontSize: 15),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 58),
                backgroundColor: const Color(0xFF38240D), // Dark Chocolate
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context); // Close sheet
                Navigator.pop(context); // Go back
              },
              child: const Text("Track My Order", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}