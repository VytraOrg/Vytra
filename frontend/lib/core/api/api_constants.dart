import 'package:flutter/foundation.dart';

/// Production hosted backend URL (used for production builds & release APK/web)
const String _prodBackendUrl = 'https://localcommerceapp-1.onrender.com/api/v1';

/// Local development backend URLs (used during development)
const String _localWebUrl = 'http://localhost:5001/api/v1';
const String _localAndroidEmulatorUrl = 'http://10.0.2.2:5001/api/v1';
const String _localDesktopUrl = 'http://localhost:5001/api/v1';

String get apiBaseUrl {
  // 1. Production release builds or when explicitly overriding with --dart-define=USE_REMOTE_BACKEND=true
  const bool forceRemote = bool.fromEnvironment('USE_REMOTE_BACKEND', defaultValue: false);
  if (kReleaseMode || forceRemote) {
    return _prodBackendUrl;
  }

  // 2. Development mode (Debug / Profile)
  if (kIsWeb) {
    return _localWebUrl;
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return _localAndroidEmulatorUrl;
  }

  return _localDesktopUrl;
}

