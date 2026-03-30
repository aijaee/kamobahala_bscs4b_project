import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../dashboard/organization_dashboard.dart';
import '../../viewmodels/financial_viewmodel.dart';
import '../../viewmodels/organization_dashboard_viewmodel.dart';
import '../../viewmodels/projects_viewmodel.dart';
import '../../core/services/admin_service.dart';
import '../dashboard/financial_ledger.dart';
import 'new_proj_screen.dart';
import 'project_overview.dart';
import 'edit_proj_screen.dart';

class ProjectsList extends StatefulWidget {
  final int initialIndex;
  final Map<String, dynamic> organization;
  const ProjectsList(
      {super.key, this.initialIndex = 1, required this.organization});

  @override
  State<ProjectsList> createState() => _ProjectsListState();
}

class _ProjectsListState extends State<ProjectsList> with WidgetsBindingObserver {
  late int currentIndex;
  int selectedTab = 0;
  bool _isAdmin = false;
  late FinancialViewModel _financialViewModel;
  late OrganizationDashboardViewModel _dashboardViewModel;
  final AdminService _adminService = AdminService();
  double _balance = 0;
  String _searchQuery = "";
  late List<String> tabs;
  bool _balanceHidden = true;

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
        context.read<ProjectsViewModel>().fetchProjectsWithProgress(widget.organization['id'].toString());
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
      await context.read<ProjectsViewModel>().fetchProjectsWithProgress(widget.organization['id'].toString());
      _buildTabsFromProjects();
      await _fetchBalance();
    }
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isUserAdmin(widget.organization['id']);
    setState(() => _isAdmin = isAdmin);
  }

  void _buildTabsFromProjects() {
    final projectsViewModel = context.read<ProjectsViewModel>();
    final uniqueDepartments = <String>{};
    
    for (var project in projectsViewModel.projects) {
      final department = project['department'] as String?;
      if (department != null && department.isNotEmpty) {
        uniqueDepartments.add(department);
      }
    }

    setState(() {
      tabs = ['All Projects', ...uniqueDepartments.toList()];
      // Reset selectedTab if it's out of bounds
      if (selectedTab >= tabs.length) {
        selectedTab = 0;
      }
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
          _balance = _dashboardViewModel.currentBalance;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _balance =
              double.tryParse(widget.organization['budget']?.toString() ?? '') ?? 0;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredProjects(
      List<Map<String, dynamic>> projects) {
    return projects.where((project) {
      final matchesSearch = _searchQuery.isEmpty ||
          project['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesTab = selectedTab == 0 ||
          project['department'] == tabs[selectedTab];

      return matchesSearch && matchesTab;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF137FEC),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateProjectScreen(organization: widget.organization),
                  ),
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), border: const Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          selectedItemColor: const Color(0xFF137FEC),
          unselectedItemColor: const Color(0xFF9CA3AF),
          onTap: (idx) {
            if (idx == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OrganizationDashboard(organization: widget.organization),
                ),
              );
            } else if (idx == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => FinancialLedgerScreen(
                        initialIndex: 2, organization: widget.organization)),
              );
            } else if (idx == 3) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Profile screen coming soon..."),
                ),
              );
            } else {
              setState(() {
                currentIndex = idx;
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          showUnselectedLabels: true,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              label: "Projects",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: "Finances",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Profile",
            ),
          ],
        ),
      ),
      body: Consumer<ProjectsViewModel>(
        builder: (context, projectsViewModel, _) {
          return Consumer<FinancialViewModel>(
            builder: (context, financialViewModel, _) {
              return SafeArea(
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
                            else if (_getFilteredProjects(projectsViewModel.projects).isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text("No projects found."),
                                ),
                              )
                            else
                              ..._getFilteredProjects(projectsViewModel.projects)
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final project = entry.value;
                                final isLast = entry.key == _getFilteredProjects(projectsViewModel.projects).length - 1;
                                final progress = (project['progress'] as num?)?.toDouble() ?? 0.0;

                                double spent = 0.0;
                                final projectId = project['id'];
                                for (final transaction in financialViewModel.transactions) {
                                  if (transaction['project_id'] == projectId &&
                                      (transaction['transaction_type'] ?? '').toString().toLowerCase() == 'expense' &&
                                      (transaction['title'] ?? '').toString().startsWith('Task:')) {
                                    spent += (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                                  }
                                }

                                final projectBudget = (project['budget'] as num?)?.toDouble() ?? 0.0;
                                String budget = projectBudget > 0 ? "₱${projectBudget.toStringAsFixed(2)}" : "₱0.00";
                                String spentStr = spent > 0 ? "₱${spent.toStringAsFixed(2)}" : "₱0.00";

                                return Column(
                                  children: [
                                    _projectCard(
                                      tag: project['status'] ?? "Active",
                                      title: project['name'] ?? "Untitled Project",
                                      progress: progress,
                                      spent: spentStr,
                                      limit: budget,
                                      color: const Color(0xFF137FEC),
                                      projectId: project['id'],
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProjectOverviewScreen(
                                              organization: widget.organization,
                                              project: project,
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
                                        child: Text("No completed projects yet."),
                                      ),
                                    )
                                  ]
                                : projectsViewModel.completedProjects.map((project) {
                                    final budget = project['budget'] != null
                                        ? "₱${project['budget']}"
                                        : "₱0";
                                    return _completedCard(
                                      title: project['name'] ?? "Project",
                                      amount: budget,
                                      completedDate:
                                          project['due_date'] ?? "Recently completed",
                                    );
                                  }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
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
                    icon: const Icon(Icons.edit, color: Color(0xFF137FEC), size: 20),
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
                        context.read<ProjectsViewModel>()
                            .fetchProjects(widget.organization['id'].toString());
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
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
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

  String _formatCurrency(double amount) {
    final absolute = amount.abs().toStringAsFixed(2);
    final parts = absolute.split('.');
    final whole = parts[0];
    final decimals = parts[1];
    final buffer = StringBuffer();

    for (var index = 0; index < whole.length; index++) {
      final reversedIndex = whole.length - index;
      buffer.write(whole[index]);
      if (reversedIndex > 1 && reversedIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    final prefix = amount < 0 ? '-₱' : '₱';
    return '$prefix${buffer.toString()}.$decimals';
  }
}