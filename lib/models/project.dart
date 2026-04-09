/// Project model representing a project within an organization
class Project {
  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final double? budget;
  final String? status; // active, completed, archived, etc.
  final String? repositoryUrl;
  final String? repositoryConfig;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Project({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    this.budget,
    this.status,
    this.repositoryUrl,
    this.repositoryConfig,
    this.startDate,
    this.endDate,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create Project from Supabase response
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String? ?? '',
      organizationId: map['organization_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      budget: _toDouble(map['budget']),
      status: map['status'] as String?,
      repositoryUrl: map['repository_url'] as String?,
      repositoryConfig: map['repository_config'] as String?,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert Project to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      'description': description,
      'budget': budget,
      'status': status,
      'repository_url': repositoryUrl,
      'repository_config': repositoryConfig,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with some fields replaced
  Project copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? description,
    double? budget,
    String? status,
    String? repositoryUrl,
    String? repositoryConfig,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      repositoryUrl: repositoryUrl ?? this.repositoryUrl,
      repositoryConfig: repositoryConfig ?? this.repositoryConfig,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Project(id: $id, name: $name, status: $status, budget: $budget)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Helper to convert dynamic values to double
double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
