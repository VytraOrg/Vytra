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
  if (kIsWeb) {
    return 'https://localcommerceapp-1.onrender.com/api/v1';
  }

  if (kReleaseMode) {
    return 'https://localcommerceapp-1.onrender.com/api/v1';
  }

  String hostIp = '10.0.2.2';

  final url = 'http://$hostIp:5001/api/v1';

  if (kDebugMode) {
    print('📡 Attempting to connect to: $url');
  }

  return url;
}
