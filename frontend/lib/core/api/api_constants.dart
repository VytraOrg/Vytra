import 'package:flutter/foundation.dart';

/// --- CONNECTIVITY GUIDE ---
/// 
/// 1. EMULATOR: Use '10.0.2.2'
/// 2. PHYSICAL PHONE: 
///    - Connect phone and PC to the SAME Wi-Fi.
///    - Find your PC IP (Windows: 'ipconfig', Mac: 'ifconfig').
///    - Look for "IPv4 Address" (usually starts with 192.168...).
///    - Replace '10.0.2.2' with that IP below.
/// 3. BACKEND: Ensure you run using 'python app.py' NOT 'flask run'.

String get apiBaseUrl {
  // If the app is compiled in Release/Production mode, point directly to the deployed Render URL
  if (kReleaseMode) {
    return 'https://local-commerce-backend.onrender.com/api/v1'; // Replace with your actual Render URL once deployed
  }

  if (kIsWeb) return 'http://localhost:5001/api/v1';

  // --- EDIT THIS LINE ---
  // Change to your PC IP if using a real phone (e.g., '192.168.1.5')
  String hostIp = '10.0.2.2';
  // ----------------------

  final url = 'http://$hostIp:5001/api/v1'; // Force refresh port
  
  if (kDebugMode) {
    print('📡 Attempting to connect to: $url');
  }
  
  return url;
}
