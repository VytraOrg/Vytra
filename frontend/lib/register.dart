import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String selectedRole = 'Customer';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: 'I am a...', border: OutlineInputBorder()),
              items: ['Customer', 'Shopkeeper', 'Distributor']
                  .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                  .toList(),
              onChanged: (value) => setState(() => selectedRole = value!),
            ),
            const SizedBox(height: 15),
            const TextField(decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            const TextField(decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            
            // Show Shop Name only if they aren't a basic Customer
            if (selectedRole != 'Customer') ...[
              const SizedBox(height: 15),
              TextField(decoration: InputDecoration(
                labelText: selectedRole == 'Shopkeeper' ? 'Shop Name' : 'Distributor Name', 
                border: const OutlineInputBorder())),
            ],
            
            const SizedBox(height: 15),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
            const SizedBox(height: 30),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
              onPressed: () {
                // Future: Integrate with Database (Firebase/Supabase)
              },
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}