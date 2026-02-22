import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/data/auth_repository.dart';
import 'package:frontend/data/models/hr_ops.dart';

class HROpsRepository {
  final String baseUrl;
  final String token;

  HROpsRepository({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ---------------------------------------------------------
  // HIRING REQUIREMENTS
  // ---------------------------------------------------------

  Future<List<ResourceRequirement>> getResourceRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/resource-requirements'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ResourceRequirement.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load resource requests: ${response.body}');
    }
  }

  Future<ResourceRequirement> createResourceRequest(ResourceRequirement req) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/resource-requirements'),
      headers: _headers,
      body: json.encode(req.toJson()),
    );

    if (response.statusCode == 201) {
      return ResourceRequirement.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create resource request: ${response.body}');
    }
  }

  Future<void> updateResourceRequestStatus(String id, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/resource-requirements/$id/$status'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update status: ${response.body}');
    }
  }

  // ---------------------------------------------------------
  // RESIGNATIONS
  // ---------------------------------------------------------

  Future<List<Resignation>> getResignations() async {
    final response = await http.get(Uri.parse('$baseUrl/api/resignations'), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Resignation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load resignations: ${response.body}');
    }
  }

  Future<Resignation> createResignation(Resignation res) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/resignations'),
      headers: _headers,
      body: json.encode(res.toJson()),
    );
    if (response.statusCode == 201) {
      return Resignation.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to submit resignation: ${response.body}');
    }
  }

  Future<void> updateResignationStatus(String id, String status, {String? clearanceStatus}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/resignations/$id/status'),
      headers: _headers,
      body: json.encode({
        'status': status,
        if (clearanceStatus != null) 'exit_clearance_status': clearanceStatus,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update resignation: ${response.body}');
    }
  }

  // ---------------------------------------------------------
  // EXIT CLEARANCE
  // ---------------------------------------------------------

  Future<List<ExitClearanceItem>> getClearanceItems(String resignationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/resignations/$resignationId/clearance'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ExitClearanceItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load clearance items: ${response.body}');
    }
  }

  Future<void> updateClearanceItem(String itemId, String status, String notes) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/resignations/clearance/$itemId'),
      headers: _headers,
      body: json.encode({'status': status, 'notes': notes}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update clearance item: ${response.body}');
    }
  }

  // ---------------------------------------------------------
  // EXIT INTERVIEW
  // ---------------------------------------------------------

  Future<ExitInterview?> getExitInterview(String resignationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/resignations/$resignationId/interview'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data == null) return null;
      return ExitInterview.fromJson(data);
    } else {
      throw Exception('Failed to load exit interview: ${response.body}');
    }
  }

  Future<void> saveExitInterview(ExitInterview interview) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/resignations/interview'),
      headers: _headers,
      body: json.encode(interview.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save exit interview: ${response.body}');
    }
  }
}

final hrOpsRepositoryProvider = Provider<HROpsRepository>((ref) {
  final session = ref.watch(sessionProvider);
  return HROpsRepository(
    baseUrl: const String.fromEnvironment('API_URL', defaultValue: 'http://127.0.0.1:3000'),
    token: session?.accessToken ?? '',
  );
});

final resourceRequestsProvider = FutureProvider<List<ResourceRequirement>>((ref) async {
  return ref.watch(hrOpsRepositoryProvider).getResourceRequests();
});

final resignationsProvider = FutureProvider<List<Resignation>>((ref) async {
  return ref.watch(hrOpsRepositoryProvider).getResignations();
});
