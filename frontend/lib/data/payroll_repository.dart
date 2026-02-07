import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';

class PayrollRun {
  final String id;
  final String tenantId;
  final int month;
  final int year;
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
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class Payslip {
  final String id;
  final String tenantId;
  final String payrollRunId;
  final String employeeId;
  final double basicSalary;
  final double grossSalary;
  final double tax;
  final double netSalary;

  Payslip({
    required this.id,
    required this.tenantId,
    required this.payrollRunId,
    required this.employeeId,
    required this.basicSalary,
    required this.grossSalary,
    required this.tax,
    required this.netSalary,
  });

  factory Payslip.fromJson(Map<String, dynamic> json) {
    return Payslip(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      payrollRunId: json['payroll_run_id'] as String,
      employeeId: json['employee_id'] as String,
      basicSalary: (json['basic_salary'] as num).toDouble(),
      grossSalary: (json['gross_salary'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      netSalary: (json['net_salary'] as num).toDouble(),
    );
  }
}

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  return PayrollRepository(ref.watch(apiClientProvider));
});

class PayrollRepository {
  PayrollRepository(this._client);

  final ApiClient _client;

  Future<List<PayrollRun>> listRuns() async {
    final res = await _client.dio.get('/api/payroll');
    final list = res.data as List;
    return list.map((e) => PayrollRun.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PayrollRun> getRun(String id) async {
    final res = await _client.dio.get('/api/payroll/$id');
    return PayrollRun.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PayrollRun> createRun(int month, int year) async {
    final res = await _client.dio.post('/api/payroll/run', data: {'month': month, 'year': year});
    return PayrollRun.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> lockRun(String id) async {
    await _client.dio.post('/api/payroll/lock', data: {'id': id});
  }

  Future<List<Payslip>> listPayslips(String runId) async {
    final res = await _client.dio.get('/api/payroll/$runId/payslips');
    final list = res.data as List;
    return list.map((e) => Payslip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Uint8List> getPayslipPdf(String payslipId) async {
    // Note: This needs proper implementation for binary responses
    // For now, returning empty bytes to allow compilation
    throw UnimplementedError('Binary PDF download needs proper HTTP handling');
  }
}
