import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Ken Burns effect
          Positioned.fill(
            child: Image.asset(
              'assets/bg_image.jpg',
              fit: BoxFit.cover,
            ).animate().scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(1.0, 1.0),
                  duration: 10.seconds,
                  curve: Curves.linear,
                ),
          ),

          // Dark Gradient Overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 3),
                  
                  // App Branding
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Image.asset(
                      'assets/logo_transparent.png',
                      width: 40,
                      height: 40,
                      color: AppColors.primary,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2),

                  const SizedBox(height: AppSpacing.lg),

                  // Headline
                  Text(
                    "Shop Local.\nThink Premium.",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          height: 1.1,
                        ),
                  ).animate().fadeIn(delay: 200.ms, duration: 800.ms).slideX(begin: -0.1),

                  const SizedBox(height: AppSpacing.md),

                  // Subtitle
                  Text(
                    "Experience the best neighborhood products delivered with care and elegance.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                  ).animate().fadeIn(delay: 400.ms, duration: 800.ms),

                  const Spacer(flex: 2),

                  // Action Buttons
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: const Text("Get Started"),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: const Text(
                          "Create an Account",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms, duration: 800.ms).slideY(begin: 0.1),
                  
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}