import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/design_system.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../orders/presentation/screens/orders_page.dart';
import '../../../auth/presentation/screens/welcome_screen.dart';
import '../controllers/account_controller.dart';
import 'addresses_page.dart';
import 'wishlist_page.dart';
import 'payment_methods_page.dart';
import 'notifications_page.dart';

class AccountPage extends StatefulWidget {
  final String customerId;
  final UserEntity? user;

  const AccountPage({super.key, required this.customerId, this.user});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountController>().loadStats();
    });
  }

  String get _displayName {
    final currentUser = context.watch<AuthController>().currentUser;
    if (currentUser?.name.isNotEmpty == true) return currentUser!.name;
    if (currentUser?.email.isNotEmpty == true) return currentUser!.email.split('@')[0];
    return 'Customer';
  }

  String get _initials {
    final name = _displayName;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'C';
  }

  @override
  Widget build(BuildContext context) {
    final accountController = context.watch<AccountController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          _buildHeader(accountController),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoCard(),
                const SizedBox(height: AppSpacing.lg),

                _buildSectionTitle('Shopping'),
                _buildMenuTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'My Orders',
                  subtitle: 'Track current & past orders',
                  color: AppColors.freshGreen,
                  delay: 100,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersPage())),
                ),
                _buildMenuTile(
                  icon: Icons.location_on_outlined,
                  title: 'Saved Addresses',
                  subtitle: 'Home, Office & more',
                  color: AppColors.skyBlue,
                  delay: 150,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesPage())),
                ),
                _buildMenuTile(
                  icon: Icons.favorite_border_rounded,
                  title: 'Wishlist',
                  subtitle: 'Items you love',
                  color: AppColors.error,
                  delay: 200,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage())),
                ),

                const SizedBox(height: AppSpacing.md),
                _buildSectionTitle('Account'),
                _buildMenuTile(
                  icon: Icons.payment_rounded,
                  title: 'Payment Methods',
                  subtitle: 'Cards, UPI & Wallets',
                  color: AppColors.primary,
                  delay: 300,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsPage())),
                ),
                _buildMenuTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Manage alerts & updates',
                  color: AppColors.citrusOrange,
                  delay: 350,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
                ),

                const SizedBox(height: AppSpacing.xl),
                _buildLogoutButton(),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AccountController controller) {
    final currentUser = context.watch<AuthController>().currentUser;

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          MediaQuery.of(context).padding.top + AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(AppRadius.xxl),
            bottomRight: Radius.circular(AppRadius.xxl),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: AppSpacing.xl),

            Row(
              children: [
                _buildAvatar(currentUser),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_displayName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(currentUser?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            if (controller.isLoading)
              const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
            else
              Row(
                children: [
                  _buildStatCard('${controller.totalOrders}', 'Orders', Icons.shopping_bag_outlined),
                  _buildStatDivider(),
                  _buildStatCard('₹${controller.totalSpent.toStringAsFixed(0)}', 'Spent', Icons.currency_rupee_rounded),
                  _buildStatDivider(),
                  _buildStatCard('4.8', 'Rating', Icons.star_rounded),
                ],
              ).animate().fadeIn(delay: 350.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() => Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2));

  Widget _buildInfoCard() {
    final currentUser = context.watch<AuthController>().currentUser;
    final phone = currentUser?.phone ?? '';
    final isComplete = phone.isNotEmpty;

    return GestureDetector(
      onTap: () => _showPhoneEditSheet(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isComplete ? AppColors.freshGreen.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Icon(isComplete ? Icons.check_circle_outline_rounded : Icons.person_outline_rounded, color: isComplete ? AppColors.freshGreen : AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isComplete ? 'Profile Complete!' : 'Complete your profile', style: TextStyle(fontWeight: FontWeight.bold, color: isComplete ? AppColors.freshGreen : AppColors.textPrimary)),
                  Text(isComplete ? phone : 'Add phone to get faster delivery', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (!isComplete)
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05);
  }

  void _showPhoneEditSheet(BuildContext context) {
    final authController = context.read<AuthController>();
    // Strip prefix if any for display in editing textfield
    final currentPhone = authController.currentUser?.phone ?? '';
    final digitsOnly = currentPhone.replaceAll('+91 ', '');
    final phoneController = TextEditingController(text: digitsOnly);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.xl),
              topRight: Radius.circular(AppRadius.xl),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Update Phone Number',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter your 10-digit mobile number for faster delivery updates.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  maxLength: 10,
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                    prefixText: '+91 ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                    hintText: 'Enter phone number',
                    hintStyle: const TextStyle(fontWeight: FontWeight.normal, letterSpacing: 0, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide.none,
                    ),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Please enter a valid 10-digit number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await authController.updatePhone('+91 ${phoneController.text}');
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Phone number updated successfully!'),
                            backgroundColor: AppColors.freshGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                  child: const Text('Save Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, left: 4),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required String subtitle, required Color color, int delay = 0, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.md)), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        onTap: onTap,
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.05);
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        await context.read<AuthController>().logout();
        if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => WelcomeScreen()), (route) => false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.error.withOpacity(0.2))),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 550.ms);
  }

  Widget _buildAvatar(UserEntity? user) {
    final imageUrl = user?.imageUrl ?? '';
    final initials = _initials;

    Widget avatarImage;
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:image') || !imageUrl.startsWith('http')) {
        try {
          final bytes = base64Decode(imageUrl.split(',').last);
          avatarImage = CircleAvatar(
            radius: 36,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (e) {
          avatarImage = CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.accent,
            child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          );
        }
      } else {
        avatarImage = CircleAvatar(
          radius: 36,
          backgroundImage: NetworkImage(imageUrl),
        );
      }
    } else {
      avatarImage = CircleAvatar(
        radius: 36,
        backgroundColor: AppColors.accent,
        child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
      );
    }

    return GestureDetector(
      onTap: _showAvatarOptions,
      child: Stack(
        children: [
          avatarImage.animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.easeOutBack),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppColors.primary,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions() {
    final user = context.read<AuthController>().currentUser;
    final hasPhoto = user?.imageUrl.isNotEmpty == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Profile Picture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Upload Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfilePicture();
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: AppColors.error),
                  title: const Text('Remove Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    await context.read<AuthController>().updateAvatar('');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile picture removed.'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickProfilePicture() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/png;base64,$base64String';

        if (mounted) {
          await context.read<AuthController>().updateAvatar(dataUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: AppColors.freshGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
