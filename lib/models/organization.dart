/// Organization model representing a workspace/company
class Organization {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final double? budget;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Organization({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.budget,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create Organization from Supabase response
  factory Organization.fromMap(Map<String, dynamic> map) {
    return Organization(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      logoUrl: map['logo_url'] as String?,
      budget: _toDouble(map['budget']),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert Organization to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'budget': budget,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with some fields replaced
  Organization copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    double? budget,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      budget: budget ?? this.budget,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Organization(id: $id, name: $name, budget: $budget, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Organization &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Helper to convert dynamic values to double?
double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
