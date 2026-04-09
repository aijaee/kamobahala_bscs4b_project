import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/financial_viewmodel.dart';
import '../../viewmodels/organization_dashboard_viewmodel.dart';
import '../../viewmodels/projects_viewmodel.dart';
import '../../viewmodels/tasks_viewmodel.dart';
import '../../core/services/admin_service.dart';
import '../../models/project.dart';
import 'project_overview.dart';
import 'edit_proj_screen.dart';

class ProjectsList extends StatefulWidget {
  final int initialIndex;
  final Map<String, dynamic> organization;
  final Function(int)? onTabChange;
  const ProjectsList({
    super.key,
    this.initialIndex = 1,
    required this.organization,
    this.onTabChange,
  });

  @override
  State<ProjectsList> createState() => _ProjectsListState();
}

class _ProjectsListState extends State<ProjectsList>
    with WidgetsBindingObserver {
  late int currentIndex;
  int selectedTab = 0;
  bool _isAdmin = false;
  late FinancialViewModel _financialViewModel;
  late OrganizationDashboardViewModel _dashboardViewModel;
  final AdminService _adminService = AdminService();
  String _searchQuery = "";
  late List<String> tabs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentIndex = widget.initialIndex;
    _financialViewModel = context.read<FinancialViewModel>();
    _dashboardViewModel = OrganizationDashboardViewModel(
      financialViewModel: _financialViewModel,
    );
    _checkAdminStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchBalance();
        context
            .read<ProjectsViewModel>()
            .fetchProjectsWithProgress(widget.organization['id'].toString());
        context.read<ProjectsViewModel>().fetchCompletedProjects();
        _buildTabsFromProjects();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchBalance();
      _refreshProjectsWithProgress();
    }
  }

  Future<void> _refreshProjectsWithProgress() async {
    if (mounted) {
      await Future.wait([
        context
            .read<ProjectsViewModel>()
            .fetchProjectsWithProgress(widget.organization['id'].toString()),
        context.read<ProjectsViewModel>().fetchCompletedProjects(),
      ]);
      _buildTabsFromProjects();
      await _fetchBalance();
    }
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isUserAdmin(widget.organization['id']);
    setState(() => _isAdmin = isAdmin);
  }

  void _buildTabsFromProjects() {
    // Department not part of model, so just use default tabs
    setState(() {
      tabs = ['All Projects'];
      selectedTab = 0;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dashboardViewModel.dispose();
    super.dispose();
  }

  Future<void> _fetchBalance() async {
    try {
      await _financialViewModel
          .fetchTransactions(widget.organization['id'].toString());
      _dashboardViewModel.calculateFinancialSummary(
        widget.organization,
        _financialViewModel.transactions,
      );

      if (mounted) {
        setState(() {
          // Balance updated in dashboard view model
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          // Balance retrieval failed
        });
      }
    }
  }

  List<Project> _getFilteredProjects(List<Project> projects) {
    return projects.where((project) {
      // Only include active/ongoing projects, exclude completed ones
      final status = (project.status ?? 'active').toLowerCase();
      if (status == 'completed') {
        return false; // Skip completed projects
      }

      final matchesSearch = _searchQuery.isEmpty ||
          project.name.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesTab = selectedTab == 0;

      return matchesSearch && matchesTab;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsViewModel>(
      builder: (context, projectsViewModel, _) {
        return Consumer2<FinancialViewModel, TasksViewModel>(
          builder: (context, financialViewModel, tasksViewModel, _) {
            return Material(
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    _header(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshProjectsWithProgress,
                        color: const Color(0xFF137FEC),
                        backgroundColor: Colors.white,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                          children: [
                            _sectionHeader("Ongoing Projects", ""),
                            const SizedBox(height: 12),
                            if (projectsViewModel.isLoading)
                              const Center(child: CircularProgressIndicator())
                            else if (_getFilteredProjects(
                                    projectsViewModel.projects)
                                .isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text("No projects found."),
                                ),
                              )
                            else
                              ..._getFilteredProjects(
                                      projectsViewModel.projects)
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final project = entry.value;
                                final isLast = entry.key ==
                                    _getFilteredProjects(
                                                projectsViewModel.projects)
                                            .length -
                                        1;
                                final progress = projectsViewModel
                                    .getProjectProgressFromCache(project.id)
                                    .clamp(0.0, 1.0);

                                final projectId = project.id;
                                final projectTasks = tasksViewModel.tasks
                                    .where((task) =>
                                        task.projectId == projectId &&
                                        task.isCompleted)
                                    .toList();
                                final spent =
                                    financialViewModel.calculateProjectSpent(
                                        projectId, projectTasks);

                                final projectBudget = project.budget ?? 0.0;
                                String budget = projectBudget > 0
                                    ? "₱${projectBudget.toStringAsFixed(2)}"
                                    : "₱0.00";
                                String spentStr = spent > 0
                                    ? "₱${spent.toStringAsFixed(2)}"
                                    : "₱0.00";

                                return Column(
                                  children: [
                                    _projectCard(
                                      tag: project.status ?? "Active",
                                      title: project.name,
                                      progress: progress,
                                      spent: spentStr,
                                      limit: budget,
                                      color: const Color(0xFF137FEC),
                                      projectId: project.id,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProjectOverviewScreen(
                                              organization: widget.organization,
                                              project: project,
                                              onTabChange: widget.onTabChange,
                                            ),
                                          ),
                                        ).then((_) {
                                          _refreshProjectsWithProgress();
                                        });
                                      },
                                    ),
                                    if (!isLast) const SizedBox(height: 12),
                                  ],
                                );
                              }).toList(),
                            const SizedBox(height: 20),
                            _sectionHeader("Completed", ""),
                            const SizedBox(height: 12),
                            ...projectsViewModel.completedProjects.isEmpty
                                ? [
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child:
                                            Text("No completed projects yet."),
                                      ),
                                    )
                                  ]
                                : projectsViewModel.completedProjects
                                    .map((project) {
                                    final budget = project.budget != null
                                        ? "₱${project.budget}"
                                        : "₱0";
                                    final completedDate =
                                        project.endDate?.toString() ??
                                            "Recently completed";
                                    return _completedCard(
                                      title: project.name,
                                      amount: budget,
                                      completedDate: completedDate,
                                    );
                                  }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// HEADER
  Widget _header() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
          color: const Color(0xFFF6F7F8).withOpacity(.92),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Projects",
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                    hintText: "Search projects, teams, or tasks…",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFE5E7EB),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(tabs.length, (i) {
                    final active = selectedTab == i;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tabs[i]),
                        selected: active,
                        onSelected: (_) {
                          setState(() {
                            selectedTab = i;
                          });
                        },
                        selectedColor: const Color(0xFF137FEC),
                        labelStyle: TextStyle(
                            color: active ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// SECTION HEADER
  Widget _sectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        Text(
          action,
          style: const TextStyle(
              color: Color(0xFF137FEC), fontWeight: FontWeight.w600),
        )
      ],
    );
  }

  /// PROJECT CARD
  Widget _projectCard(
      {required String tag,
      required String title,
      required double progress,
      required String spent,
      required String limit,
      required Color color,
      String? projectId,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3F4F6)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1))
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(tag),
                  backgroundColor: color.withOpacity(.1),
                ),
                if (_isAdmin && projectId != null)
                  IconButton(
                    icon: const Icon(Icons.edit,
                        color: Color(0xFF137FEC), size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProjectScreen(
                            projectId: projectId,
                            organization: widget.organization,
                          ),
                        ),
                      ).then((_) {
                        context.read<ProjectsViewModel>().fetchProjects(
                            widget.organization['id'].toString());
                      });
                    },
                  )
                else
                  const Icon(Icons.chevron_right)
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style:
                  GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Completion"),
                Text("${(progress * 100).toInt()}%")
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              color: color,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Budget Spent"),
                Text("$spent / $limit",
                    style: const TextStyle(fontWeight: FontWeight.bold))
              ],
            )
          ],
        ),
      ),
    );
  }

  /// COMPLETED CARD
  Widget _completedCard({
    required String title,
    required String amount,
    String completedDate = "Recently completed",
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6))),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Finished $completedDate",
                    style: const TextStyle(color: Colors.grey, fontSize: 12))
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}
