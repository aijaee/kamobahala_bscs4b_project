import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'edit_task_screen.dart';
import '../../viewmodels/tasks_viewmodel.dart';
import '../../viewmodels/financial_viewmodel.dart';
import '../../models/task.dart';
import '../../models/organization_member.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/organization_service.dart';

class TaskDetailsScreen extends StatefulWidget {
  final dynamic task; // Can be Task or Map for legacy compatibility
  final String? organizationId;

  const TaskDetailsScreen({
    super.key,
    required this.task,
    this.organizationId,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late String _currentStatus;
  bool _isAdmin = false;
  bool _taskUpdated = false;
  final AdminService _adminService = AdminService();
  final OrganizationService _orgService = OrganizationService();

  @override
  void initState() {
    super.initState();
    final taskStatus = (widget.task is Map)
        ? widget.task['status']
        : (widget.task as Task).status;
    _currentStatus = taskStatus == 'Todo' || taskStatus == 'todo'
        ? 'To Do'
        : (taskStatus ?? 'To Do');
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final organizationId = widget.organizationId;
    if (organizationId != null) {
      final isAdmin = await _adminService.isUserAdmin(organizationId);
      if (mounted) {
        setState(() => _isAdmin = isAdmin);
      }
    }
  }

  Future<void> _refreshTask() async {
    // Refresh task data from the ViewModel
    try {
      final projectId = (widget.task is Map)
          ? widget.task['project_id']
          : (widget.task as Task).projectId;
      if (projectId != null && mounted) {
        final tasksViewModel = context.read<TasksViewModel>();
        await tasksViewModel.fetchProjectTasks(projectId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing task: $e')),
        );
      }
    }
  }

  Future<void> _toggleTaskCompletion() async {
    try {
      final taskId =
          (widget.task is Map) ? widget.task['id'] : (widget.task as Task).id;

      if (taskId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update task - missing ID')),
        );
        return;
      }

      final isMarkedComplete = _currentStatus.toLowerCase() == 'todo';
      final newStatus = isMarkedComplete ? 'completed' : 'todo';

      // Get viewmodels from Provider
      final tasksViewModel = context.read<TasksViewModel>();
      final financialViewModel = context.read<FinancialViewModel>();

      // Update task status through ViewModel (this will notify listeners)
      final updateSuccess =
          await tasksViewModel.updateTask(taskId, {'status': newStatus});

      if (!updateSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error updating task')),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _currentStatus = newStatus == 'completed' ? 'Completed' : 'To Do';
          _taskUpdated = true;
        });

        final organizationId = widget.organizationId;
        if (organizationId != null) {
          await financialViewModel.fetchTransactions(organizationId);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task marked as ${newStatus.toLowerCase()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: _refreshTask,
        color: const Color(0xFF137FEC),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(),
              _buildInfoGrid(),
              _buildDescription(),
              _buildFinancialDetailsCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final priority = (widget.task is Map)
        ? widget.task['priority']?.toString() ?? 'Low'
        : (widget.task as Task).priority?.toString() ?? 'Low';
    final title = (widget.task is Map)
        ? widget.task['title'] ?? 'Task Title'
        : (widget.task as Task).title;

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getPriorityColor(priority).withValues(alpha: 0.8),
            _getPriorityColor(priority).withValues(alpha: 0.4),
          ],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? 'Task Title',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    final priority = (widget.task is Map)
        ? widget.task['priority']?.toString().toUpperCase() ?? 'LOW'
        : (widget.task as Task).priority?.toString().toUpperCase() ?? 'LOW';
    final priorityColor = _getPriorityColor((widget.task is Map)
        ? widget.task['priority']?.toString() ?? 'Low'
        : (widget.task as Task).priority?.toString() ?? 'Low');
    final dueDate = (widget.task is Map)
        ? widget.task['due_date']
        : (widget.task as Task).dueDate;
    final dueDateStr = dueDate != null ? _formatDate(dueDate) : 'No date';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _buildGridItem(
                Icons.flag_rounded,
                "Priority",
                priority,
                priorityColor,
              ),
              const SizedBox(width: 16),
              _buildGridItem(
                Icons.sync,
                "Status",
                _currentStatus,
                const Color(0xFF137FEC),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildGridItem(
                Icons.calendar_today,
                "Due Date",
                dueDateStr,
                const Color(0xFF617589),
              ),
              const SizedBox(width: 16),
              FutureBuilder<String>(
                future: _getAssigneeDisplayName(),
                builder: (context, snapshot) {
                  final displayName = snapshot.data ?? 'Unassigned';
                  return _buildGridItem(
                    Icons.person,
                    "Assigned To",
                    displayName,
                    const Color(0xFF617589),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'Invalid date';
      }
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateValue.toString();
    }
  }

  Future<String> _getAssigneeDisplayName() async {
    final assigneeId = (widget.task is Map)
        ? widget.task['assignee_id'] ??
            widget.task['assignee'] ??
            widget.task['assignee_name']
        : (widget.task as Task).assigneeId ??
            (widget.task as Task).assigneeName;

    if (assigneeId != null) {
      try {
        final organizationId = widget.organizationId;
        if (organizationId == null) return assigneeId.toString();

        final members =
            await _orgService.getOrganizationMembers(organizationId);

        // Find member by ID from the typed list
        OrganizationMember? member;
        try {
          member = members.firstWhere(
            (m) =>
                m.userId == assigneeId ||
                m.email == assigneeId ||
                m.fullName == assigneeId,
          );
        } catch (e) {
          // Member not found
          return assigneeId.toString();
        }

        if (member.fullName != null && member.fullName!.isNotEmpty) {
          return member.fullName!;
        }
      } catch (e) {
        // Continue with ID fallback
      }
      return assigneeId.toString();
    }
    return 'Unassigned';
  }

  Widget _buildGridItem(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    final description = (widget.task is Map)
        ? widget.task['description'] ?? 'No description provided'
        : ((widget.task as Task).description ?? 'No description provided');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description'.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF111418),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialDetailsCard() {
    final taskData = widget.task is Map
        ? Map<String, dynamic>.from(widget.task as Map)
        : (widget.task as Task).toMap();
    final estimatedAmount = _toDouble(taskData['estimated_expense']) ?? 0.0;
    final expenseCategory =
        taskData['expense_category']?.toString() ?? 'Not specified';
    final deductFromBudget = taskData['deduct_from_budget'] as bool? ?? false;
    final amountLabel =
        deductFromBudget ? 'Estimated Expense' : 'Estimated Income';
    final amountColor =
        deductFromBudget ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final budgetModeColor =
        deductFromBudget ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Details'.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                amountLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF617589),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₱${estimatedAmount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF617589),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                expenseCategory,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Mode',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF617589),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: budgetModeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: budgetModeColor, width: 1),
                ),
                child: Text(
                  deductFromBudget ? 'Deduct from Budget' : 'Add to Budget',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: budgetModeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isCompleted = _currentStatus.toLowerCase() == 'completed';
    return AppBar(
      backgroundColor: const Color(0xFF137FEC),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context, _taskUpdated),
      ),
      title: Text(
        'Task Details',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: isCompleted ? const Color(0xFFA3E635) : Colors.white,
            size: 24,
          ),
          onPressed: () => _toggleTaskCompletion(),
        ),
        if (_isAdmin)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white, size: 20),
            onPressed: () async {
              final taskData = widget.task is Map
                  ? Map<String, dynamic>.from(widget.task as Map)
                  : (widget.task as Task).toMap();
              final projectId = taskData['project_id']?.toString();
              final organizationId = widget.organizationId ??
                  taskData['organization_id']?.toString();
              final taskId = taskData['id']?.toString() ?? '';

              if (projectId != null &&
                  organizationId != null &&
                  taskId.isNotEmpty) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditTaskScreen(
                      taskId: taskId,
                      projectId: projectId,
                      organizationId: organizationId,
                      task: taskData,
                    ),
                  ),
                );
                if (!mounted) return;
                if (result == true) {
                  Navigator.pop(context, true);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Unable to edit task - missing information')),
                );
              }
            },
          ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFEF4444);
      case 'MEDIUM':
        return const Color(0xFFF59E0B);
      case 'LOW':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
