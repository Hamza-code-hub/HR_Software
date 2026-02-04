import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _defaultBaseUrl = 'http://localhost:3000';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  ApiClient({String baseUrl = _defaultBaseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401 && _onRefresh != null) {
          final refreshed = await _onRefresh!();
          if (refreshed) {
            return handler.resolve(
              await _retry(err.requestOptions),
            );
          }
        }
        return handler.next(err);
      },
    ));
  }

  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  Future<bool> Function()? _onRefresh;

  Dio get dio => _dio;

  void setTokens({String? access, String? refresh}) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  void setOnRefresh(Future<bool> Function() fn) {
    _onRefresh = fn;
  }

  Future<Response<T>> _retry<T>(RequestOptions options) {
    return _dio.fetch(options);
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
}
