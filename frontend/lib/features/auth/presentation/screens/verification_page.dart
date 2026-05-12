import 'package:flutter/material.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool gstUploaded = false;
  bool licenseUploaded = false;

  @override
  Widget build(BuildContext context) {
    bool isReady = gstUploaded && licenseUploaded;

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
              subtitle: "Required for tax compliance",
              isUploaded: gstUploaded,
              onTap: () => setState(() => gstUploaded = true),
            ),

            const SizedBox(height: 20),

            _buildPremiumUploadCard(
              title: "Trade License / Shop Act",
              subtitle: "Must be valid for the current year",
              isUploaded: licenseUploaded,
              onTap: () => setState(() => licenseUploaded = true),
            ),

            const SizedBox(height: 40),

            // 3. Adaptive Submit Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: isReady ? Colors.indigo.shade800 : Colors.grey.shade200,
                  foregroundColor: isReady ? Colors.white : Colors.grey.shade500,
                  elevation: isReady ? 4 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: isReady ? () => _showSuccessModal() : null,
                child: const Text("Submit Verification Request", 
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
                  Text(isUploaded ? "Document Attached" : subtitle, 
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
                Navigator.pop(context); // Go back to Dash
              },
              child: const Text("Done", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}