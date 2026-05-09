import 'package:flutter/material.dart';
import 'main.dart'; // To navigate to LoginScreen
import 'register.dart'; // To navigate to RegisterScreen

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light fallback color
      body: Stack(
        children: [
          // 1. THE WAVY BACKGROUND IMAGE
          // NOTE: Make sure to add your image to the assets folder and pubspec.yaml!
          Positioned.fill(
            child: Image.asset(
              'assets/bg_image.jpg', // Make sure this matches your image file name
              fit: BoxFit.cover,
            ),
          ),

          // 2. MAIN TEXT CONTENT
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Welcome Back!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF38240D), // Dark chocolate from your earthy theme
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Enter personal details to your\nemployee account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: const Color(0xFF38240D).withValues(alpha: 0.7),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. THE BOTTOM WHITE BAR (Sign in / Sign up)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 100, // Height of the bottom button bar
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ]
              ),
              child: Row(
                children: [
                  // Left Side: Sign In (Black text)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                          "Sign in",
                          style: TextStyle(
                            color: Color.fromARGB(255, 56, 36, 13), 
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Right Side: Sign Up (Orange/Rust text)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            color: Color.fromARGB(255, 56, 36, 13), // Dark chocolate from your earthy theme
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}