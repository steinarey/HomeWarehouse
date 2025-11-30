import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:mobile/config/app_constants.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((
  ref,
) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  static const _tokenKey = 'auth_token';
  String? _token;

  String? get token => _token;

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      if (_token != null) {
        state = const AsyncValue.data(true);
      } else {
        state = const AsyncValue.data(false);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      // We need a separate Dio instance or raw http to avoid circular dependency
      // if ApiClient depends on AuthProvider.
      // Or we can use the ApiClient but we need to be careful.
      // For login, we don't need the token header, so a fresh Dio is fine.

      // Get base URL from prefs or constants
      final prefs = await SharedPreferences.getInstance();
      final baseUrl =
          prefs.getString('base_url') ?? AppConstants.defaultBaseUrl;

      final dio = Dio(BaseOptions(baseUrl: baseUrl));

      final response = await dio.post(
        '/login/access-token',
        data: FormData.fromMap({'username': username, 'password': password}),
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final token = response.data['access_token'];
      await prefs.setString(_tokenKey, token);
      _token = token;
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _token = null;
    state = const AsyncValue.data(false);
  }
}
