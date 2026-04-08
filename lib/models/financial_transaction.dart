/// Financial transaction model representing financial records
class FinancialTransaction {
  final String id;
  final String organizationId;
  final String? projectId;
  final String? taskId;
  final String title;
  final String? description;
  final String? department;
  final String transactionType; // income, expense, transfer
  final double amount;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FinancialTransaction({
    required this.id,
    required this.organizationId,
    this.projectId,
    this.taskId,
    required this.title,
    this.description,
    this.department,
    required this.transactionType,
    required this.amount,
    required this.occurredAt,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create FinancialTransaction from Supabase response
  factory FinancialTransaction.fromMap(Map<String, dynamic> map) {
    return FinancialTransaction(
      id: map['id'] as String? ?? '',
      organizationId: map['organization_id'] as String? ?? '',
      projectId: map['project_id'] as String?,
      taskId: map['task_id'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      department: map['department'] as String?,
      transactionType: map['transaction_type'] as String? ?? 'expense',
      amount: _toDouble(map['amount']) ?? 0.0,
      occurredAt: map['occurred_at'] != null
          ? DateTime.parse(map['occurred_at'] as String)
          : DateTime.now(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert FinancialTransaction to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'project_id': projectId,
      'task_id': taskId,
      'title': title,
      'description': description,
      'department': department,
      'transaction_type': transactionType,
      'amount': amount,
      'occurred_at': occurredAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with some fields replaced
  FinancialTransaction copyWith({
    String? id,
    String? organizationId,
    String? projectId,
    String? taskId,
    String? title,
    String? description,
    String? department,
    String? transactionType,
    double? amount,
    DateTime? occurredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      department: department ?? this.department,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if transaction is an income
  bool get isIncome => transactionType.toLowerCase() == 'income';

  /// Check if transaction is an expense
  bool get isExpense => transactionType.toLowerCase() == 'expense';

  @override
  String toString() =>
      'FinancialTransaction(id: $id, title: $title, amount: $amount, type: $transactionType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialTransaction &&
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
