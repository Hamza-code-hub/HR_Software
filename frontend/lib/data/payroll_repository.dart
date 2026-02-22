import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';

// ────────────────────────────────────────────────────────────────
// Models
// ────────────────────────────────────────────────────────────────
class PayrollRun {
  final String id;
  final String tenantId;
  final int    month;
  final int    year;
  final String status;
  final String createdAt;

  PayrollRun({
    required this.id,
    required this.tenantId,
    required this.month,
    required this.year,
    required this.status,
    required this.createdAt,
  });

  factory PayrollRun.fromJson(Map<String, dynamic> json) {
    return PayrollRun(
      id:        json['id']         as String,
      tenantId:  json['tenant_id']  as String,
      month:     json['month']      as int,
      year:      json['year']       as int,
      status:    json['status']     as String,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  bool get isLocked => status == 'locked';
}

class Payslip {
  final String id;
  final String tenantId;
  final String payrollRunId;
  final String employeeId;
  final String? employeeName;
  final double basicSalary;
  final double grossSalary;
  final double tax;
  final double netSalary;

  Payslip({
    required this.id,
    required this.tenantId,
    required this.payrollRunId,
    required this.employeeId,
    this.employeeName,
    required this.basicSalary,
    required this.grossSalary,
    required this.tax,
    required this.netSalary,
  });

  factory Payslip.fromJson(Map<String, dynamic> json) {
    return Payslip(
      id:           json['id']             as String,
      tenantId:     json['tenant_id']      as String,
      payrollRunId: json['payroll_run_id'] as String,
      employeeId:   json['employee_id']    as String,
      employeeName: json['employee_name']  as String?,
      basicSalary:  (json['basic_salary']  as num).toDouble(),
      grossSalary:  (json['gross_salary']  as num).toDouble(),
      tax:          (json['tax']           as num).toDouble(),
      netSalary:    (json['net_salary']    as num).toDouble(),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Repository
// ────────────────────────────────────────────────────────────────
final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  return PayrollRepository(ref.watch(apiClientProvider));
});

class PayrollRepository {
  PayrollRepository(this._client);
  final ApiClient _client;

  Future<List<PayrollRun>> listRuns() async {
    final res = await _client.get('/api/payroll') as List;
    return res.map((e) => PayrollRun.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PayrollRun> getRun(String id) async {
    final res = await _client.get('/api/payroll/$id') as Map<String, dynamic>;
    return PayrollRun.fromJson(res);
  }

  Future<PayrollRun> createRun(int month, int year) async {
    final res = await _client.post('/api/payroll/run', body: {'month': month, 'year': year}) as Map<String, dynamic>;
    return PayrollRun.fromJson(res);
  }

  Future<void> lockRun(String id) async {
    await _client.post('/api/payroll/lock', body: {'id': id});
  }

  Future<List<Payslip>> listPayslips(String runId) async {
    final res = await _client.get('/api/payroll/$runId/payslips') as List;
    return res.map((e) => Payslip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Uint8List> getPayslipPdf(String payslipId) async {
    return _client.getBytes('/api/payslips/$payslipId/pdf');
  }
}

// ────────────────────────────────────────────────────────────────
// Providers
// ────────────────────────────────────────────────────────────────
final payrollRunsProvider = FutureProvider.autoDispose<List<PayrollRun>>((ref) async {
  return ref.watch(payrollRepositoryProvider).listRuns();
});
