import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../widgets/auth_text_field.dart';
import '../auth_controller.dart';
import '../../../shop/presentation/screens/customer_home.dart';
import '../../../shopkeeper/presentation/screens/shopkeeper_route_handler.dart';
import '../../../distributor/presentation/screens/distributor_dash.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String selectedRole = 'Customer';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _businessNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerAccount(AuthController authController) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final businessName = _businessNameController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, email and password are required')),
      );
      return;
    }

    final success = await authController.register({
      'name': name,
      'email': email,
      'password': password,
      'role': selectedRole,
      'businessName': selectedRole == 'Customer' ? '' : businessName,
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome aboard!'), backgroundColor: AppColors.success),
      );
      
      if (selectedRole == 'Customer') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerHome(customerId: authController.currentUser!.id),
          ),
          (route) => false,
        );
      } else if (selectedRole == 'Shopkeeper') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ShopkeeperRouteHandler()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DistributorDash()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authController.error ?? 'Registration failed'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                boxShadow: AppShadows.premium,
              ),
              child: Column(
                children: [
                  _buildRoleSelector(),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: "Full Name",
                    icon: Icons.person_outline_rounded,
                    hint: "John Doe",
                    controller: _nameController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: "Email",
                    icon: Icons.alternate_email_rounded,
                    hint: "john@example.com",
                    controller: _emailController,
                  ),
                  if (selectedRole != 'Customer') ...[
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: selectedRole == 'Shopkeeper' ? "Shop Name" : "Distributor Name",
                      icon: Icons.business_rounded,
                      hint: "Enter business name",
                      controller: _businessNameController,
                    ),
                  ],
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
                    onPressed: authController.isLoading ? null : () => _registerAccount(authController),
                    child: authController.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Create Account"),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Already have an account? Login", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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
