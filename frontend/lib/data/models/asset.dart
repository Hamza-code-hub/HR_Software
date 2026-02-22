class Asset {
  final String id;
  final String tenantId;
  final String name;
  final String type;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final String status;
  final String condition;
  final String? notes;

  Asset({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.type,
    this.serialNumber,
    this.purchaseDate,
    required this.status,
    required this.condition,
    this.notes,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      serialNumber: json['serial_number'] as String?,
      purchaseDate: json['purchase_date'] != null ? DateTime.tryParse(json['purchase_date'] as String) : null,
      status: json['status'] as String? ?? 'available',
      condition: json['condition'] as String? ?? 'new',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'name': name,
        'type': type,
        'serial_number': serialNumber,
        'purchase_date': purchaseDate?.toIso8601String(),
        'status': status,
        'condition': condition,
        'notes': notes,
      };
}

class AssetAssignment {
  final String id;
  final String tenantId;
  final String assetId;
  final String employeeId;
  final DateTime assignedDate;
  final DateTime? returnedDate;
  final String? conditionOut;
  final String? conditionIn;
  final String? notes;
  
  // Joined fields
  final String? assetName;
  final String? employeeName;

  AssetAssignment({
    required this.id,
    required this.tenantId,
    required this.assetId,
    required this.employeeId,
    required this.assignedDate,
    this.returnedDate,
    this.conditionOut,
    this.conditionIn,
    this.notes,
    this.assetName,
    this.employeeName,
  });

  factory AssetAssignment.fromJson(Map<String, dynamic> json) {
    return AssetAssignment(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      assetId: json['asset_id'] as String,
      employeeId: json['employee_id'] as String,
      assignedDate: DateTime.parse(json['assigned_date'] as String),
      returnedDate: json['returned_date'] != null ? DateTime.tryParse(json['returned_date'] as String) : null,
      conditionOut: json['condition_out'] as String?,
      conditionIn: json['condition_in'] as String?,
      notes: json['notes'] as String?,
      assetName: json['asset_name'] as String?,
      employeeName: json['employee_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'asset_id': assetId,
        'employee_id': employeeId,
        'assigned_date': assignedDate.toIso8601String(),
        'returned_date': returnedDate?.toIso8601String(),
        'condition_out': conditionOut,
        'condition_in': conditionIn,
        'notes': notes,
      };
}

class AssetRequest {
  final String id;
  final String tenantId;
  final String employeeId;
  final String requestedType;
  final String? justification;
  final String status;
  final String priority;
  final String? notes;
  final DateTime? createdAt;
  
  // Joined fields
  final String? employeeName;

  AssetRequest({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.requestedType,
    this.justification,
    required this.status,
    required this.priority,
    this.notes,
    this.createdAt,
    this.employeeName,
  });

  factory AssetRequest.fromJson(Map<String, dynamic> json) {
    return AssetRequest(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String,
      requestedType: json['requested_type'] as String,
      justification: json['justification'] as String?,
      status: json['status'] as String? ?? 'pending',
      priority: json['priority'] as String? ?? 'normal',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      employeeName: json['employee_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'employee_id': employeeId,
        'requested_type': requestedType,
        'justification': justification,
        'status': status,
        'priority': priority,
        'notes': notes,
      };
}
