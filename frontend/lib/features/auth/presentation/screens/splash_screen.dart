import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shopkeeper/presentation/screens/shopkeeper_route_handler.dart';
import '../../domain/repositories/i_auth_repository.dart';
import 'welcome_screen.dart';
import '../../../shop/presentation/screens/customer_home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() {
    Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;

      final authRepo = context.read<IAuthRepository>();
      final user = authRepo.getCachedUser();

      Widget nextScreen;
      if (user != null) {
        if (user.role == 'Shopkeeper') {
          nextScreen = const ShopkeeperRouteHandler();
        } else {
          nextScreen = CustomerHome(customerId: user.id);
        }
      } else {
        nextScreen = const WelcomeScreen();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // The exact terracotta/clay background color from the user's mockup
    const Color backgroundColor = Color(0xFFB46D4D);
    // The cream/off-white color matching the logo symbol
    const Color creamColor = Color(0xFFF9EFE0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Logo & Typography
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon Logo Symbol
                  Image.asset(
                    'assets/logo_transparent.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1.0, 1.0),
                        duration: 800.ms,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: 24),
                  
                  // App Name
                  Text(
                    'VYTRA',
                    style: GoogleFonts.outfit(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.0,
                      color: creamColor,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 800.ms)
                      .slideY(begin: 0.15, end: 0.0, curve: Curves.easeOut),
                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'Local Commerce, Simplified.',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                      color: creamColor.withOpacity(0.85),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 800.ms)
                      .slideY(begin: 0.15, end: 0.0, curve: Curves.easeOut),
                ],
              ),
            ),

            // Loading Indicator at the Bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      creamColor.withOpacity(0.5),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 600.ms),
            ),
          ],
        ),
      ),
    );
  }
}
