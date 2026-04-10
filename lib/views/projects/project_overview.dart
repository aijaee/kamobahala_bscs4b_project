import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../models/financial_transaction.dart';
import 'task_list_screen.dart';
import 'edit_proj_screen.dart';
import '../../viewmodels/tasks_viewmodel.dart';
import '../../viewmodels/financial_viewmodel.dart';
import '../../viewmodels/projects_viewmodel.dart';
import '../../core/services/admin_service.dart';

class ProjectOverviewScreen extends StatefulWidget {
  final Map<String, dynamic> organization;
  final Project? project;
  final Function(int)? onTabChange;

  const ProjectOverviewScreen({
    super.key,
    this.organization = const {
      'id': 'test-123',
      'name': 'Sample University Org',
      'budget': 20000.0,
    },
    this.project,
    this.onTabChange,
  });

  @override
  State<ProjectOverviewScreen> createState() => _ProjectOverviewScreenState();
}

class _ProjectOverviewScreenState extends State<ProjectOverviewScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 1;
  bool _isAdmin = false;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProjectData();
    _checkAdminStatus();
  }

  Future<void> _markProjectAsComplete() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark Project Complete'),
          content: Text(
            'Are you sure you want to mark "${widget.project?.name ?? 'this project'}" as completed? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF137FEC),
              ),
              child: const Text('Mark Complete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || widget.project == null) return;

    try {
      final projectsVM = context.read<ProjectsViewModel>();
      final financialVM = context.read<FinancialViewModel>();
      final projectId = widget.project!.id;

      // Update project status to completed
      final success = await projectsVM.updateProject(
        projectId,
        {'status': 'completed'},
      );

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to mark project as complete')),
          );
        }
        return;
      }

      // Do not post a bulk "Project Completed" financial adjustment.
      // Task and manual project transactions are already reflected in the depository.
      final organizationId = widget.organization['id']?.toString();
      if (organizationId != null) {
        await financialVM.fetchTransactions(organizationId);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Project "${widget.project?.name}" marked as completed')),
      );

      // Refresh completed projects list
      await projectsVM.fetchCompletedProjects();

      // Navigate back after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isUserAdmin(widget.organization['id']);
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  void _loadProjectData() {
    // Fetch tasks and financial data for this project
    if (widget.project != null && widget.project!.id.isNotEmpty) {
      final projectId = widget.project!.id;
      final orgId = widget.organization['id'];

      // Fetch tasks for this project
      context.read<TasksViewModel>().fetchProjectTasks(projectId);
      // Fetch ALL transactions for the organization to ensure financial data is accurate
      context.read<FinancialViewModel>().fetchTransactions(orgId);
    }
  }

  void _handleTaskListTabResult(dynamic result) {
    if (result is int && result != 1) {
      widget.onTabChange?.call(result);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  // Force refresh - ACTUALLY await the data loading
  Future<void> _forceRefresh() async {
    if (widget.project != null && widget.project!.id.isNotEmpty) {
      final projectId = widget.project!.id;
      final orgId = widget.organization['id'];

      // Await both fetch operations to complete
      await Future.wait([
        context.read<TasksViewModel>().fetchProjectTasks(projectId),
        context.read<FinancialViewModel>().fetchTransactions(orgId),
      ]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Refresh data when navigating back
        await _forceRefresh();
        return true;
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: _forceRefresh,
        color: const Color(0xFF137FEC),
        backgroundColor: Colors.white,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainProgressCard(),
                  const SizedBox(height: 20),
                  _buildFinancialHealthCard(),
                  const SizedBox(height: 24),
                  Text(
                    "PROJECT SECTIONS",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF617589),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProjectSections(context),
                  const SizedBox(height: 24),
                  _buildTaskListButton(context),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNav(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSections(BuildContext context) {
    return Consumer<TasksViewModel>(
      builder: (context, tasksVM, _) {
        if (tasksVM.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tasksVM.tasks.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Center(
              child: Text(
                "No tasks yet. Create one to get started!",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFF617589)),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${tasksVM.tasks.length} Tasks",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...tasksVM.tasks.take(3).map((task) {
                final isCompleted = task.isCompleted;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskListScreen(
                            projectId: widget.project?.id ?? '',
                            organizationId:
                                widget.organization['id'].toString(),
                            projectName: widget.project?.name ?? 'Project',
                            onTabChange: widget.onTabChange,
                          ),
                        ),
                      ).then((result) {
                        if (result is int && result != 1) {
                          _handleTaskListTabResult(result);
                        } else {
                          _loadProjectData();
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: isCompleted
                              ? Colors.green
                              : const Color(0xFFD1D5DB),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.title,
                            style: GoogleFonts.inter(
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              if (tasksVM.tasks.length > 3) ...[
                const Divider(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskListScreen(
                          projectId: widget.project?.id ?? '',
                          organizationId: widget.organization['id'].toString(),
                          projectName: widget.project?.name ?? 'Project',
                          onTabChange: widget.onTabChange,
                        ),
                      ),
                    ).then((result) {
                      if (result is int && result != 1) {
                        _handleTaskListTabResult(result);
                      } else {
                        _loadProjectData();
                      }
                    });
                  },
                  child: Text(
                    "View all ${tasksVM.tasks.length} tasks →",
                    style: GoogleFonts.inter(
                        color: const Color(0xFF137FEC),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios,
            color: Color(0xFF111418), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.project?.name ?? "Project Overview",
        style: GoogleFonts.inter(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: true,
      actions: [
        if (_isAdmin)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'edit') {
                if (widget.project != null && widget.project!.id.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProjectScreen(
                        projectId: widget.project!.id,
                        organization: widget.organization,
                      ),
                    ),
                  ).then((_) {
                    // Refresh project data when returning from edit
                    _loadProjectData();
                  });
                }
              } else if (value == 'complete') {
                _markProjectAsComplete();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Project'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: Color(0xFF137FEC)),
                      SizedBox(width: 8),
                      Text('Mark Complete'),
                    ],
                  ),
                ),
              ];
            },
          ),
      ],
    );
  }

  Widget _buildMainProgressCard() {
    final projectName = widget.project?.name ?? 'CS Gala Preparation';
    final budget = widget.project?.budget ?? 0;

    return Consumer<TasksViewModel>(
      builder: (context, tasksVM, _) {
        // Calculate progress based on actual tasks
        double progress = 0.0;
        if (tasksVM.tasks.isNotEmpty) {
          final completedCount =
              tasksVM.tasks.where((task) => task.isCompleted).length;
          progress = completedCount / tasksVM.tasks.length;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor:
                          const Color(0xFF137FEC).withValues(alpha: 0.1),
                      color: const Color(0xFF137FEC),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${(progress * 100).toInt()}%",
                          style: GoogleFonts.inter(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                      Text("COMPLETED",
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),
              Text(projectName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("Budget: ₱${budget.toString()}",
                  style: GoogleFonts.inter(color: const Color(0xFF617589))),
              const SizedBox(height: 24),
              // Add linear progress indicator to match project card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Progress",
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  Text("${(progress * 100).toInt()}%",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                color: const Color(0xFF137FEC),
                backgroundColor: Colors.grey[300],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinancialHealthCard() {
    return Consumer2<FinancialViewModel, TasksViewModel>(
      builder: (context, financialVM, tasksVM, _) {
        final projectBudget = widget.project?.budget ?? 0.0;
        final projectId = widget.project?.id;

        final completedTasks = projectId == null
            ? const <Task>[]
            : tasksVM.tasks
                .where(
                    (task) => task.projectId == projectId && task.isCompleted)
                .toList();

        final taskIncome = completedTasks
            .where((task) => task.deductFromBudget == false)
            .fold<double>(
                0.0, (sum, task) => sum + (task.estimatedExpense ?? 0));

        final projectTransactions = projectId == null
            ? const <FinancialTransaction>[]
            : financialVM.transactions
                .where((transaction) => transaction.projectId == projectId)
                .toList();

        final nonTaskIncome = projectTransactions.where((transaction) {
          final title = transaction.title.toLowerCase();
          final isInternalTransfer = title.contains('budget allocation') ||
              title.contains('budget adjustment');
          final isTaskTransaction = (transaction.taskId?.isNotEmpty ?? false) ||
              title.startsWith('task:');
          return transaction.isIncome &&
              !isInternalTransfer &&
              !isTaskTransaction;
        }).fold<double>(0.0, (sum, transaction) => sum + transaction.amount);

        final budgetUtilized = projectId == null
            ? 0.0
            : financialVM.calculateProjectSpent(projectId, completedTasks);
        final projectIncome = taskIncome + nonTaskIncome;

        final utilizationPercent =
            projectBudget > 0 ? (budgetUtilized / projectBudget) : 0.0;
        final estimatedTotal = budgetUtilized > 0
            ? (budgetUtilized /
                (utilizationPercent > 0 ? utilizationPercent : 1.0))
            : projectBudget;
        final isOnTrack = utilizationPercent <= 0.75;

        return Container(
          padding: const EdgeInsets.all(20),
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
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          color: Color(0xFF137FEC), size: 20),
                      const SizedBox(width: 8),
                      Text("Financial Status",
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOnTrack
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOnTrack ? "On Track" : "At Risk",
                      style: GoogleFonts.inter(
                        color: isOnTrack ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Budget Utilized",
                      style: GoogleFonts.inter(color: const Color(0xFF617589))),
                  Text(
                    "₱${budgetUtilized.toStringAsFixed(2)} / ₱${projectBudget.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: utilizationPercent.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: const Color(0xFFF3F4F6),
                  color: isOnTrack ? const Color(0xFF137FEC) : Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Estimated completion cost: ₱${estimatedTotal.toStringAsFixed(2)}",
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Income Made",
                      style: GoogleFonts.inter(color: const Color(0xFF617589))),
                  Text(
                    "₱${projectIncome.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: projectIncome > 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskListButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 72,
      decoration: BoxDecoration(
          color: const Color(0xFF137FEC),
          borderRadius: BorderRadius.circular(16)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskListScreen(
                  projectId: widget.project?.id ?? '',
                  organizationId: widget.organization['id'].toString(),
                  projectName: widget.project?.name ?? 'Project',
                  onTabChange: widget.onTabChange,
                ),
              ),
            ).then((result) {
              if (result is int && result != 1) {
                _handleTaskListTabResult(result);
              } else {
                _forceRefresh();
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.checklist, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Task List",
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text("View all tasks",
                        style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          border: const Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == _selectedIndex) return;

          // If we have an onTabChange callback, use it to switch tabs
          if (widget.onTabChange != null) {
            Navigator.pop(context);
            widget.onTabChange!(index);
          } else {
            // Fallback: just pop back
            Navigator.pop(context);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF137FEC),
        unselectedItemColor: const Color(0xFF9CA3AF),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined), label: "Projects"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: "Finances"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}
