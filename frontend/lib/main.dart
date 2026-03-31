import 'register.dart';
import 'customer_home.dart';
import 'shopkeeper_dash.dart';
import 'api_config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const LocalCommerceApp());
}

class LocalCommerceApp extends StatelessWidget {
  const LocalCommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Local Commerce',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'Customer';
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkServer() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiBaseUrl)).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server Response: ${response.body}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot connect to $apiBaseUrl. Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final loginUrl = '$apiBaseUrl/api/auth/login';

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) {
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        final error = (body['error'] ?? 'Login failed').toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      final user = (body['user'] as Map<String, dynamic>? ?? {});
      final role = (user['role'] ?? '').toString();
      if (role != selectedRole) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This account is registered as $role. Please select the correct role.')),
        );
        return;
      }

      if (selectedRole == 'Customer') {
        final customerId = (user['customerId'] ?? '').toString();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CustomerHome(customerId: customerId)),
        );
      } else if (selectedRole == 'Shopkeeper') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopkeeperDash()));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed to $loginUrl\nError: $e'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(label: 'Retry', onPressed: _handleLogin),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          _buildHeaderBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildBranding(),
                  const SizedBox(height: 40),
                  _buildLoginCard(context),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _checkServer,
                    icon: Icon(Icons.lan_outlined, color: Colors.indigo.shade600, size: 20),
                    label: Text(
                      "Troubleshoot Connection",
                      style: TextStyle(
                        color: Colors.indigo.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.storefront_outlined,
              size: 38,
              color: Colors.indigo.shade700,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          "Local Commerce",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Connecting you to your neighborhood",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Login to your account",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            "Select your role and enter credentials",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          _buildRoleDropdown(),
          const SizedBox(height: 22),
          _buildTextField(
            label: "Email Address",
            icon: Icons.email_outlined,
            hint: "example@mail.com",
            controller: _emailController,
          ),
          const SizedBox(height: 22),
          _buildTextField(
            label: "Password",
            icon: Icons.lock_outline,
            hint: "••••••••",
            isPassword: true,
            controller: _passwordController,
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.indigo.shade500],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.shade700.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(
                      "Login as $selectedRole",
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                  child: Text(
                    "Register here",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo.shade700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedRole,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          icon: Icon(Icons.expand_more_outlined, color: Colors.indigo.shade600),
          onChanged: (value) => setState(() => selectedRole = value!),
          items: ['Customer', 'Shopkeeper', 'Distributor']
              .map((role) => DropdownMenuItem(
                    value: role,
                    child: Row(
                      children: [
                        Icon(
                          role == 'Customer'
                              ? Icons.shopping_bag_outlined
                              : role == 'Shopkeeper'
                                  ? Icons.store_outlined
                                  : Icons.local_shipping_outlined,
                          color: Colors.indigo.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          role,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscureText : false,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.indigo.shade600, size: 22),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.indigo.shade600,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.indigo.shade600, width: 2.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
