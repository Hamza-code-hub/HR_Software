import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/asset.dart';
import 'auth_repository.dart';

class AssetRepository {
  final String baseUrl;
  final String token;

  AssetRepository({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // --- ASSETS ---

  Future<List<Asset>> getAssets() async {
    final response = await http.get(Uri.parse('$baseUrl/api/assets'), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Asset.fromJson(json)).toList();
    }
    throw Exception('Failed to load assets: ${response.statusCode} - ${response.body}');
  }

  Future<Asset> createAsset(Map<String, dynamic> assetData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/assets'),
      headers: _headers,
      body: json.encode(assetData),
    );
    if (response.statusCode == 201) {
      return Asset.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create asset: ${response.statusCode} - ${response.body}');
  }

  Future<Asset> updateAsset(String id, Map<String, dynamic> assetData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/assets/$id'),
      headers: _headers,
      body: json.encode(assetData),
    );
    if (response.statusCode == 200) {
      return Asset.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update asset: ${response.statusCode} - ${response.body}');
  }

  Future<void> deleteAsset(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/assets/$id'), headers: _headers);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete asset: ${response.statusCode} - ${response.body}');
    }
  }

  // --- ASSIGNMENTS ---

  Future<List<AssetAssignment>> getAssignments({String? employeeId}) async {
    final uri = Uri.parse('$baseUrl/api/assets/assignments').replace(
      queryParameters: employeeId != null ? {'employee_id': employeeId} : null,
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => AssetAssignment.fromJson(json)).toList();
    }
    throw Exception('Failed to load assignments: ${response.statusCode} - ${response.body}');
  }

  Future<AssetAssignment> assignAsset(Map<String, dynamic> assignmentData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/assets/assignments'),
      headers: _headers,
      body: json.encode(assignmentData),
    );
    if (response.statusCode == 201) {
      return AssetAssignment.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to assign asset: ${response.statusCode} - ${response.body}');
  }

  Future<void> returnAsset(String assignmentId, String conditionIn) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/assets/assignments/$assignmentId/return'),
      headers: _headers,
      body: json.encode({'condition_in': conditionIn}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to return asset: ${response.statusCode} - ${response.body}');
    }
  }

  // --- REQUESTS ---

  Future<List<AssetRequest>> getAssetRequests() async {
    final response = await http.get(Uri.parse('$baseUrl/api/asset-requests'), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => AssetRequest.fromJson(json)).toList();
    }
    throw Exception('Failed to load asset requests: ${response.statusCode} - ${response.body}');
  }

  Future<AssetRequest> createAssetRequest(Map<String, dynamic> requestData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/asset-requests'),
      headers: _headers,
      body: json.encode(requestData),
    );
    if (response.statusCode == 201) {
      return AssetRequest.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create asset request: ${response.statusCode} - ${response.body}');
  }

  Future<void> updateAssetRequestStatus(String requestId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/asset-requests/$requestId/status'),
      headers: _headers,
      body: json.encode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update asset request status: ${response.statusCode} - ${response.body}');
    }
  }
}

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  final session = ref.watch(sessionProvider);
  return AssetRepository(
    baseUrl: const String.fromEnvironment('API_URL', defaultValue: 'http://127.0.0.1:3000'),
    token: session?.accessToken ?? '',
  );
});

final assetsListProvider = FutureProvider.autoDispose<List<Asset>>((ref) async {
  final repo = ref.watch(assetRepositoryProvider);
  return repo.getAssets();
});

final assetAssignmentsProvider = FutureProvider.autoDispose.family<List<AssetAssignment>, String?>((ref, employeeId) async {
  final repo = ref.watch(assetRepositoryProvider);
  return repo.getAssignments(employeeId: employeeId);
});

final assetRequestsProvider = FutureProvider.autoDispose<List<AssetRequest>>((ref) async {
  final repo = ref.watch(assetRepositoryProvider);
  return repo.getAssetRequests();
});
