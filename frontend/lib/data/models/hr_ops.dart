class ResourceRequirement {
  final String id;
  final String tenantId;
  final String requestedById;
  final String departmentId;
  final String resourceName;
  final int quantity;
  final String priority;
  final String status;
  final String? justification;
  final DateTime requestedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? requestedByName;
  final String? departmentName;

  ResourceRequirement({
    required this.id,
    required this.tenantId,
    required this.requestedById,
    required this.departmentId,
    required this.resourceName,
    required this.quantity,
    required this.priority,
    required this.status,
    this.justification,
    required this.requestedDate,
    required this.createdAt,
    required this.updatedAt,
    this.requestedByName,
    this.departmentName,
  });

  factory ResourceRequirement.fromJson(Map<String, dynamic> json) {
    return ResourceRequirement(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      requestedById: json['requested_by_id'] as String,
      departmentId: json['department_id'] as String,
      resourceName: json['resource_name'] as String,
      quantity: json['quantity'] as int? ?? 1,
      priority: json['priority'] as String? ?? 'normal',
      status: json['status'] as String? ?? 'pending',
      justification: json['justification'] as String?,
      requestedDate: DateTime.parse(json['requested_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      requestedByName: json['requested_by_name'] as String?,
      departmentName: json['department_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requested_by_id': requestedById,
      'department_id': departmentId,
      'resource_name': resourceName,
      'quantity': quantity,
      'priority': priority,
      'status': status,
      'justification': justification,
    };
  }
}

class Resignation {
  final String id;
  final String tenantId;
  final String employeeId;
  final DateTime resignationDate;
  final DateTime? lastWorkingDay;
  final String? reason;
  final String status;
  final String exitClearanceStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? employeeName;

  Resignation({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.resignationDate,
    this.lastWorkingDay,
    this.reason,
    required this.status,
    required this.exitClearanceStatus,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.employeeName,
  });

  factory Resignation.fromJson(Map<String, dynamic> json) {
    return Resignation(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String,
      resignationDate: DateTime.parse(json['resignation_date'] as String),
      lastWorkingDay: json['last_working_day'] != null ? DateTime.parse(json['last_working_day'] as String) : null,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'pending',
      exitClearanceStatus: json['exit_clearance_status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      employeeName: json['employee_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'resignation_date': resignationDate.toIso8601String(),
      'last_working_day': lastWorkingDay?.toIso8601String(),
      'reason': reason,
      'status': status,
      'exit_clearance_status': exitClearanceStatus,
      'notes': notes,
    };
  }
}

class ExitClearanceItem {
  final String id;
  final String tenantId;
  final String resignationId;
  final String department;
  final String itemName;
  final String status;
  final String? clearedById;
  final DateTime? clearedAt;
  final String? notes;

  ExitClearanceItem({
    required this.id,
    required this.tenantId,
    required this.resignationId,
    required this.department,
    required this.itemName,
    required this.status,
    this.clearedById,
    this.clearedAt,
    this.notes,
  });

  factory ExitClearanceItem.fromJson(Map<String, dynamic> json) {
    return ExitClearanceItem(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      resignationId: json['resignation_id'] as String,
      department: json['department'] as String,
      itemName: json['item_name'] as String,
      status: json['status'] as String? ?? 'pending',
      clearedById: json['cleared_by_id'] as String?,
      clearedAt: json['cleared_at'] != null ? DateTime.parse(json['cleared_at'] as String) : null,
      notes: json['notes'] as String?,
    );
  }
}

class ExitInterview {
  final String? id;
  final String? tenantId;
  final String resignationId;
  final DateTime? interviewDate;
  final String? interviewerId;
  final String reasonForLeaving;
  final String feedbackManagement;
  final String feedbackCulture;
  final bool recommendCompany;
  final String additionalComments;

  ExitInterview({
    this.id,
    this.tenantId,
    required this.resignationId,
    this.interviewDate,
    this.interviewerId,
    required this.reasonForLeaving,
    required this.feedbackManagement,
    required this.feedbackCulture,
    required this.recommendCompany,
    required this.additionalComments,
  });

  factory ExitInterview.fromJson(Map<String, dynamic> json) {
    return ExitInterview(
      id: json['id'] as String?,
      tenantId: json['tenant_id'] as String?,
      resignationId: json['resignation_id'] as String,
      interviewDate: json['interview_date'] != null ? DateTime.parse(json['interview_date'] as String) : null,
      interviewerId: json['interviewer_id'] as String?,
      reasonForLeaving: json['reason_for_leaving'] as String? ?? '',
      feedbackManagement: json['feedback_management'] as String? ?? '',
      feedbackCulture: json['feedback_culture'] as String? ?? '',
      recommendCompany: json['recommend_company'] as bool? ?? true,
      additionalComments: json['additional_comments'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resignation_id': resignationId,
      'reason_for_leaving': reasonForLeaving,
      'feedback_management': feedbackManagement,
      'feedback_culture': feedbackCulture,
      'recommend_company': recommendCompany,
      'additional_comments': additionalComments,
    };
  }
}
