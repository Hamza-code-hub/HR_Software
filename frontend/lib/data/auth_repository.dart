import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthTokens?>>((ref) {
  final client = ref.watch(apiClientProvider);
  final notifier = AuthNotifier(client);
  client.setOnRefresh(() => notifier.refresh());
  return notifier;
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthTokens?>> {
  AuthNotifier(this._client) : super(const AsyncValue.data(null)) {
    _loadStored();
  }

  final ApiClient _client;

  static const _storageKey = 'hr_saas_tokens';

  void _loadStored() {
    // In a real app, read from secure storage. For MVP use in-memory only.
    state = const AsyncValue.data(null);
  }

  Future<void> signup({
    required String email,
    required String password,
    required String tenantName,
    String? subdomain,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.dio.post(
        '/auth/signup',
        data: {
          'email': email,
          'password': password,
          'tenant_name': tenantName,
          if (subdomain != null && subdomain.isNotEmpty) 'subdomain': subdomain,
        },
      );
      final data = res.data as Map<String, dynamic>;
      final access = data['access_token'] as String;
      final refresh = data['refresh_token'] as String;
      final expiresAt = DateTime.tryParse(data['expires_at'] as String? ?? '') ?? DateTime.now().add(const Duration(minutes: 15));
      _client.setTokens(access: access, refresh: refresh);
      state = AsyncValue.data(AuthTokens(accessToken: access, refreshToken: refresh, expiresAt: expiresAt));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
    String? tenantId,
    String? subdomain,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          if (tenantId != null && tenantId.isNotEmpty) 'tenant_id': tenantId,
          if (subdomain != null && subdomain.isNotEmpty) 'subdomain': subdomain,
        },
      );
      final data = res.data as Map<String, dynamic>;
      final access = data['access_token'] as String;
      final refresh = data['refresh_token'] as String;
      final expiresAt = DateTime.tryParse(data['expires_at'] as String? ?? '') ?? DateTime.now().add(const Duration(minutes: 15));
      _client.setTokens(access: access, refresh: refresh);
      state = AsyncValue.data(AuthTokens(accessToken: access, refreshToken: refresh, expiresAt: expiresAt));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<bool> refresh() async {
    final refreshToken = _client.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final res = await _client.dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = res.data as Map<String, dynamic>;
      final access = data['access_token'] as String;
      final newRefresh = data['refresh_token'] as String;
      final expiresAt = DateTime.tryParse(data['expires_at'] as String? ?? '') ?? DateTime.now().add(const Duration(minutes: 15));
      _client.setTokens(access: access, refresh: newRefresh);
      state = AsyncValue.data(AuthTokens(accessToken: access, refreshToken: newRefresh, expiresAt: expiresAt));
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    _client.clearTokens();
    state = const AsyncValue.data(null);
  }
}
