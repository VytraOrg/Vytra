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
  if (kIsWeb) return 'http://localhost:5001';

  // --- EDIT THIS LINE ---
  // Change to your PC IP if using a real phone (e.g., '192.168.1.5')
  // We remove 'const' to ensure Flutter doesn't cache an old IP.
  String hostIp = '192.168.0.104';
  // ----------------------

  final url = 'http://$hostIp:5001';
  
  if (kDebugMode) {
    print('📡 Attempting to connect to: $url');
  }
  
  return url;
}
