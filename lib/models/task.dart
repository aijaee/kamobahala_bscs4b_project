/// Task model representing a task within a project
class Task {
  final String id;
  final String projectId;
  final String? assigneeId;
  final String? assigneeName;
  final String title;
  final String? description;
  final String? category;
  final String? status; // pending, in_progress, completed, etc.
  final String? priority; // low, medium, high, urgent
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.projectId,
    this.assigneeId,
    this.assigneeName,
    required this.title,
    this.description,
    this.category,
    this.status,
    this.priority,
    this.dueDate,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  /// Create Task from Supabase response
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String? ?? '',
      projectId: map['project_id'] as String? ?? '',
      assigneeId: map['assignee_id'] as String?,
      assigneeName: map['assignee_name'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      category: map['category'] as String?,
      status: map['status'] as String?,
      priority: map['priority'] as String?,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  /// Convert Task to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'assignee_id': assigneeId,
      'assignee_name': assigneeName,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Create a copy with some fields replaced
  Task copyWith({
    String? id,
    String? projectId,
    String? assigneeId,
    String? assigneeName,
    String? title,
    String? description,
    String? category,
    String? status,
    String? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Check if task is completed
  bool get isCompleted => status?.toLowerCase() == 'completed';

  /// Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  @override
  String toString() =>
      'Task(id: $id, title: $title, status: $status, priority: $priority)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
