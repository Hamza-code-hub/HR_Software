class EmployeeDocument {
  final String id;
  final String tenantId;
  final String employeeId;
  final String documentName;
  final String documentType;
  final String documentUrl;
  final DateTime uploadDate;
  final DateTime? expiryDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined field
  final String? employeeName;

  EmployeeDocument({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.documentName,
    required this.documentType,
    required this.documentUrl,
    required this.uploadDate,
    this.expiryDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.employeeName,
  });

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) {
    return EmployeeDocument(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String,
      documentName: json['document_name'] as String,
      documentType: json['document_type'] as String? ?? 'Other',
      documentUrl: json['document_url'] as String,
      uploadDate: DateTime.parse(json['upload_date'] as String),
      expiryDate: json['expiry_date'] != null ? DateTime.tryParse(json['expiry_date'] as String) : null,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      employeeName: json['employee_name'] as String?,
    );
  }
}

class ProbationRecord {
  final String id;
  final String tenantId;
  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime? reviewDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined field
  final String? employeeName;

  ProbationRecord({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reviewDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.employeeName,
  });

  factory ProbationRecord.fromJson(Map<String, dynamic> json) {
    return ProbationRecord(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: json['status'] as String? ?? 'active',
      reviewDate: json['review_date'] != null ? DateTime.tryParse(json['review_date'] as String) : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      employeeName: json['employee_name'] as String?,
    );
  }
}

class EmployeePromotion {
  final String id;
  final String tenantId;
  final String employeeId;
  final String previousDesignation;
  final String newDesignation;
  final double previousSalary;
  final double newSalary;
  final String type;
  final DateTime effectiveDate;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined field
  final String? employeeName;

  EmployeePromotion({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.previousDesignation,
    required this.newDesignation,
    required this.previousSalary,
    required this.newSalary,
    required this.type,
    required this.effectiveDate,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.employeeName,
  });

  factory EmployeePromotion.fromJson(Map<String, dynamic> json) {
    return EmployeePromotion(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String,
      previousDesignation: json['previous_designation'] as String? ?? '',
      newDesignation: json['new_designation'] as String? ?? '',
      previousSalary: (json['previous_salary'] as num?)?.toDouble() ?? 0.0,
      newSalary: (json['new_salary'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? 'Promotion',
      effectiveDate: DateTime.parse(json['effective_date'] as String),
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      employeeName: json['employee_name'] as String?,
    );
  }
}
