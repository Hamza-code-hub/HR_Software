class OfferLetter {
  final String id;
  final String candidateId;
  final String jobId;
  final double salaryOffered;
  final DateTime? joiningDate;
  final DateTime? validUntil;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final String? candidateName;
  final String? jobTitle;

  OfferLetter({
    required this.id,
    required this.candidateId,
    required this.jobId,
    required this.salaryOffered,
    this.joiningDate,
    this.validUntil,
    required this.status,
    this.notes,
    required this.createdAt,
    this.candidateName,
    this.jobTitle,
  });

  factory OfferLetter.fromJson(Map<String, dynamic> json) {
    return OfferLetter(
      id: json['id'] as String,
      candidateId: json['candidate_id'] as String,
      jobId: json['job_id'] as String,
      salaryOffered: (json['salary_offered'] as num).toDouble(),
      joiningDate: json['joining_date'] != null ? DateTime.parse(json['joining_date'] as String) : null,
      validUntil: json['valid_until'] != null ? DateTime.parse(json['valid_until'] as String) : null,
      status: json['status'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      candidateName: json['candidate_name'] as String?,
      jobTitle: json['job_title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidate_id': candidateId,
      'job_id': jobId,
      'salary_offered': salaryOffered,
      'joining_date': joiningDate?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }
}

class EmployeeContract {
  final String id;
  final String employeeId;
  final String contractType;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final String? documentUrl;
  final DateTime createdAt;
  final String? employeeName;

  EmployeeContract({
    required this.id,
    required this.employeeId,
    required this.contractType,
    required this.startDate,
    this.endDate,
    required this.status,
    this.documentUrl,
    required this.createdAt,
    this.employeeName,
  });

  factory EmployeeContract.fromJson(Map<String, dynamic> json) {
    return EmployeeContract(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      contractType: json['contract_type'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      status: json['status'] as String? ?? 'active',
      documentUrl: json['document_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      employeeName: json['employee_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'contract_type': contractType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'document_url': documentUrl,
    };
  }
}
