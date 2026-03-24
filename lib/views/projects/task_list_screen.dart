import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kamobahala_bscs4b_project/viewmodels/tasks_viewmodel.dart';
import 'package:kamobahala_bscs4b_project/viewmodels/financial_viewmodel.dart';
import 'package:kamobahala_bscs4b_project/core/services/admin_service.dart';
import 'package:kamobahala_bscs4b_project/core/services/financial_service.dart';
import 'task_details.dart';
import 'new_task_screen.dart';
import 'edit_task_screen.dart';
import '../dashboard/organization_dashboard.dart';
import '../dashboard/financial_ledger.dart';

class TaskListScreen extends StatefulWidget {
  final String projectId;
  final String organizationId;
  final String projectName;

  const TaskListScreen({
    super.key,
    required this.projectId,
    required this.organizationId,
    required this.projectName,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _isAdmin = false;
  final AdminService _adminService = AdminService();
  final FinancialService _financialService = FinancialService();

  @override
  void initState() {
    super.initState();
    // Fetch tasks using the logic you provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TasksViewModel>(context, listen: false)
          .fetchProjectTasks(widget.projectId);
      _checkAdminStatus();
    });
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isUserAdmin(widget.organizationId);
    setState(() => _isAdmin = isAdmin);
  }

  Future<void> _handleTaskStatusChange(
      BuildContext context, Map<String, dynamic> task, bool isMarkedComplete) async {
    final taskId = task['task_id'] ?? task['id'];
    final newStatus = isMarkedComplete ? 'completed' : 'todo';

    // Update task status
    Provider.of<TasksViewModel>(context, listen: false)
        .updateTask(taskId, {'status': newStatus});

    // If marking as completed, record the expense to financial depository
    if (isMarkedComplete) {
      final estimatedExpense = (task['estimated_expense'] ?? 0.0) as num;
      final deductFromBudget = task['deduct_from_budget'] ?? false;

      if (estimatedExpense > 0 && deductFromBudget) {
        try {
          await _financialService.createTransaction(
            widget.organizationId,
            {
              'title': 'Task: ${task['title']}',
              'transaction_type': 'expense',
              'amount': estimatedExpense.toDouble(),
              'category': task['expense_category'] ?? 'Task Expense',
              'department': 'Projects',
              'description': 'Task completed: ${task['title']}',
              'project_id': widget.projectId,
              'task_id': taskId,
              'occurred_at': DateTime.now().toIso8601String(),
            },
          );
          // Refresh both task list and financial data after transaction
          if (mounted) {
            Provider.of<TasksViewModel>(context, listen: false)
                .fetchProjectTasks(widget.projectId);
            Provider.of<FinancialViewModel>(context, listen: false)
                .fetchTransactions(widget.organizationId);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Note: Task completed, but could not record financial detail: $e')),
            );
          }
        }
      } else if (isMarkedComplete) {
        // Even if not deducting from budget, refresh the task list for progress calculation
        if (mounted) {
          Provider.of<TasksViewModel>(context, listen: false)
              .fetchProjectTasks(widget.projectId);
        }
      }
    } else {
      // If unchecking (marking as not completed), delete associated financial transactions
      try {
        final success = await _financialService.deleteTaskTransactions(taskId);
        if (success && mounted) {
          // Refresh both task list and financial data after deletion
          Provider.of<TasksViewModel>(context, listen: false)
              .fetchProjectTasks(widget.projectId);
          Provider.of<FinancialViewModel>(context, listen: false)
              .fetchTransactions(widget.organizationId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Note: Task status updated, but could not remove financial detail: $e')),
          );
        }
      }
    }
  }

  /// Handle task deletion with confirmation dialog
  Future<void> _handleDeleteTask(BuildContext context, Map<String, dynamic> task) async {
    final taskTitle = task['title'] ?? 'Untitled Task';
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Are you sure you want to delete "$taskTitle"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final taskId = task['task_id'] ?? task['id'];
      
      if (taskId == null || taskId.isEmpty) {
        throw Exception('Invalid task ID');
      }
      
      // Delete the task
      final success = await Provider.of<TasksViewModel>(context, listen: false).deleteTask(taskId);
      
      if (!success) {
        throw Exception('Failed to delete task from database');
      }

      if (mounted) {
        // Refresh task list and financial data
        await Provider.of<TasksViewModel>(context, listen: false)
            .fetchProjectTasks(widget.projectId);
        
        // Also refresh financial data in case the task had any transactions
        await Provider.of<FinancialViewModel>(context, listen: false)
            .fetchTransactions(widget.organizationId);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task "$taskTitle" deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7F8), // The original greyish background
      appBar: _buildAppBar(context),
      body: Consumer<TasksViewModel>(
        builder: (context, tasksViewModel, _) {
          if (tasksViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tasksViewModel.errorMessage != null) {
            return Center(child: Text(tasksViewModel.errorMessage ?? 'Error'));
          }

          final tasks = tasksViewModel.tasks;
          if (tasks.isEmpty) {
            return _buildEmptyState();
          }

          // Calculate progress
          final completedTasks = tasks.where((task) => task['status'] == 'completed').length;
          final progress = tasks.isNotEmpty ? completedTasks / tasks.length : 0.0;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressHeader(progress),
                ...tasks.map((task) => _buildTaskCard(context, task)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF137FEC),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewTaskScreen(
                      projectId: widget.projectId,
                      organizationId: widget.organizationId,
                    ),
                  ),
                ).then((_) {
                  Provider.of<TasksViewModel>(context, listen: false)
                      .fetchProjectTasks(widget.projectId);
                });
              },
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildProgressHeader(double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Project Progress",
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF617589)),
              ),
              Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF137FEC)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3F4F6),
              color: const Color(0xFF137FEC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task) {
    final priority = task['priority']?.toString() ?? 'Low';
    final isCompleted = task['status'] == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Checkbox(
          value: isCompleted,
          onChanged: (value) {
            if (value != null) {
              _handleTaskStatusChange(context, task, value);
            }
          },
        ),
        title: Text(
          task['title'] ?? 'Untitled Task',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          task['description'] ?? 'No description',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)),
        ),
        trailing: _isAdmin
            ? SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF137FEC), size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditTaskScreen(
                              taskId: task['id'],
                              projectId: widget.projectId,
                              organizationId: widget.organizationId,
                              task: task,
                            ),
                          ),
                        ).then((result) {
                          // Refresh task list and financial data when returning
                          Provider.of<TasksViewModel>(context, listen: false)
                              .fetchProjectTasks(widget.projectId);
                          Provider.of<FinancialViewModel>(context, listen: false)
                              .fetchTransactions(widget.organizationId);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 20),
                      onPressed: () {
                        _handleDeleteTask(context, task);
                      },
                    ),
                  ],
                ),
              )
            : _buildBadge(priority, _getPriorityColor(priority)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailsScreen(task: task),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt_outlined, size: 64, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),
          Text(
            "No tasks yet",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF137FEC)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.projectName,
        style: GoogleFonts.inter(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: false,
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

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF137FEC),
      unselectedItemColor: Colors.grey,
      currentIndex: 1,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrganizationDashboard(
                organization: {
                  'id': widget.organizationId,
                  'name': 'Organization',
                },
              ),
            ),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => FinancialLedgerScreen(
                organization: {
                  'id': widget.organizationId,
                  'name': 'Organization',
                },
              ),
            ),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded), label: "Dashboard"),
        BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined), label: "Projects"),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: "Finances"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
      ],
    );
  }
}