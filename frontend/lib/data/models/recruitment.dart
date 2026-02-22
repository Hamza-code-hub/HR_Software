class JobPosting {
  final String id;
  final String tenantId;
  final String title;
  final String department;
  final String location;
  final String employmentType;
  final String description;
  final String requirements;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  JobPosting({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.department,
    required this.location,
    required this.employmentType,
    required this.description,
    required this.requirements,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobPosting.fromJson(Map<String, dynamic> json) {
    return JobPosting(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      title: json['title'] as String,
      department: json['department'] as String? ?? '',
      location: json['location'] as String? ?? '',
      employmentType: json['employment_type'] as String? ?? 'Full-time',
      description: json['description'] as String? ?? '',
      requirements: json['requirements'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'title': title,
        'department': department,
        'location': location,
        'employment_type': employmentType,
        'description': description,
        'requirements': requirements,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class Candidate {
  final String id;
  final String tenantId;
  final String jobId;
  final String name;
  final String email;
  final String phone;
  final String resumeUrl;
  final String status;
  final String source;
  final DateTime appliedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined field
  final String? jobTitle;

  Candidate({
    required this.id,
    required this.tenantId,
    required this.jobId,
    required this.name,
    required this.email,
    required this.phone,
    required this.resumeUrl,
    required this.status,
    required this.source,
    required this.appliedDate,
    required this.createdAt,
    required this.updatedAt,
    this.jobTitle,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      jobId: json['job_id'] as String? ?? '',
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      resumeUrl: json['resume_url'] as String? ?? '',
      status: json['status'] as String? ?? 'new',
      source: json['source'] as String? ?? '',
      appliedDate: json['applied_date'] != null ? DateTime.parse(json['applied_date'] as String) : DateTime.now(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      jobTitle: json['job_title'] as String?,
    );
  }
}

class Interview {
  final String id;
  final String tenantId;
  final String candidateId;
  final String interviewerId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String location;
  final String meetingLink;
  final String status;
  final String? feedback;
  final int? rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined fields
  final String? candidateName;
  final String? interviewerName;

  Interview({
    required this.id,
    required this.tenantId,
    required this.candidateId,
    required this.interviewerId,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.location,
    required this.meetingLink,
    required this.status,
    this.feedback,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.candidateName,
    this.interviewerName,
  });

  factory Interview.fromJson(Map<String, dynamic> json) {
    return Interview(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      candidateId: json['candidate_id'] as String,
      interviewerId: json['interviewer_id'] as String? ?? '',
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      location: json['location'] as String? ?? '',
      meetingLink: json['meeting_link'] as String? ?? '',
      status: json['status'] as String? ?? 'scheduled',
      feedback: json['feedback'] as String?,
      rating: json['rating'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      candidateName: json['candidate_name'] as String?,
      interviewerName: json['interviewer_name'] as String?,
    );
  }
}
