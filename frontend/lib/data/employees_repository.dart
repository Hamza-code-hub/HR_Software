import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';

class Employee {
  final String id;
  final String tenantId;
  final String? userId;
  final String? employeeCode;
  final String name;
  final String? email;
  final String? cnic;
  final String? phone;
  final String? designation;
  final String? joiningDate;
  final String status;
  final double? basicSalary;
  final Map<String, dynamic>? allowances;
  final Map<String, dynamic>? deductions;
  final String createdAt;

  Employee({
    required this.id,
    required this.tenantId,
    this.userId,
    this.employeeCode,
    required this.name,
    this.email,
    this.cnic,
    this.phone,
    this.designation,
    this.joiningDate,
    required this.status,
    this.basicSalary,
    this.allowances,
    this.deductions,
    required this.createdAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      userId: json['user_id'] as String?,
      employeeCode: json['employee_code'] as String?,
      name: json['name'] as String,
      email: json['email'] as String?,
      cnic: json['cnic'] as String?,
      phone: json['phone'] as String?,
      designation: json['designation'] as String?,
      joiningDate: json['joining_date'] as String?,
      status: json['status'] as String? ?? 'active',
      basicSalary: (json['basic_salary'] as num?)?.toDouble(),
      allowances: json['allowances'] as Map<String, dynamic>?,
      deductions: json['deductions'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (employeeCode != null) 'employee_code': employeeCode,
      'name': name,
      if (email != null) 'email': email,
      if (cnic != null) 'cnic': cnic,
      if (phone != null) 'phone': phone,
      if (designation != null) 'designation': designation,
      if (joiningDate != null) 'joining_date': joiningDate,
      'status': status,
      if (basicSalary != null) 'basic_salary': basicSalary,
      if (allowances != null) 'allowances': allowances,
      if (deductions != null) 'deductions': deductions,
    };
  }
}

final employeesRepositoryProvider = Provider<EmployeesRepository>((ref) {
  return EmployeesRepository(ref.watch(apiClientProvider));
});

class EmployeesRepository {
  EmployeesRepository(this._client);

  final ApiClient _client;

  Future<List<Employee>> list() async {
    final res = await _client.dio.get('/api/employees');
    final list = res.data as List;
    return list.map((e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Employee> get(String id) async {
    final res = await _client.dio.get('/api/employees/$id');
    return Employee.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Employee> create(Employee employee) async {
    final res = await _client.dio.post('/api/employees', data: employee.toJson());
    return Employee.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Employee> update(String id, Employee employee) async {
    final res = await _client.dio.put('/api/employees/$id', data: employee.toJson());
    return Employee.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.dio.delete('/api/employees/$id');
  }
}

final employeesListProvider = FutureProvider.autoDispose<List<Employee>>((ref) async {
  final repo = ref.watch(employeesRepositoryProvider);
  return repo.list();
});
