import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/auth_controller.dart';
import 'shopkeeper_route_handler.dart';

class VerificationUnderReviewScreen extends StatelessWidget {
  final String status;

  const VerificationUnderReviewScreen({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.grey),
            onPressed: () => authController.logout(),
            tooltip: 'Logout',
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.watch_later_outlined, 
                  color: Colors.indigo.shade800, 
                  size: 72,
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                "Application Under Review",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Your application has been submitted successfully. Our team will review your documents and update your verification status within 24 hours.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15, 
                  color: Colors.grey, 
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 58),
                  backgroundColor: Colors.indigo.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopkeeperRouteHandler()),
                    (route) => false,
                  );
                },
                label: const Text(
                  "Check Status", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => authController.logout(),
                child: const Text(
                  "Sign Out",
                  style: TextStyle(
                    color: Colors.grey, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
