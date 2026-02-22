import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import 'models/employee_central.dart';

final employeeCentralRepositoryProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return EmployeeCentralRepository(client);
});

final employeeDocumentsProvider = FutureProvider<List<EmployeeDocument>>((ref) async {
  return ref.watch(employeeCentralRepositoryProvider).listDocuments();
});

final probationRecordsProvider = FutureProvider<List<ProbationRecord>>((ref) async {
  return ref.watch(employeeCentralRepositoryProvider).listProbation();
});

final employeePromotionsProvider = FutureProvider<List<EmployeePromotion>>((ref) async {
  return ref.watch(employeeCentralRepositoryProvider).listPromotions();
});

class EmployeeCentralRepository {
  final ApiClient _client;

  EmployeeCentralRepository(this._client);

  Future<List<EmployeeDocument>> listDocuments() async {
    final res = await _client.get('/api/employee-central/documents');
    return (res.data as List).map((e) => EmployeeDocument.fromJson(e)).toList();
  }

  Future<List<ProbationRecord>> listProbation() async {
    final res = await _client.get('/api/employee-central/probation');
    return (res.data as List).map((e) => ProbationRecord.fromJson(e)).toList();
  }

  Future<List<EmployeePromotion>> listPromotions() async {
    final res = await _client.get('/api/employee-central/promotions');
    return (res.data as List).map((e) => EmployeePromotion.fromJson(e)).toList();
  }
}
