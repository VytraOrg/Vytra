import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../errors/exceptions.dart';
import '../cache/cache_manager.dart';
import '../../api_config.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _client.get(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: _defaultHeaders(),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on SocketException {
      throw NetworkError();
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _client.post(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: _defaultHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on SocketException {
      throw NetworkError();
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _client.put(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: _defaultHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on SocketException {
      throw NetworkError();
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _client.delete(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: _defaultHeaders(),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on SocketException {
      throw NetworkError();
    } catch (e) {
      rethrow;
    }
  }

  Map<String, String> _defaultHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final user = CacheManager.getUser();
    if (kDebugMode) print('👤 Cached User: $user');
    
    if (user != null && user['accessToken'] != null) {
      final token = user['accessToken'];
      headers['Authorization'] = 'Bearer $token';
      if (kDebugMode) print('🔑 Auth Header Set: Bearer ${token.substring(0, 10)}...');
    } else {
      if (kDebugMode) print('⚠️ No Auth Token found in Cache!');
    }

    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    switch (response.statusCode) {
      case 200:
      case 201:
        return decoded;
      case 400:
        throw AppError(decoded['error'] ?? "Bad request");
      case 401:
        throw AuthError(decoded['error'] ?? "Unauthorized");
      case 500:
        throw ServerError(statusCode: 500);
      default:
        throw AppError("Error ${response.statusCode}: ${response.reasonPhrase}");
    }
  }
}
