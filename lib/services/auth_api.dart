import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../core/constants.dart';
import '../models/auth_models.dart';
import 'api_client.dart';

/// Authentication API service.
/// Mirrors: frontend/src/api/authApi.ts
class AuthApi {
  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  AuthApi({required this.apiClient, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Login and store JWT token securely.
  Future<LoginResponse> login(LoginRequest credentials) async {
    final response = await apiClient.dio.post(
      '/api/auth/login',
      data: credentials.toJson(),
    );
    final loginResponse = LoginResponse.fromJson(response.data);

    // Store token securely
    await _storage.write(key: AppConstants.tokenKey, value: loginResponse.token);
    debugPrint('Login successful, token stored.');

    return loginResponse;
  }

  /// Register a new user.
  Future<RegisterResponse> register(RegisterRequest data) async {
    final response = await apiClient.dio.post(
      '/api/auth/register',
      data: data.toJson(),
    );
    return RegisterResponse.fromJson(response.data);
  }

  /// Clear stored token (logout).
  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    debugPrint('Token cleared, user logged out.');
  }

  /// Check if user has a valid (non-expired) token.
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null || token.isEmpty) return false;

    try {
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      debugPrint('Token validation failed: $e');
      return false;
    }
  }

  /// Extract userId from JWT token claims.
  /// Tries common claim names: nameid, sub, userId, nameidentifier.
  Future<String?> getUserIdFromToken() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null || token.isEmpty) return null;

    try {
      final decoded = JwtDecoder.decode(token);
      return decoded['nameid'] as String? ??
          decoded['sub'] as String? ??
          decoded['userId'] as String? ??
          decoded[
              'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
              as String?;
    } catch (e) {
      debugPrint('Failed to decode JWT: $e');
      return null;
    }
  }

  /// Get the raw token for SignalR auth (future use).
  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }
}