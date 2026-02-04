import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';

class AttendanceRecord {
  final String id;
  final String tenantId;
  final String employeeId;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final double? totalHours;
  final String? status;

  AttendanceRecord({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.totalHours,
    this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String,
      date: json['date'] as String,
      checkIn: json['check_in'] as String?,
      checkOut: json['check_out'] as String?,
      totalHours: (json['total_hours'] as num?)?.toDouble(),
      status: json['status'] as String?,
    );
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(apiClientProvider));
});

class AttendanceRepository {
  AttendanceRepository(this._client);

  final ApiClient _client;

  Future<List<AttendanceRecord>> list(int month, int year) async {
    final res = await _client.dio.get('/api/attendance', queryParameters: {'month': month, 'year': year});
    final list = res.data as List;
    return list.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> checkIn(String employeeId) async {
    await _client.dio.post('/api/attendance/checkin', data: {'employee_id': employeeId});
  }

  Future<void> checkOut(String employeeId) async {
    await _client.dio.post('/api/attendance/checkout', data: {'employee_id': employeeId});
  }
}
