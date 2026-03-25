import 'package:flutter/foundation.dart';

// Optional override: flutter run --dart-define=API_BASE_URL=http://<host>:5000
String get apiBaseUrl {
  if (kIsWeb) {
    final fromQuery = Uri.base.queryParameters['apiBase'];
    if (fromQuery != null && fromQuery.isNotEmpty) {
      return fromQuery;
    }
  }

  const configuredUrl = String.fromEnvironment('API_BASE_URL');
  if (configuredUrl.isNotEmpty) {
    return configuredUrl;
  }

  if (kIsWeb) {
    final baseUri = Uri.base;
    final host = baseUri.host;
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return 'http://localhost:5000';
    }

    // For forwarded hosts like "name-43253.app.github.dev", map the app port
    // segment to backend port 5000 => "name-5000.app.github.dev".
    final mappedHost = _mapForwardedHostToPort(host, 5000);
    if (mappedHost != null) {
      return '${baseUri.scheme}://$mappedHost';
    }

    return '${baseUri.scheme}://$host:5000';
  }

  return 'http://10.0.2.2:5000';
}

String? _mapForwardedHostToPort(String host, int port) {
  final match = RegExp(r'^(.*)-\d+(\..+)$').firstMatch(host);
  if (match == null) {
    return null;
  }
  final prefix = match.group(1);
  final suffix = match.group(2);
  if (prefix == null || suffix == null) {
    return null;
  }
  return '$prefix-$port$suffix';
}