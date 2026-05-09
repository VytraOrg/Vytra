import 'package:flutter/material.dart';

class DistributorOrdersPage extends StatelessWidget {
  const DistributorOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Incoming Shop Orders"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (context, index) {
          final shops = ["Maa Tara Variety", "Lokenath Dash", "Joy Guru Stores"];
          final owners = ["Sapan Majhi", "Bikash Paul", "Arjun Das"];
          return _buildOrderCard(context, shops[index], owners[index], "₹${(index + 1) * 2400}");
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, String shop, String owner, String val) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(shop, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                Text("Owner: $owner", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
              Text(val, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 30),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () {}, child: const Text("View Items"))),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () {}, // Print Bill Logic
                icon: const Icon(Icons.print_outlined, color: Colors.indigo),
                style: IconButton.styleFrom(backgroundColor: Colors.indigo.shade50),
              ),
            ],
          )
        ],
      ),
    );
  }
}