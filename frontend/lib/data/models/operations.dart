class Shift {
  final String id;
  final String tenantId;
  final String name;
  final String startTime;
  final String endTime;
  final int gracePeriodMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shift({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.gracePeriodMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      gracePeriodMinutes: json['grace_period_minutes'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class Timesheet {
  final String id;
  final String tenantId;
  final String employeeId;
  final DateTime date;
  final String taskDescription;
  final double hoursWorked;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Join
  final String? employeeName;

  Timesheet({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.date,
    required this.taskDescription,
    required this.hoursWorked,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.employeeName,
  });

  factory Timesheet.fromJson(Map<String, dynamic> json) {
    return Timesheet(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String,
      date: DateTime.parse(json['date'] as String),
      taskDescription: json['task_description'] as String? ?? '',
      hoursWorked: (json['hours_worked'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      employeeName: json['employee_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'employee_id': employeeId,
        'date': date.toIso8601String(),
        'task_description': taskDescription,
        'hours_worked': hoursWorked,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class Project {
  final String id;
  final String tenantId;
  final String name;
  final String clientName;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.clientName,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      clientName: json['client_name'] as String? ?? 'Internal',
      description: json['description'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class OvertimeRequest {
  final String id;
  final String tenantId;
  final String employeeId;
  final DateTime date;
  final double hoursRequested;
  final String reason;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Join
  final String? employeeName;

  OvertimeRequest({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.date,
    required this.hoursRequested,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.employeeName,
  });

  factory OvertimeRequest.fromJson(Map<String, dynamic> json) {
    return OvertimeRequest(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String,
      date: DateTime.parse(json['date'] as String),
      hoursRequested: (json['hours'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      employeeName: json['employee_name'] as String?,
    );
  }
}
