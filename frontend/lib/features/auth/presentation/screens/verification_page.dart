import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/api/api_constants.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  Uint8List? gstBytes;
  String? gstFileName;
  Uint8List? licenseBytes;
  String? licenseFileName;
  bool isUploading = false;

  Future<void> _pickGstFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          gstBytes = result.files.single.bytes;
          gstFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _pickLicenseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          licenseBytes = result.files.single.bytes;
          licenseFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _submitVerification() async {
    if (gstBytes == null || licenseBytes == null) return;

    setState(() {
      isUploading = true;
    });

    try {
      final user = CacheManager.getUser();
      final token = user?['accessToken'];

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/shops/verify'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'gstCertificate',
          gstBytes!,
          filename: gstFileName,
        ),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'tradeLicense',
          licenseBytes!,
          filename: licenseFileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSuccessModal();
      } else {
        String message = 'Failed to submit verification';
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
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isReady = gstBytes != null && licenseBytes != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Business Verification", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Security & Trust Header
            _buildSecurityHeader(),
            const SizedBox(height: 32),

            const Text(
              "Document Checklist",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Upload high-resolution scans or photos of your business credentials.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // 2. Interactive Upload Zones
            _buildPremiumUploadCard(
              title: "GST Registration Certificate",
              subtitle: gstFileName ?? "Required for tax compliance",
              isUploaded: gstBytes != null,
              onTap: isUploading ? () {} : _pickGstFile,
            ),

            const SizedBox(height: 20),

            _buildPremiumUploadCard(
              title: "Trade License / Shop Act",
              subtitle: licenseFileName ?? "Must be valid for the current year",
              isUploaded: licenseBytes != null,
              onTap: isUploading ? () {} : _pickLicenseFile,
            ),

            const SizedBox(height: 40),

            // 3. Adaptive Submit Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: isReady && !isUploading ? Colors.indigo.shade800 : Colors.grey.shade200,
                  foregroundColor: isReady && !isUploading ? Colors.white : Colors.grey.shade500,
                  elevation: isReady && !isUploading ? 4 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: isReady && !isUploading ? _submitVerification : null,
                child: isUploading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text("Submit Verification Request", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 20),
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                  SizedBox(width: 5),
                  Text("End-to-end encrypted submission", 
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigo.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.shield_rounded, color: Colors.indigo, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Secure Verification", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 2),
                Text("Your documents are stored securely and never shared.", 
                  style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumUploadCard({
    required String title, 
    required String subtitle, 
    required bool isUploaded, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isUploaded ? Colors.green.withOpacity(0.02) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUploaded ? Colors.green.shade200 : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: isUploaded ? Colors.green.shade50 : Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isUploaded ? Icons.check_rounded : Icons.add_photo_alternate_outlined,
                color: isUploaded ? Colors.green : Colors.indigo,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(isUploaded && subtitle.length > 25 
                      ? "...${subtitle.substring(subtitle.length - 22)}"
                      : subtitle, 
                    style: TextStyle(color: isUploaded ? Colors.green : Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Text(
              isUploaded ? "Replace" : "Upload",
              style: TextStyle(
                color: isUploaded ? Colors.grey : Colors.indigo,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text("Under Review", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "Your shop details are being verified by our team. This usually takes 24 hours.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 58),
                backgroundColor: Colors.indigo.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(context); // Close Modal
                Navigator.pop(context, true); // Go back to Dash and notify success
              },
              child: const Text("Done", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}