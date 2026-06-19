import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () => authController.logout(),
            tooltip: 'Logout',
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.soft,
                ),
                child: const Icon(
                  Icons.watch_later_outlined, 
                  color: AppColors.primary, 
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
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Your application has been submitted successfully. Our team will review your documents and update your verification status within 24 hours.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15, 
                  color: AppColors.textSecondary, 
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 58),
                  backgroundColor: AppColors.primary,
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
                    color: AppColors.textSecondary, 
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
