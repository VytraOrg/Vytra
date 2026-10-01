import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../auth_controller.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  int _currentStep = 0; // 0: Email, 1: OTP, 2: New Password
  bool _isLoading = false;
  String? _errorMessage;
  int _resendCooldown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendCooldown = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  // STEP 1: Submit Email to get OTP
  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authController = Provider.of<AuthController>(context, listen: false);
    final error = await authController.sendPasswordResetOtp(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      _startResendTimer();
      setState(() {
        _currentStep = 1;
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to $email'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() => _errorMessage = error);
    }
  }

  // STEP 2: Verify OTP
  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authController = Provider.of<AuthController>(context, listen: false);
    final error = await authController.verifyResetOtp(_emailController.text.trim(), otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      setState(() {
        _currentStep = 2;
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = error);
    }
  }

  // STEP 3: Reset Password
  Future<void> _handleResetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authController = Provider.of<AuthController>(context, listen: false);
    final error = await authController.resetPassword(
      _emailController.text.trim(),
      _otpController.text.trim(),
      newPass,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 8),
              Text('Success!'),
            ],
          ),
          content: const Text(
            'Your password has been reset successfully. You can now login with your new password.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Return to Login
              },
              child: const Text('Back to Login'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _errorMessage = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  // Top navigation
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () {
                      if (_currentStep > 0) {
                        setState(() {
                          _currentStep--;
                          _errorMessage = null;
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _currentStep == 0
                                ? Icons.lock_reset_rounded
                                : _currentStep == 1
                                    ? Icons.mark_email_read_rounded
                                    : Icons.verified_user_rounded,
                            size: 42,
                            color: Colors.white,
                          ),
                        ).animate().scale(duration: 400.ms),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _currentStep == 0
                              ? "Forgot Password"
                              : _currentStep == 1
                                  ? "Verify Code"
                                  : "New Password",
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ).animate().fadeIn(),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _currentStep == 0
                              ? "Enter your email to receive a recovery code"
                              : _currentStep == 1
                                  ? "Enter the 6-digit code sent to your email"
                                  : "Create a strong new password",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ).animate().fadeIn(delay: 150.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Step Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepDot(0, "Email"),
                      _buildStepLine(0),
                      _buildStepDot(1, "OTP"),
                      _buildStepLine(1),
                      _buildStepDot(2, "Reset"),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Form Card
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
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Animated Step View
                        if (_currentStep == 0) _buildStepEmail(),
                        if (_currentStep == 1) _buildStepOtp(),
                        if (_currentStep == 2) _buildStepNewPassword(),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white24,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: AppColors.accent, width: 2) : null,
          ),
          child: Center(
            child: isActive && _currentStep > step
                ? const Icon(Icons.check, size: 16, color: AppColors.primary)
                : Text(
                    "${step + 1}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.primary : Colors.white60,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isDone = _currentStep > afterStep;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      color: isDone ? Colors.white : Colors.white24,
    );
  }

  // STEP 1 WIDGET
  Widget _buildStepEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: "Registered Email",
          icon: Icons.alternate_email_rounded,
          hint: "your@email.com",
          controller: _emailController,
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendOtp,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text("Send Verification Code"),
          ),
        ),
      ],
    );
  }

  // STEP 2 WIDGET
  Widget _buildStepOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter the 6-digit code sent to ${_emailController.text}",
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
            color: AppColors.primary,
          ),
          decoration: InputDecoration(
            counterText: "",
            hintText: "••••••",
            hintStyle: TextStyle(
              fontSize: 26,
              letterSpacing: 8,
              color: Colors.grey.shade400,
            ),
            prefixIcon: const Icon(Icons.password_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: _resendCooldown > 0
              ? Text(
                  "Resend code in ${_resendCooldown}s",
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                )
              : TextButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  child: const Text(
                    "Resend Code",
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text("Verify Code"),
          ),
        ),
      ],
    );
  }

  // STEP 3 WIDGET
  Widget _buildStepNewPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: "New Password",
          icon: Icons.lock_outline_rounded,
          hint: "••••••••",
          isPassword: true,
          controller: _newPasswordController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: "Confirm New Password",
          icon: Icons.lock_rounded,
          hint: "••••••••",
          isPassword: true,
          controller: _confirmPasswordController,
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text("Update Password"),
          ),
        ),
      ],
    );
  }
}
