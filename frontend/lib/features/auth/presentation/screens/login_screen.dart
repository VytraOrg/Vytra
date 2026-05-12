import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../../../shop/presentation/screens/customer_home.dart';
import '../../../shopkeeper/presentation/screens/shopkeeper_dash.dart';
import '../../../distributor/presentation/screens/distributor_dash.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String selectedRole = 'Customer';

  void _handleLogin(AuthController authController) async {
    final success = await authController.login(
      _emailController.text,
      _passwordController.text,
      selectedRole,
    );

    if (!mounted) return;

    if (success) {
      if (selectedRole == 'Customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerHome(customerId: authController.currentUser!.id),
          ),
        );
      } else if (selectedRole == 'Shopkeeper') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ShopkeeperDash()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DistributorDash()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authController.error ?? 'Login Failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  // Logo/Icon
                  const Icon(Icons.storefront_rounded, size: 80, color: Colors.white)
                      .animate().fadeIn().scale(),
                  
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    "Welcome Back",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      boxShadow: AppShadows.premium,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Login",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        
                        _buildRoleSelector(),
                        const SizedBox(height: AppSpacing.lg),
                        
                        AppTextField(
                          label: "Email Address",
                          icon: Icons.alternate_email_rounded,
                          hint: "your@email.com",
                          controller: _emailController,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        AppTextField(
                          label: "Password",
                          icon: Icons.lock_outline_rounded,
                          hint: "••••••••",
                          isPassword: true,
                          controller: _passwordController,
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        ElevatedButton(
                          onPressed: authController.isLoading ? null : () => _handleLogin(authController),
                          child: authController.isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text("Sign In as $selectedRole"),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("New here?", style: TextStyle(color: Colors.white70)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text("Create Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          _buildRoleOption('Customer', Icons.shopping_bag_outlined),
          _buildRoleOption('Shopkeeper', Icons.store_outlined),
          _buildRoleOption('Distributor', Icons.local_shipping_outlined),
        ],
      ),
    );
  }

  Widget _buildRoleOption(String role, IconData icon) {
    final isSelected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = role),
        child: AnimatedContainer(
          duration: 300.ms,
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.black54,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                role,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
