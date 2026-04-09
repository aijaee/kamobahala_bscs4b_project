/// Organization member model representing a user's role in an organization
class OrganizationMember {
  final String id;
  final String organizationId;
  final String userId;
  final String email;
  final String? fullName;
  final String role; // Admin, Member, Viewer, etc.
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrganizationMember({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.email,
    this.fullName,
    required this.role,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create OrganizationMember from Supabase response
  factory OrganizationMember.fromMap(Map<String, dynamic> map) {
    return OrganizationMember(
      id: map['id'] as String? ?? '',
      organizationId: map['organization_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? map['name'] as String?,
      role: map['role'] as String? ?? 'Member',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert OrganizationMember to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with some fields replaced
  OrganizationMember copyWith({
    String? id,
    String? organizationId,
    String? userId,
    String? email,
    String? fullName,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganizationMember(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'OrganizationMember(id: $id, email: $email, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationMember &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
