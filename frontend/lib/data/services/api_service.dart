import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Store auth token
  String? _authToken;
  
  void setAuthToken(String token) {
    _authToken = token;
  }

  String? getAuthToken() => _authToken;

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Generic GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw ApiException(
          'Request failed with status ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw ApiException(
          'Request failed with status ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  // Analytics Endpoints
  Future<Map<String, dynamic>> getHRDashboardStats() async {
    return await get('/api/analytics/hr/dashboard-stats');
  }

  Future<Map<String, dynamic>> getPayrollTrend({int months = 12}) async {
    return await get('/api/analytics/hr/payroll-trend?months=$months');
  }

  Future<Map<String, dynamic>> getTurnoverAnalysis() async {
    return await get('/api/analytics/hr/turnover-analysis');
  }

  Future<Map<String, dynamic>> getRecruitmentFunnel() async {
    return await get('/api/analytics/hr/recruitment-funnel');
  }

  Future<Map<String, dynamic>> getLeaveBalance() async {
    return await get('/api/analytics/hr/leave-balance');
  }

  Future<Map<String, dynamic>> getAttendanceHeatmap({int days = 30}) async {
    return await get('/api/analytics/hr/attendance-heatmap?days=$days');
  }

  Future<Map<String, dynamic>> getAccountingDashboardStats() async {
    return await get('/api/analytics/accounting/dashboard-stats');
  }

  Future<Map<String, dynamic>> getRevenueExpenses({int months = 12}) async {
    return await get('/api/analytics/accounting/revenue-expenses?months=$months');
  }

  Future<Map<String, dynamic>> getCashFlow() async {
    return await get('/api/analytics/accounting/cash-flow');
  }

  Future<Map<String, dynamic>> getAgingAnalysis() async {
    return await get('/api/analytics/accounting/aging-analysis');
  }

  Future<Map<String, dynamic>> getExpenseBreakdown() async {
    return await get('/api/analytics/accounting/expense-breakdown');
  }

  Future<Map<String, dynamic>> getBudgetVsActual() async {
    return await get('/api/analytics/accounting/budget-vs-actual');
  }

  Future<Map<String, dynamic>> getProfitLoss({int quarters = 8}) async {
    return await get('/api/analytics/accounting/profit-loss?quarters=$quarters');
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
