import 'package:flutter/material.dart';

class DistributorInventoryPage extends StatefulWidget {
  const DistributorInventoryPage({super.key});

  @override
  State<DistributorInventoryPage> createState() => _DistributorInventoryPageState();
}

class _DistributorInventoryPageState extends State<DistributorInventoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Stock Control"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (context, index) {
          final items = [{"n": "Basmati Rice", "u": "50kg Bag"}, {"n": "Refined Oil", "u": "12pc Case"}, {"n": "Sugar", "u": "25kg Bag"}];
          return ListTile(
            title: Text(items[index]['n']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Unit: ${items[index]['u']}"),
            trailing: const Icon(Icons.edit_outlined, color: Colors.indigo),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: Colors.indigo[900],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Add Agency Stock", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(labelText: "Product Name")),
            const TextField(decoration: InputDecoration(labelText: "Unit (e.g. Bag/Case)")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Update Stock")),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}