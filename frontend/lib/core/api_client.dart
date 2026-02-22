import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// ────────────────────────────────────────────────────────────────
// Configuration
// ────────────────────────────────────────────────────────────────

const _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

const _kConnectTimeout = Duration(seconds: 30);
const _kReadTimeout    = Duration(seconds: 60);

// ────────────────────────────────────────────────────────────────
// Exceptions
// ────────────────────────────────────────────────────────────────

class AppException implements Exception {
  const AppException({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String  message;
  final int?    statusCode;
  final String? code;

  bool get isUnauthorized  => statusCode == 401;
  bool get isForbidden     => statusCode == 403;
  bool get isNotFound      => statusCode == 404;
  bool get isServerError   => statusCode != null && statusCode! >= 500;
  bool get isNetworkError  => statusCode == null;

  @override
  String toString() => 'AppException($statusCode): $message';
}

// ────────────────────────────────────────────────────────────────
// API Client
// ────────────────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  ApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? _kBaseUrl;

  final String _baseUrl;

  String? _accessToken;
  String? _refreshToken;

  /// Called when a token refresh is needed. Set by [AuthNotifier].
  Future<bool> Function()? onRefreshToken;

  /// Called when the session has expired and the user must be logged out.
  VoidCallback? onSessionExpired;

  void setTokens({required String access, required String refresh}) {
    _accessToken  = access;
    _refreshToken = refresh;
  }

  void clearTokens() {
    _accessToken  = null;
    _refreshToken = null;
  }

  String? get accessToken  => _accessToken;
  String? get refreshToken => _refreshToken;

  // ── Low-level HTTP ──────────────────────────────────────────

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool retry = true,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final response = await http
        .get(uri, headers: _headers())
        .timeout(_kReadTimeout);
    return _handleResponse(response, retry: retry,
        onRetry: () => get(path, queryParameters: queryParameters, retry: false));
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
    bool retry = true,
  }) async {
    final uri = _buildUri(path, null);
    final response = await http
        .post(uri, headers: _headers(authenticated: authenticated), body: jsonEncode(body))
        .timeout(_kReadTimeout);
    return _handleResponse(response, retry: retry,
        onRetry: () => post(path, body: body, retry: false));
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool retry = true,
  }) async {
    final uri = _buildUri(path, null);
    final response = await http
        .put(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(_kReadTimeout);
    return _handleResponse(response, retry: retry,
        onRetry: () => put(path, body: body, retry: false));
  }

  Future<dynamic> delete(String path, {bool retry = true}) async {
    final uri = _buildUri(path, null);
    final response = await http
        .delete(uri, headers: _headers())
        .timeout(_kReadTimeout);
    return _handleResponse(response, retry: retry,
        onRetry: () => delete(path, retry: false));
  }

  /// Download raw bytes (for PDF etc.)
  Future<Uint8List> getBytes(String path) async {
    final uri = _buildUri(path, null);
    final response = await http
        .get(uri, headers: _headers())
        .timeout(_kReadTimeout);
    if (response.statusCode == 200) return response.bodyBytes;
    throw _parseError(response);
  }

  // ── Internals ───────────────────────────────────────────────

  Uri _buildUri(String path, Map<String, String>? query) {
    final base = Uri.parse(_baseUrl);
    return Uri(
      scheme: base.scheme,
      host:   base.host,
      port:   base.port,
      path:   path,
      queryParameters: query?.isEmpty == true ? null : query,
    );
  }

  Map<String, String> _headers({bool authenticated = true}) {
    return {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader:      'application/json',
      if (authenticated && _accessToken != null)
        HttpHeaders.authorizationHeader: 'Bearer $_accessToken',
    };
  }

  Future<dynamic> _handleResponse(
    http.Response response, {
    required bool retry,
    required Future<dynamic> Function() onRetry,
  }) async {
    // 401 → try refresh once, then retry the original request
    if (response.statusCode == 401 && retry && onRefreshToken != null) {
      final refreshed = await onRefreshToken!();
      if (refreshed) {
        return onRetry();
      } else {
        // Both access and refresh tokens invalid → force logout
        onSessionExpired?.call();
        throw const AppException(message: 'Session expired. Please log in again.', statusCode: 401);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    throw _parseError(response);
  }

  AppException _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return AppException(
        message:    body['error'] as String? ?? body['message'] as String? ?? 'Unknown error',
        statusCode: response.statusCode,
        code:       body['code'] as String?,
      );
    } catch (_) {
      return AppException(
        message:    'Network error (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }
}
