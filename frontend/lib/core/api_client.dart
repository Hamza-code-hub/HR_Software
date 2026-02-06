import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Temporary stub for backward compatibility
// This maintains compatibility with existing repository files
// while the new api_service.dart serves the modern sidebar

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  String? _accessToken;
  String? _refreshToken;
  Function? _onRefresh;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  void setTokens({String? access, String? refresh}) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  void setOnRefresh(Function callback) {
    _onRefresh = callback;
  }

  // Stub Dio-like interface
  DioStub get dio => DioStub(this);
}

class DioStub {
  final ApiClient _client;
  static const String baseUrl = 'http://localhost:3000';

  DioStub(this._client);

  Future<ResponseStub> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
    final response = await http.get(
      uri,
      headers: _getHeaders(),
    );
    return ResponseStub(jsonDecode(response.body));
  }

  Future<ResponseStub> post(String path, {Map<String, dynamic>? data}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );
    return ResponseStub(jsonDecode(response.body));
  }

  Future<ResponseStub> put(String path, {Map<String, dynamic>? data}) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );
    return ResponseStub(jsonDecode(response.body));
  }

  Future<ResponseStub> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _getHeaders(),
    );
    return ResponseStub(jsonDecode(response.body));
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_client._accessToken != null) {
      headers['Authorization'] = 'Bearer ${_client._accessToken}';
    }
    return headers;
  }
}

class ResponseStub {
  final dynamic data;
  ResponseStub(this.data);
}
