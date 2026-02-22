import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../core/api_client.dart';

// ────────────────────────────────────────────────────────────────
// Storage keys
// ────────────────────────────────────────────────────────────────
const _kAccessToken  = 'hr_saas_access';
const _kRefreshToken = 'hr_saas_refresh';
const _kExpiresAt    = 'hr_saas_expires_at';
const _kUserRole     = 'hr_saas_role';
const _kUserId       = 'hr_saas_user_id';
const _kTenantId     = 'hr_saas_tenant_id';
const _kUserEmail    = 'hr_saas_email';

// ────────────────────────────────────────────────────────────────
// Models
// ────────────────────────────────────────────────────────────────
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
    required this.tenantId,
    required this.email,
    required this.role,
  });

  final String   accessToken;
  final String   refreshToken;
  final DateTime expiresAt;
  final String   userId;
  final String   tenantId;
  final String   email;
  final String   role;

  bool get isAdmin      => role == 'admin';
  bool get isHR         => role == 'hr' || role == 'admin';
  bool get isAccounting => role == 'accounting' || role == 'admin';
}

// ────────────────────────────────────────────────────────────────
// Provider
// ────────────────────────────────────────────────────────────────
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthTokens?>>(
  (ref) {
    final client   = ref.watch(apiClientProvider);
    final notifier = AuthNotifier(client);
    // Wire refresh + session expiry callbacks to the API client
    client.onRefreshToken  = notifier.refresh;
    client.onSessionExpired = notifier.logout;
    return notifier;
  },
);

// ────────────────────────────────────────────────────────────────
// Notifier
// ────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AsyncValue<AuthTokens?>> {
  AuthNotifier(this._client) : super(const AsyncValue.loading()) {
    _init();
  }

  final ApiClient   _client;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Session Init ─────────────────────────────────────────────
  Future<void> _init() async {
    try {
      final access  = await _storage.read(key: _kAccessToken);
      final refresh = await _storage.read(key: _kRefreshToken);
      final expiresAtStr = await _storage.read(key: _kExpiresAt);

      if (access == null || refresh == null) {
        state = const AsyncValue.data(null);
        return;
      }

      // Check if token is expired; try refresh if so
      final expiresAt = expiresAtStr != null
          ? DateTime.tryParse(expiresAtStr) ?? DateTime.now()
          : DateTime.now();

      if (DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 2)))) {
        // Token expired (or about to expire) — refresh silently
        _client.setTokens(access: access, refresh: refresh);
        final refreshed = await refresh_();
        if (!refreshed) {
          await _clearStorage();
          state = const AsyncValue.data(null);
          return;
        }
        return; // state set by refresh_()
      }

      // Token still valid — restore session
      final tokens = await _tokensFromStorage(access, refresh, expiresAt);
      _client.setTokens(access: access, refresh: refresh);
      state = AsyncValue.data(tokens);
    } catch (e, st) {
      state = AsyncValue.data(null); // fail silently on startup
    }
  }

  // ── Auth Operations ───────────────────────────────────────────
  Future<void> signup({
    required String email,
    required String password,
    required String tenantName,
    String? subdomain,
  }) async {
    state = const AsyncValue.loading();
    try {
      final data = await _client.post('/auth/signup', authenticated: false, body: {
        'email':       email,
        'password':    password,
        'tenant_name': tenantName,
        if (subdomain != null && subdomain.isNotEmpty) 'subdomain': subdomain,
      }) as Map<String, dynamic>;
      await _storeAndSetState(data);
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
      final data = await _client.post('/auth/login', authenticated: false, body: {
        'email':    email,
        'password': password,
        if (tenantId  != null && tenantId.isNotEmpty)  'tenant_id': tenantId,
        if (subdomain != null && subdomain.isNotEmpty) 'subdomain': subdomain,
      }) as Map<String, dynamic>;
      await _storeAndSetState(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<bool> refresh() => refresh_();

  Future<bool> refresh_() async {
    final refreshToken = _client.refreshToken ?? await _storage.read(key: _kRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final data = await _client.post(
        '/auth/refresh',
        authenticated: false,
        body: {'refresh_token': refreshToken},
      ) as Map<String, dynamic>;
      await _storeAndSetState(data);
      return true;
    } catch (_) {
      await _clearStorage();
      state = const AsyncValue.data(null);
      return false;
    }
  }

  Future<void> logout() async {
    _client.clearTokens();
    await _clearStorage();
    state = const AsyncValue.data(null);
  }

  // ── Helpers ───────────────────────────────────────────────────
  Future<void> _storeAndSetState(Map<String, dynamic> data) async {
    final access    = data['access_token']  as String;
    final refresh   = data['refresh_token'] as String;
    final expiresAt = DateTime.tryParse(data['expires_at'] as String? ?? '') ??
        DateTime.now().add(const Duration(minutes: 15));

    // Decode JWT to extract claims (userId, tenantId, email, role)
    Map<String, dynamic> claims = {};
    try {
      claims = JwtDecoder.decode(access);
    } catch (_) {}

    final userId   = claims['user_id']   as String? ?? '';
    final tenantId = claims['tenant_id'] as String? ?? '';
    final email    = claims['email']     as String? ?? '';
    final role     = claims['role']      as String? ?? 'employee';

    _client.setTokens(access: access, refresh: refresh);

    await _storage.write(key: _kAccessToken,  value: access);
    await _storage.write(key: _kRefreshToken, value: refresh);
    await _storage.write(key: _kExpiresAt,    value: expiresAt.toIso8601String());
    await _storage.write(key: _kUserId,       value: userId);
    await _storage.write(key: _kTenantId,     value: tenantId);
    await _storage.write(key: _kUserEmail,    value: email);
    await _storage.write(key: _kUserRole,     value: role);

    state = AsyncValue.data(AuthTokens(
      accessToken:  access,
      refreshToken: refresh,
      expiresAt:    expiresAt,
      userId:       userId,
      tenantId:     tenantId,
      email:        email,
      role:         role,
    ));
  }

  Future<AuthTokens> _tokensFromStorage(
    String access, String refresh, DateTime expiresAt) async {
    return AuthTokens(
      accessToken:  access,
      refreshToken: refresh,
      expiresAt:    expiresAt,
      userId:       await _storage.read(key: _kUserId)     ?? '',
      tenantId:     await _storage.read(key: _kTenantId)   ?? '',
      email:        await _storage.read(key: _kUserEmail)  ?? '',
      role:         await _storage.read(key: _kUserRole)   ?? 'employee',
    );
  }

  Future<void> _clearStorage() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kExpiresAt);
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kTenantId);
    await _storage.delete(key: _kUserEmail);
    await _storage.delete(key: _kUserRole);
  }
}

// ────────────────────────────────────────────────────────────────
// Convenience session provider (derived from authStateProvider)
// ────────────────────────────────────────────────────────────────
final sessionProvider = Provider<AuthTokens?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider) != null;
});

final userRoleProvider = Provider<String>((ref) {
  return ref.watch(sessionProvider)?.role ?? 'guest';
});
