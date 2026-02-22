import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import 'models/operations.dart';

final operationsRepositoryProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return OperationsRepository(client);
});

final shiftsProvider = FutureProvider<List<Shift>>((ref) async {
  return ref.watch(operationsRepositoryProvider).listShifts();
});

final timesheetsProvider = FutureProvider<List<Timesheet>>((ref) async {
  return ref.watch(operationsRepositoryProvider).listTimesheets();
});

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  return ref.watch(operationsRepositoryProvider).listProjects();
});

final overtimeRequestsProvider = FutureProvider<List<OvertimeRequest>>((ref) async {
  return ref.watch(operationsRepositoryProvider).listOvertime();
});

class OperationsRepository {
  final ApiClient _client;

  OperationsRepository(this._client);

  Future<List<Shift>> listShifts() async {
    final res = await _client.get('/api/operations/shifts');
    return (res as List).map((e) => Shift.fromJson(e)).toList();
  }

  Future<List<Timesheet>> listTimesheets() async {
    final res = await _client.get('/api/operations/timesheets');
    return (res as List).map((e) => Timesheet.fromJson(e)).toList();
  }

  Future<Timesheet> createTimesheet(Map<String, dynamic> data) async {
    final res = await _client.post('/api/operations/timesheets', body: data);
    return Timesheet.fromJson(res);
  }

  Future<List<Project>> listProjects() async {
    final res = await _client.get('/api/operations/projects');
    return (res as List).map((e) => Project.fromJson(e)).toList();
  }

  Future<Project> createProject(Map<String, dynamic> data) async {
    final res = await _client.post('/api/operations/projects', body: data);
    return Project.fromJson(res);
  }

  Future<List<OvertimeRequest>> listOvertime() async {
    final res = await _client.get('/api/operations/overtime');
    return (res as List).map((e) => OvertimeRequest.fromJson(e)).toList();
  }

  Future<OvertimeRequest> createOvertime(Map<String, dynamic> data) async {
    final res = await _client.post('/api/operations/overtime', body: data);
    return OvertimeRequest.fromJson(res);
  }
}
