import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../shop/data/shop_model.dart';
import 'complete_verification_screen.dart';
import 'verification_under_review_screen.dart';
import 'shopkeeper_dash.dart';

class ShopkeeperRouteHandler extends StatefulWidget {
  const ShopkeeperRouteHandler({super.key});

  @override
  State<ShopkeeperRouteHandler> createState() => _ShopkeeperRouteHandlerState();
}

class _ShopkeeperRouteHandlerState extends State<ShopkeeperRouteHandler> {
  bool _isLoading = true;
  String? _errorMessage;
  ShopModel? _shop;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.get('/shops/my');
      final shop = ShopModel.fromJson(Map<String, dynamic>.from(response));
      if (mounted) {
        setState(() {
          _shop = shop;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // AppError indicating Resource not found means no shop exists yet
        if (e.toString().contains('Resource not found') || e.toString().contains('404')) {
          setState(() {
            _shop = null;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.indigo),
              SizedBox(height: 16),
              Text('Checking profile verification status...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile details:\n$_errorMessage', 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(120, 48),
                  ),
                  onPressed: _checkStatus,
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        ),
      );
    }

    final status = _shop?.verificationStatus;

    if (_shop == null || status == 'Incomplete' || status == 'Unverified') {
      return const CompleteVerificationScreen();
    }

    if (status == 'Pending' || status == 'Under Review') {
      return VerificationUnderReviewScreen(status: status!);
    }

    if (status == 'Changes Requested') {
      return CompleteVerificationScreen(
        existingShop: _shop,
        changesNotes: _shop?.verificationRejectedNotes ?? _shop?.verificationNotes,
      );
    }

    if (status == 'Rejected') {
      return CompleteVerificationScreen(
        existingShop: _shop,
        rejectionReason: _shop?.verificationRejectedReason,
        rejectionNotes: _shop?.verificationRejectedNotes,
      );
    }

    if (status == 'Verified') {
      return const ShopkeeperDash();
    }

    // Default to verification form
    return const CompleteVerificationScreen();
  }
}
