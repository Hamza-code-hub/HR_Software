class Training {
  final String id;
  final String tenantId;
  final String title;
  final String description;
  final String trainerName;
  final int durationHours;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Training({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.description,
    required this.trainerName,
    required this.durationHours,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      trainerName: json['trainer'] as String? ?? 'N/A',
      durationHours: json['duration_hours'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class PerformanceReview {
  final String id;
  final String tenantId;
  final String employeeId;
  final String reviewerId;
  final DateTime reviewDate;
  final double overallScore;
  final String comments;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joins
  final String? employeeName;
  final String? reviewerName;

  PerformanceReview({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.reviewerId,
    required this.reviewDate,
    required this.overallScore,
    required this.comments,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.employeeName,
    this.reviewerName,
  });

  factory PerformanceReview.fromJson(Map<String, dynamic> json) {
    return PerformanceReview(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      reviewDate: DateTime.parse(json['review_date'] as String),
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
      comments: json['comments'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      employeeName: json['employee_name'] as String?,
      reviewerName: json['reviewer_name'] as String?,
    );
  }
}
