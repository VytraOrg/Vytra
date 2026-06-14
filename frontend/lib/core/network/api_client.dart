import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../errors/exceptions.dart';
import '../cache/cache_manager.dart';
import '../api/api_constants.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> get(String endpoint) async {
    try {
      if (kDebugMode) print('📡 GET: $apiBaseUrl$endpoint');
      final response = await _client.get(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: _defaultHeaders(),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on SocketException {
      throw NetworkError();
    } catch (e) {
      if (kDebugMode) print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      if (kDebugMode) print('📡 POST: $apiBaseUrl$endpoint | Body: $body');
      final response = await _client.post(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: _defaultHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on SocketException {
      throw NetworkError();
    } catch (e) {
      if (kDebugMode) print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      if (kDebugMode) print('📡 PUT: $apiBaseUrl$endpoint | Body: $body');
      final response = await _client.put(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: _defaultHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on SocketException {
      throw NetworkError();
    } catch (e) {
      if (kDebugMode) print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      if (kDebugMode) print('📡 DELETE: $apiBaseUrl$endpoint');
      final response = await _client.delete(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: _defaultHeaders(),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on SocketException {
      throw NetworkError();
    } catch (e) {
      if (kDebugMode) print('❌ API Error: $e');
      rethrow;
    }
  }

  Map<String, String> _defaultHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final user = CacheManager.getUser();
    if (user != null && user['accessToken'] != null) {
      final token = user['accessToken'];
      headers['Authorization'] = 'Bearer $token';
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
        throw AppError("Resource not found");
      case 500:
        throw ServerError(statusCode: 500);
      default:
        throw AppError("Error ${response.statusCode}: $message");
    }
  }
}
