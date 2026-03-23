import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_task_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task; // FIXED: Explicit Map for [] operator

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    // FIXED: Align with your SQL check constraint
    _currentStatus = widget.task['status'] == 'Todo'
        ? 'To Do'
        : (widget.task['status'] ?? 'To Do');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
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
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getPriorityColor(widget.task['priority']?.toString() ?? 'Low').withValues(alpha: 0.8),
            _getPriorityColor(widget.task['priority']?.toString() ?? 'Low').withValues(alpha: 0.4),
          ],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.task['title'] ?? 'Task Title',
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _buildGridItem(
                Icons.flag_rounded,
                "Priority",
                widget.task['priority']?.toString().toUpperCase() ?? 'LOW',
                _getPriorityColor(widget.task['priority']?.toString() ?? 'Low'),
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
                widget.task['due_date'] != null
                    ? _formatDate(widget.task['due_date'])
                    : 'No date',
                const Color(0xFF617589),
              ),
              const SizedBox(width: 16),
              _buildGridItem(
                Icons.person,
                "Assigned To",
                widget.task['assigned_to'] ?? 'Unassigned',
                const Color(0xFF617589),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateString;
    }
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
            widget.task['description'] ?? 'No description provided',
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
    final estimatedExpense = widget.task['estimated_expense'] ?? 0.0;
    final expenseCategory = widget.task['expense_category'] ?? 'Not specified';
    final deductFromBudget = widget.task['deduct_from_budget'] ?? false;

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
                'Estimated Expense',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF617589),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\$${estimatedExpense.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF137FEC),
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
                'Expense Category',
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
                'Deduct from Budget',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF617589),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: deductFromBudget ? const Color(0xFFDEF7EC) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  deductFromBudget ? 'Yes' : 'No',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: deductFromBudget ? const Color(0xFF059669) : const Color(0xFFDC2626),
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
    return AppBar(
      backgroundColor: const Color(0xFF137FEC),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
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
          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
          onPressed: () {
            final projectId = widget.task['project_id'];
            final organizationId = widget.task['organization_id'];
            final taskId = widget.task['id'];
            
            if (projectId != null && organizationId != null && taskId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditTaskScreen(
                    taskId: taskId,
                    projectId: projectId,
                    organizationId: organizationId,
                    task: widget.task,
                  ),
                ),
              ).then((_) {
                Navigator.pop(context);
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unable to edit task - missing information')),
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
}
