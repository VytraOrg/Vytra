import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../errors/exceptions.dart';
import '../cache/cache_manager.dart';
import '../api/api_constants.dart';

class ApiClient {
  final http.Client _client;
  Future<void>? _refreshFuture;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> _execute(Future<http.Response> Function() requestFn) async {
    try {
      final response = await requestFn().timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 401) {
        if (kDebugMode) print('🔑 API Client: Unauthorized (401), attempting token refresh...');
        final refreshSuccess = await _attemptTokenRefresh();
        if (refreshSuccess) {
          if (kDebugMode) print('🔁 API Client: Retrying request...');
          final retryResponse = await requestFn().timeout(const Duration(seconds: 15));
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } on SocketException {
      throw NetworkError();
    } catch (e) {
      if (kDebugMode) print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<bool> _attemptTokenRefresh() async {
    if (_refreshFuture != null) {
      try {
        await _refreshFuture;
        return true;
      } catch (_) {
        return false;
      }
    }

    final user = CacheManager.getUser();
    final refreshToken = user?['refreshToken'] ?? user?['refresh_token'];
    if (refreshToken == null) {
      if (kDebugMode) print('⚠️ API Client: No refresh token found in local cache');
      return false;
    }

    final completer = Completer<void>();
    _refreshFuture = completer.future;

    try {
      if (kDebugMode) print('🔄 API Client: Sending refresh token request...');
      final response = await _client.post(
        Uri.parse('$apiBaseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final currentUser = CacheManager.getUser() ?? {};
        
        // Safely extract and merge tokens into existing camelCase structure
        final newAccessToken = decoded['access_token'] ?? decoded['accessToken'];
        final newRefreshToken = decoded['refresh_token'] ?? decoded['refreshToken'];
        
        if (newAccessToken != null) {
          currentUser['accessToken'] = newAccessToken;
        }
        if (newRefreshToken != null) {
          currentUser['refreshToken'] = newRefreshToken;
        }

        // Merge updated user details if returned
        if (decoded['user'] is Map) {
          final userMap = Map<String, dynamic>.from(decoded['user']);
          currentUser['id'] = (userMap['id'] ?? userMap['_id'] ?? currentUser['id'] ?? '').toString();
          currentUser['name'] = (userMap['name'] ?? currentUser['name'] ?? '').toString();
          currentUser['email'] = (userMap['email'] ?? currentUser['email'] ?? '').toString();
          currentUser['role'] = (userMap['role'] ?? currentUser['role'] ?? '').toString();
          currentUser['businessName'] = (userMap['businessName'] ?? currentUser['businessName'] ?? '').toString();
          currentUser['phone'] = (userMap['phone'] ?? currentUser['phone'] ?? '').toString();
        }
        
        await CacheManager.saveUser(currentUser);
        if (kDebugMode) print('✅ API Client: Token refresh successful and merged into local cache');
        completer.complete();
        return true;
      } else {
        if (kDebugMode) print('❌ API Client: Refresh request rejected (Status: ${response.statusCode})');
        await CacheManager.clearAll();
        completer.completeError('Token refresh rejected');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('❌ API Client: Refresh request failed ($e)');
      completer.completeError(e);
      return false;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<dynamic> get(
    String endpoint, {
    bool useCache = false,
    Duration? maxAge,
    bool forceRefresh = false,
  }) async {
    final cacheKey = endpoint;
    if (useCache && !forceRefresh) {
      final cached = CacheManager.getCachedResponse(
        cacheKey,
        maxAge: maxAge ?? const Duration(minutes: 5),
      );
      if (cached != null) {
        if (kDebugMode) print('⚡ CACHE HIT: $cacheKey');
        return cached;
      }
    }

    if (kDebugMode) print('📡 GET: $apiBaseUrl$endpoint');
    try {
      final response = await _execute(() => _client.get(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: _defaultHeaders(),
      ));

      if (useCache && response != null) {
        await CacheManager.cacheResponse(cacheKey, response);
      }
      return response;
    } catch (e) {
      // Offline fallback: return stale cached response if available
      if (useCache) {
        final staleCache = CacheManager.getCachedResponse(cacheKey);
        if (staleCache != null) {
          if (kDebugMode) print('⚠️ Returning stale cache due to network error: $e');
          return staleCache;
        }
      }
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    if (kDebugMode) print('📡 POST: $apiBaseUrl$endpoint | Body: $body');
    return _execute(() => _client.post(
      Uri.parse('$apiBaseUrl$endpoint'),
      headers: _defaultHeaders(),
      body: jsonEncode(body),
    ));
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    if (kDebugMode) print('📡 PUT: $apiBaseUrl$endpoint | Body: $body');
    return _execute(() => _client.put(
      Uri.parse('$apiBaseUrl$endpoint'),
      headers: _defaultHeaders(),
      body: jsonEncode(body),
    ));
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    if (kDebugMode) print('📡 PATCH: $apiBaseUrl$endpoint | Body: $body');
    return _execute(() => _client.patch(
      Uri.parse('$apiBaseUrl$endpoint'),
      headers: _defaultHeaders(),
      body: jsonEncode(body),
    ));
  }

  Future<dynamic> delete(String endpoint) async {
    if (kDebugMode) print('📡 DELETE: $apiBaseUrl$endpoint');
    return _execute(() => _client.delete(
      Uri.parse('$apiBaseUrl$endpoint'),
      headers: _defaultHeaders(),
    ));
  }

  Map<String, String> _defaultHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final user = CacheManager.getUser();
    if (user != null) {
      final token = user['accessToken'] ?? user['access_token'];
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    var message = decoded['message'] ?? decoded['error'] ?? "Request failed";
    if (message is List) {
      message = message.join(', ');
    } else {
      message = message.toString();
    }
    
    switch (response.statusCode) {
      case 400:
        throw AppError(message);
      case 401:
        throw AuthError(message);
      case 403:
        throw AuthError("Forbidden: Insufficient permissions");
      case 404:
        throw AppError(message.isNotEmpty && message != "Not Found" ? message : "Resource not found");
      case 500:
        throw ServerError(statusCode: 500);
      default:
        throw AppError("Error ${response.statusCode}: $message");
    }
  }
}
