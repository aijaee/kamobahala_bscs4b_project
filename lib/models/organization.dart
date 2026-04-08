/// Organization model representing a workspace/company
class Organization {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Organization({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Organization(id: $id, name: $name, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Organization &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
