import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/design_system.dart';
import '../../../shop/data/shop_model.dart';
import '../../../auth/presentation/auth_controller.dart';
import 'shopkeeper_route_handler.dart';
import 'location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CompleteVerificationScreen extends StatefulWidget {
  final ShopModel? existingShop;
  final String? changesNotes;
  final String? rejectionReason;
  final String? rejectionNotes;

  const CompleteVerificationScreen({
    super.key,
    this.existingShop,
    this.changesNotes,
    this.rejectionReason,
    this.rejectionNotes,
  });

  @override
  State<CompleteVerificationScreen> createState() => _CompleteVerificationScreenState();
}

class _CompleteVerificationScreenState extends State<CompleteVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Owner Info
  late TextEditingController _ownerNameController;
  late TextEditingController _ownerPhoneController;

  // Shop Info
  late TextEditingController _shopNameController;
  late TextEditingController _shopDescController;
  String _selectedCategory = 'Grocery';

  // Location Info
  late TextEditingController _addressController;
  late TextEditingController _districtController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  
  // GPS Coordinates
  double? _latitude;
  double? _longitude;

  // Business verification numbers
  late TextEditingController _gstNumberController;
  late TextEditingController _tradeLicenseNumberController;

  // Picked Documents
  Uint8List? _gstCertificateBytes;
  String? _gstCertificateFileName;

  Uint8List? _tradeLicenseBytes;
  String? _tradeLicenseFileName;

  Uint8List? _shopImageBytes;
  String? _shopImageFileName;

  bool _isUploading = false;

  final List<String> _categories = [
    'Grocery',
    'Pharmacy',
    'Electronics',
    'Fashion',
    'Home Decor',
    'Stationery',
    'Others'
  ];

  @override
  void initState() {
    super.initState();
    
    final shop = widget.existingShop;
    final cachedUser = CacheManager.getUser();

    // Prefill name/phone from shop or cached user
    _ownerNameController = TextEditingController(text: shop?.ownerName ?? cachedUser?['name'] ?? '');
    _ownerPhoneController = TextEditingController(text: shop?.ownerPhone ?? cachedUser?['phone'] ?? '');

    // Prefill shop details
    _shopNameController = TextEditingController(text: shop?.name ?? cachedUser?['businessName'] ?? '');
    _shopDescController = TextEditingController(text: shop?.description ?? '');
    
    if (shop?.category != null && _categories.contains(shop!.category)) {
      _selectedCategory = shop.category;
    }

    // Prefill location
    _addressController = TextEditingController(text: shop?.address ?? '');
    _districtController = TextEditingController(text: shop?.district ?? '');
    _stateController = TextEditingController(text: shop?.state ?? '');
    _pincodeController = TextEditingController(text: shop?.pincode ?? '');
    _latitude = shop?.latitude;
    _longitude = shop?.longitude;

    // Prefill doc numbers
    _gstNumberController = TextEditingController(text: shop?.gstNumber ?? '');
    _tradeLicenseNumberController = TextEditingController(text: shop?.tradeLicenseNumber ?? '');

    // Setup filenames if url exists to show placeholder uploaded status
    if (shop?.gstCertificateUrl != null) {
      _gstCertificateFileName = 'gst_certificate_previously_uploaded.pdf';
    }
    if (shop?.tradeLicenseUrl != null) {
      _tradeLicenseFileName = 'trade_license_previously_uploaded.pdf';
    }
    if (shop?.imageUrl != null) {
      _shopImageFileName = 'shop_image_previously_uploaded.jpg';
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _shopNameController.dispose();
    _shopDescController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstNumberController.dispose();
    _tradeLicenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          if (documentType == 'gst') {
            _gstCertificateBytes = result.files.single.bytes;
            _gstCertificateFileName = result.files.single.name;
          } else if (documentType == 'license') {
            _tradeLicenseBytes = result.files.single.bytes;
            _tradeLicenseFileName = result.files.single.name;
          } else if (documentType == 'shopImage') {
            _shopImageBytes = result.files.single.bytes;
            _shopImageFileName = result.files.single.name;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    // Strict validation: Require file uploads (new or previously existing)
    final hasGst = _gstCertificateBytes != null || widget.existingShop?.gstCertificateUrl != null;
    final hasLicense = _tradeLicenseBytes != null || widget.existingShop?.tradeLicenseUrl != null;
    final hasShopImg = _shopImageBytes != null || widget.existingShop?.imageUrl != null;

    if (!hasGst || !hasLicense || !hasShopImg) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload all 3 required verification documents/images.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final user = CacheManager.getUser();
      final token = user?['accessToken'] ?? user?['access_token'];

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/shops/verify'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add files if newly picked
      if (_gstCertificateBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'gstCertificate',
            _gstCertificateBytes!,
            filename: _gstCertificateFileName,
          ),
        );
      } else {
        // Submit mock empty file if keeping previous (handled gracefully on backend by retaining url)
        request.files.add(
          http.MultipartFile.fromBytes(
            'gstCertificate',
            Uint8List(0),
            filename: 'keep_existing',
          ),
        );
      }

      if (_tradeLicenseBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'tradeLicense',
            _tradeLicenseBytes!,
            filename: _tradeLicenseFileName,
          ),
        );
      } else {
        request.files.add(
          http.MultipartFile.fromBytes(
            'tradeLicense',
            Uint8List(0),
            filename: 'keep_existing',
          ),
        );
      }

      if (_shopImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'shopImage',
            _shopImageBytes!,
            filename: _shopImageFileName,
          ),
        );
      } else {
        request.files.add(
          http.MultipartFile.fromBytes(
            'shopImage',
            Uint8List(0),
            filename: 'keep_existing',
          ),
        );
      }

      // Add text fields
      request.fields['ownerName'] = _ownerNameController.text.trim();
      request.fields['ownerPhone'] = _ownerPhoneController.text.trim();
      request.fields['name'] = _shopNameController.text.trim();
      request.fields['category'] = _selectedCategory;
      request.fields['description'] = _shopDescController.text.trim();
      request.fields['address'] = _addressController.text.trim();
      request.fields['district'] = _districtController.text.trim();
      request.fields['state'] = _stateController.text.trim();
      request.fields['pincode'] = _pincodeController.text.trim();
      request.fields['gstNumber'] = _gstNumberController.text.trim().toUpperCase();
      request.fields['tradeLicenseNumber'] = _tradeLicenseNumberController.text.trim();
      
      if (_latitude != null) {
        request.fields['latitude'] = _latitude!.toString();
      }
      if (_longitude != null) {
        request.fields['longitude'] = _longitude!.toString();
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification profile submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        if (mounted) {
          // Push to Route Handler to reload and lock screens
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ShopkeeperRouteHandler()),
            (route) => false,
          );
        }
      } else {
        String message = 'Failed to submit verification profile';
        try {
          final Map<String, dynamic> decoded = jsonDecode(response.body);
          message = decoded['message'] ?? message;
        } catch (_) {}
        throw Exception(message);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Business Onboarding", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () => authController.logout(),
            tooltip: 'Logout',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.changesNotes != null) _buildAdminFeedbackBanner("Changes Requested", widget.changesNotes!, Colors.amber.shade800, Colors.amber.shade50, Colors.amber.shade200),
              if (widget.rejectionReason != null) _buildAdminFeedbackBanner("Verification Rejected", "${widget.rejectionReason}\n${widget.rejectionNotes ?? ''}", Colors.red.shade900, Colors.red.shade50, Colors.red.shade200),
              
              _buildSectionCard(
                title: "1. Owner Information",
                icon: Icons.person_rounded,
                children: [
                  TextFormField(
                    controller: _ownerNameController,
                    decoration: const InputDecoration(labelText: "Full Name", hintText: "John Doe"),
                    validator: (v) => v == null || v.trim().isEmpty ? "Name is required" : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _ownerPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Phone Number", hintText: "9876543210"),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Phone number is required";
                      if (v.trim().length < 10) return "Enter a valid 10-15 digit phone number";
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              
              _buildSectionCard(
                title: "2. Shop Information",
                icon: Icons.storefront_rounded,
                children: [
                  TextFormField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(labelText: "Shop / Business Name", hintText: "Fresh Mart"),
                    validator: (v) => v == null || v.trim().isEmpty ? "Shop name is required" : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val ?? 'Grocery'),
                    decoration: const InputDecoration(labelText: "Shop Category"),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _shopDescController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Business Description", 
                      hintText: "Describe what your business sells and provides..."
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? "Description is required" : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              
              _buildSectionCard(
                title: "3. Location Information",
                icon: Icons.location_on_rounded,
                children: [
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: "Full Physical Address", hintText: "12, M.G. Road, Flat 3B"),
                    validator: (v) => v == null || v.trim().isEmpty ? "Address is required" : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _districtController,
                          decoration: const InputDecoration(labelText: "District", hintText: "Kolkata"),
                          validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(labelText: "State", hintText: "West Bengal"),
                          validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Pincode", hintText: "700001"),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Pincode is required";
                      if (v.trim().length != 6 || int.tryParse(v) == null) return "Must be a 6 digit number";
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Map Location (Coordinates)",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _latitude != null && _longitude != null
                                  ? "Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}"
                                  : "No location selected on map",
                              style: TextStyle(
                                fontSize: 12,
                                color: _latitude != null ? Colors.green.shade800 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
                          ),
                        ),
                        icon: const Icon(Icons.map_rounded, size: 16),
                        label: Text(_latitude != null ? "Change" : "Select"),
                        onPressed: () async {
                          final LatLng? result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocationPickerScreen(
                                initialLatitude: _latitude,
                                initialLongitude: _longitude,
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _latitude = result.latitude;
                              _longitude = result.longitude;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              
              _buildSectionCard(
                title: "4. Business Credentials & Uploads",
                icon: Icons.verified_rounded,
                children: [
                  TextFormField(
                    controller: _gstNumberController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: "GST Number", hintText: "19AAAAA0000A1Z5"),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "GST Number is required";
                      final clean = v.trim().toUpperCase();
                      if (clean.length != 15) return "GST must be exactly 15 characters";
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildUploadItem(
                    title: "GST Certificate",
                    fileName: _gstCertificateFileName,
                    onTap: () => _pickFile('gst'),
                  ),
                  const Divider(height: AppSpacing.xl),
                  TextFormField(
                    controller: _tradeLicenseNumberController,
                    decoration: const InputDecoration(labelText: "Trade License Number", hintText: "TL-182736"),
                    validator: (v) => v == null || v.trim().isEmpty ? "Trade License number is required" : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildUploadItem(
                    title: "Trade License Document",
                    fileName: _tradeLicenseFileName,
                    onTap: () => _pickFile('license'),
                  ),
                  const Divider(height: AppSpacing.xl),
                  _buildUploadItem(
                    title: "Shop Front Photo / Banner Image",
                    fileName: _shopImageFileName,
                    onTap: () => _pickFile('shopImage'),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 58),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: _isUploading ? null : _submitData,
                child: _isUploading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        "Submit Profile for Verification",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1.2),
          ...children,
        ],
      ),
    );
  }

  Widget _buildUploadItem({
    required String title,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    final hasFile = fileName != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasFile ? Colors.green.withOpacity(0.03) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? Colors.green.shade200 : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
              color: hasFile ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    hasFile
                        ? (fileName.length > 30 ? "...${fileName.substring(fileName.length - 27)}" : fileName)
                        : "Format: JPG, PNG, PDF (Max 5MB)",
                    style: TextStyle(color: hasFile ? Colors.green.shade800 : Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              hasFile ? "Replace" : "Select",
              style: TextStyle(
                color: hasFile ? AppColors.textSecondary : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminFeedbackBanner(
    String title,
    String body,
    Color textColor,
    Color bgColor,
    Color borderColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
