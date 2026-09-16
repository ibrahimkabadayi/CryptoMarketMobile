import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../services/api_client.dart';
import '../services/auth_api.dart';

// ── Service Providers ──────────────────────────────────────
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(apiClient: ref.read(apiClientProvider)),
);

// ── Auth State ─────────────────────────────────────────────
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? userId;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.userId,
    this.errorMessage,
    this.successMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? userId,
    String? errorMessage,
    String? successMessage,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    isLoading: isLoading ?? this.isLoading,
    userId: userId ?? this.userId,
    errorMessage: errorMessage,
    successMessage: successMessage,
  );
}

// ── Auth Notifier ──────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _authApi;

  AuthNotifier(this._authApi) : super(const AuthState());

  /// Check if user is already logged in (on app startup).
  Future<void> checkAuth() async {
    final loggedIn = await _authApi.isLoggedIn();
    if (loggedIn) {
      final userId = await _authApi.getUserIdFromToken();
      state = state.copyWith(isLoggedIn: true, userId: userId);
    } else {
      state = state.copyWith(isLoggedIn: false, userId: null);
    }
  }

  /// Login with email/password.
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authApi.login(
        LoginRequest(email: email, password: password),
      );

      final userId = await _authApi.getUserIdFromToken();
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        userId: userId,
      );
      return true;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ??
          'Invalid credentials or server error. Please try again.';
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  /// Register a new user.
  Future<bool> register(RegisterRequest request) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final response = await _authApi.register(request);
      state = state.copyWith(
        isLoading: false,
        successMessage:
            response.message.isNotEmpty
                ? response.message
                : 'Registration successful! Proceeding to auth...',
      );
      return true;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ??
          'Registration failed. Verify input and retry.';
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  /// Logout and clear token.
  Future<void> logout() async {
    await _authApi.logout();
    state = const AuthState();
  }

  /// Clear transient messages.
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

// ── Provider ───────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authApiProvider)),
);
