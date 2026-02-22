class Announcement {
  final String id;
  final String tenantId;
  final String postedById;
  final String title;
  final String content;
  final String priority;
  final String category;
  final String targetAudience;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Join
  final String? postedByName;

  Announcement({
    required this.id,
    required this.tenantId,
    required this.postedById,
    required this.title,
    required this.content,
    required this.priority,
    required this.category,
    required this.targetAudience,
    required this.isActive,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.postedByName,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      postedById: json['posted_by_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      priority: json['priority'] as String? ?? 'normal',
      category: json['category'] as String? ?? 'general',
      targetAudience: json['target_audience'] as String? ?? 'all',
      isActive: json['is_active'] as bool? ?? true,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      postedByName: json['posted_by_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'posted_by_id': postedById,
        'title': title,
        'content': content,
        'priority': priority,
        'category': category,
        'target_audience': targetAudience,
        'is_active': isActive,
        'expires_at': expiresAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
