import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/financial_viewmodel.dart';
import '../../viewmodels/organization_dashboard_viewmodel.dart';
import '../../viewmodels/projects_viewmodel.dart';
import '../../core/services/organization_service.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/dashboard_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/project.dart';
import 'tasks_by_category_screen.dart';
import 'search_results_screen.dart';
import '../projects/project_overview.dart';
import '../projects/task_details.dart';

class OrganizationDashboard extends StatefulWidget {
  final Map<String, dynamic> organization;
  final Function(int)? onTabChange;
  const OrganizationDashboard({
    super.key,
    required this.organization,
    this.onTabChange,
  });

  @override
  State<OrganizationDashboard> createState() => _OrganizationDashboardState();
}

class _OrganizationDashboardState extends State<OrganizationDashboard>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  late FinancialViewModel _financialViewModel;
  late OrganizationDashboardViewModel _dashboardViewModel;
  final OrganizationService _orgService = OrganizationService();
  final AdminService _adminService = AdminService();
  bool _balanceHidden = true;
  bool _isAdmin = false;
  String? _userEmail;
  final TextEditingController _searchController = TextEditingController();
  bool _showSuggestions = false;
  List<Map<String, dynamic>> _searchSuggestions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _financialViewModel = FinancialViewModel();
    _dashboardViewModel = OrganizationDashboardViewModel(
      financialViewModel: _financialViewModel,
    );
    _financialViewModel.addListener(_onViewModelChanged);
    _dashboardViewModel.addListener(_onViewModelChanged);

    _getUserEmail();
    _checkAdminStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBalance();
      }
    });
  }

  @override
  void didUpdateWidget(OrganizationDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organization['id'] != widget.organization['id']) {
      _cleanupViewModels();
      _initializeViewModels();
      _refreshProjects();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshProjects();
      _loadBalance();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupViewModels();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeViewModels() {
    _financialViewModel = FinancialViewModel();
    _dashboardViewModel = OrganizationDashboardViewModel(
      financialViewModel: _financialViewModel,
    );
    _financialViewModel.addListener(_onViewModelChanged);
    _dashboardViewModel.addListener(_onViewModelChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBalance();
      }
    });
  }

  void _cleanupViewModels() {
    _financialViewModel.removeListener(_onViewModelChanged);
    _dashboardViewModel.removeListener(_onViewModelChanged);
    _financialViewModel.dispose();
    _dashboardViewModel.dispose();
  }

  void _onViewModelChanged() {
    setState(() {});
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin =
        await _adminService.isUserAdmin(widget.organization['id'].toString());
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  void _getUserEmail() {
    final user = Supabase.instance.client.auth.currentUser;
    if (mounted) {
      setState(() => _userEmail = user?.email);
    }
  }

  Future<void> _loadBalance() async {
    await _financialViewModel
        .fetchTransactions(widget.organization['id'].toString());
    _dashboardViewModel.calculateFinancialSummary(
      widget.organization,
      _financialViewModel.transactions,
    );

    if (_isAdmin) {
      await _dashboardViewModel.fetchAdminDeadlines(
        widget.organization['id'].toString(),
        _userEmail,
      );
    } else {
      await _dashboardViewModel.fetchMemberDeadlines(
        widget.organization['id'].toString(),
        _userEmail,
      );
    }

    await _orgService
        .syncMemberNamesFromProfiles(widget.organization['id'].toString());
  }

  void _refreshProjects() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProjectsViewModel>().fetchProjectsWithProgress(
              widget.organization['id'].toString(),
            );
      }
    });
  }

  Future<void> _refreshDashboard() async {
    await context.read<ProjectsViewModel>().fetchProjectsWithProgress(
          widget.organization['id'].toString(),
        );
    await _loadBalance();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final allTasks = _dashboardViewModel.priorityDeadlines;
    final projectsViewModel = context.read<ProjectsViewModel>();
    final allProjects = projectsViewModel.projects;
    final allTransactions = _financialViewModel.transactions;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          query: query,
          tasks: allTasks,
          projects: allProjects.map((p) => p.toMap()).toList(),
          transactions: allTransactions.map((t) => t.toMap()).toList(),
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        _loadBalance();
      }
    });
  }

  void _updateSearchSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions = [];
      });
      return;
    }

    final queryLower = query.toLowerCase();
    final suggestions = <Map<String, dynamic>>[];

    final allTasks = _dashboardViewModel.priorityDeadlines;
    final projectsViewModel = context.read<ProjectsViewModel>();
    final allProjects = projectsViewModel.projects;
    final allTransactions = _financialViewModel.transactions;

    final matchingTasks = allTasks
        .where((task) =>
            (task['title'] ?? '').toString().toLowerCase().contains(queryLower))
        .take(3)
        .toList();

    for (var task in matchingTasks) {
      suggestions.add({
        'type': 'task',
        'title': task['title'] ?? 'Untitled Task',
        'subtitle': task['projectName'] ?? 'Unknown Project',
        'icon': Icons.assignment,
        'data': task,
      });
    }

    final matchingProjects = allProjects
        .where((project) => project.name.toLowerCase().contains(queryLower))
        .take(3)
        .toList();

    for (var project in matchingProjects) {
      final projectId = project.id;
      final taskCount =
          allTasks.where((task) => task['project_id'] == projectId).length;

      suggestions.add({
        'type': 'project',
        'title': project.name,
        'subtitle': '$taskCount task${taskCount != 1 ? 's' : ''}',
        'icon': Icons.folder_outlined,
        'data': project,
      });
    }

    final matchingTransactions = allTransactions
        .where((transaction) =>
            transaction.title.toLowerCase().contains(queryLower))
        .take(2)
        .toList();

    for (var transaction in matchingTransactions) {
      suggestions.add({
        'type': 'transaction',
        'title': transaction.title,
        'subtitle': '₱${transaction.amount.toStringAsFixed(2)}',
        'icon': Icons.account_balance_wallet_outlined,
        'data': transaction,
      });
    }

    setState(() {
      _showSuggestions = true;
      _searchSuggestions = suggestions;
    });
  }

  void _handleSuggestionTap(Map<String, dynamic> suggestion) {
    final type = suggestion['type'];
    final data = suggestion['data'];

    _searchController.clear();
    setState(() => _showSuggestions = false);

    if (type == 'task') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailsScreen(
            task: data,
            organizationId: widget.organization['id'].toString(),
          ),
        ),
      ).then((taskUpdated) {
        if (taskUpdated == true && mounted) {
          _loadBalance();
        }
      });
    } else if (type == 'project') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectOverviewScreen(
            project: data,
            organization: widget.organization,
            onTabChange: widget.onTabChange,
          ),
        ),
      );
    } else if (type == 'transaction') {
      // Switch to Finances tab using the callback
      widget.onTabChange?.call(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refreshDashboard,
              color: const Color(0xFF137FEC),
              backgroundColor: Colors.white,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(),
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildFinancialCard(context),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          _isAdmin ? "Priority Overview" : "Tasks Assigned",
                          "View All",
                          onPressed: () {
                            _showAllTasksModal(context);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDeadlinesList(context),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          "Active Projects",
                          "See All",
                          onPressed: () {
                            widget.onTabChange?.call(1);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildProjectsListFromViewModel(context),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.organization['name'] ?? 'Organization',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111418),
                      ),
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back,
                      size: 24, color: Colors.blue),
                  label: const Text(
                    'Back to main',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search bar with suggestions
            Column(
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _performSearch(),
                  onChanged: (value) {
                    _updateSearchSuggestions(value);
                  },
                  decoration: InputDecoration(
                    hintText: "Search tasks, projects, or finances",
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _showSuggestions = false);
                            },
                            child: const Icon(Icons.close, size: 18),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFE5E7EB).withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                // Suggestions dropdown
                if (_showSuggestions && _searchSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _searchSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _searchSuggestions[index];
                        final icon = suggestion['icon'] as IconData;
                        final title = suggestion['title'] as String;
                        final subtitle = suggestion['subtitle'] as String;

                        return GestureDetector(
                          onTap: () => _handleSuggestionTap(suggestion),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF137FEC)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 16,
                                    color: const Color(0xFF137FEC),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF137FEC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF137FEC).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.organization['name'] ?? 'ORGANIZATION',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TOTAL DEPOSITORY BALANCE',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _balanceHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _balanceHidden = !_balanceHidden;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _balanceHidden
                ? "••••••••"
                : _formatCurrency(_dashboardViewModel.currentBalance),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Switch to Finances tab using the callback
              widget.onTabChange?.call(2);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF137FEC),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text("View Financial Details"),
          ),
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
      if (reversedIndex > 1 && reversedIndex % 3 == 1) buffer.write(',');
    }
    return '${amount < 0 ? '-₱' : '₱'}${buffer.toString()}.$decimals';
  }

  Widget _buildSectionHeader(String title, String actionText,
      {VoidCallback? onPressed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style:
                GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: onPressed,
          child: Text(actionText,
              style: const TextStyle(color: Color(0xFF137FEC))),
        ),
      ],
    );
  }

  Widget _buildDeadlinesList(BuildContext context) {
    if (_dashboardViewModel.isLoadingDeadlines) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isAdmin) {
      return _buildAdminPriorityCards(context);
    } else {
      return _buildMemberPriorityCards(context);
    }
  }

  Widget _buildAdminPriorityCards(BuildContext context) {
    final allTasks = _dashboardViewModel.priorityDeadlines;
    final assignedTasks = _dashboardViewModel.assignedDeadlines;

    final highCount = allTasks
        .where((t) => (t['priority'] ?? 'Low').toLowerCase() == 'high')
        .length;
    final mediumCount = allTasks
        .where((t) => (t['priority'] ?? 'Low').toLowerCase() == 'medium')
        .length;
    final lowCount = allTasks
        .where((t) => (t['priority'] ?? 'Low').toLowerCase() == 'low')
        .length;

    final cards = [
      {
        'title': 'High Priority',
        'count': highCount,
        'color': 0xFFEF4444,
        'icon': Icons.error,
        'subtitle': '$highCount task${highCount != 1 ? 's' : ''} to handle',
      },
      {
        'title': 'Medium Priority',
        'count': mediumCount,
        'color': 0xFFF97316,
        'icon': Icons.warning,
        'subtitle':
            '$mediumCount task${mediumCount != 1 ? 's' : ''} in progress',
      },
      {
        'title': 'Low Priority',
        'count': lowCount,
        'color': 0xFF22C55E,
        'icon': Icons.info,
        'subtitle': '$lowCount task${lowCount != 1 ? 's' : ''} planned',
      },
      {
        'title': 'My Tasks',
        'count': assignedTasks.length,
        'color': 0xFF8B5CF6,
        'icon': Icons.assignment,
        'subtitle':
            '${assignedTasks.length} task${assignedTasks.length != 1 ? 's' : ''} assigned to me',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final color = Color(card['color'] as int);
        final cardTitle = card['title'] as String;

        return GestureDetector(
          onTap: () {
            List<Map<String, dynamic>> filteredTasks;

            if (cardTitle == 'High Priority') {
              filteredTasks = allTasks
                  .where(
                      (t) => (t['priority'] ?? 'Low').toLowerCase() == 'high')
                  .toList();
            } else if (cardTitle == 'Medium Priority') {
              filteredTasks = allTasks
                  .where(
                      (t) => (t['priority'] ?? 'Low').toLowerCase() == 'medium')
                  .toList();
            } else if (cardTitle == 'Low Priority') {
              filteredTasks = allTasks
                  .where((t) => (t['priority'] ?? 'Low').toLowerCase() == 'low')
                  .toList();
            } else {
              filteredTasks = assignedTasks;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TasksByCategoryScreen(
                  title: cardTitle,
                  tasks: filteredTasks,
                  categoryColor: color,
                ),
              ),
            ).then((result) {
              if (result == true && mounted) {
                _loadBalance();
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3F4F6)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        card['icon'] as IconData,
                        size: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        card['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${card['count']} tasks',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card['subtitle'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberPriorityCards(BuildContext context) {
    final allAssignedTasks = _dashboardViewModel.priorityDeadlines;

    final highCount = allAssignedTasks
        .where((t) => (t['priority'] ?? 'Low').toLowerCase() == 'high')
        .length;
    final mediumCount = allAssignedTasks
        .where((t) => (t['priority'] ?? 'Low').toLowerCase() == 'medium')
        .length;
    final lowCount = allAssignedTasks
        .where((t) => (t['priority'] ?? 'Low').toLowerCase() == 'low')
        .length;

    final now = DateTime.now();
    final overdueTasks = allAssignedTasks.where((t) {
      final dueDateStr = t['due_date'];
      if (dueDateStr == null || dueDateStr.isEmpty) return false;
      try {
        final dueDate = DateTime.parse(dueDateStr);
        return dueDate.isBefore(now) &&
            (t['status'] ?? '').toLowerCase() != 'completed';
      } catch (e) {
        return false;
      }
    }).toList();

    final cards = [
      {
        'title': 'High Priority',
        'count': highCount,
        'color': 0xFFEF4444,
        'icon': Icons.error,
        'subtitle': '$highCount task${highCount != 1 ? 's' : ''} assigned',
      },
      {
        'title': 'Medium Priority',
        'count': mediumCount,
        'color': 0xFFF97316,
        'icon': Icons.warning,
        'subtitle': '$mediumCount task${mediumCount != 1 ? 's' : ''} assigned',
      },
      {
        'title': 'Low Priority',
        'count': lowCount,
        'color': 0xFF22C55E,
        'icon': Icons.info,
        'subtitle': '$lowCount task${lowCount != 1 ? 's' : ''} assigned',
      },
      {
        'title': 'Overdue Tasks',
        'count': overdueTasks.length,
        'color': 0xFF8B5CF6,
        'icon': Icons.schedule,
        'subtitle':
            '${overdueTasks.length} task${overdueTasks.length != 1 ? 's' : ''} overdue',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final color = Color(card['color'] as int);
        final cardTitle = card['title'] as String;

        return GestureDetector(
          onTap: () {
            List<Map<String, dynamic>> filteredTasks;

            if (cardTitle == 'High Priority') {
              filteredTasks = allAssignedTasks
                  .where(
                      (t) => (t['priority'] ?? 'Low').toLowerCase() == 'high')
                  .toList();
            } else if (cardTitle == 'Medium Priority') {
              filteredTasks = allAssignedTasks
                  .where(
                      (t) => (t['priority'] ?? 'Low').toLowerCase() == 'medium')
                  .toList();
            } else if (cardTitle == 'Low Priority') {
              filteredTasks = allAssignedTasks
                  .where((t) => (t['priority'] ?? 'Low').toLowerCase() == 'low')
                  .toList();
            } else {
              filteredTasks = overdueTasks;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TasksByCategoryScreen(
                  title: cardTitle,
                  tasks: filteredTasks,
                  categoryColor: color,
                ),
              ),
            ).then((result) {
              if (result == true && mounted) {
                _loadBalance();
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        card['icon'] as IconData,
                        size: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        card['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${card['count']} tasks',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card['subtitle'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = date.difference(now);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Tomorrow';
      } else if (difference.inDays < 0) {
        return 'Overdue';
      } else if (difference.inDays < 7) {
        return 'In ${difference.inDays} days';
      } else {
        return '${date.month}/${date.day}';
      }
    } catch (e) {
      return '';
    }
  }

  Future<void> _showAllTasksModal(BuildContext context) {
    final tasks = _dashboardViewModel.priorityDeadlines;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6F7F8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Scaffold(
              backgroundColor: const Color(0xFFF6F7F8),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: Text(
                  _isAdmin ? "All Priority Tasks" : "My Priority Tasks",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111418),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF111418)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.green[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No priority tasks at this time",
                            style: GoogleFonts.inter(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Priority Levels",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildLegendItem(
                                    "High",
                                    Color(DashboardService.getPriorityInfo(
                                        'High')['color'] as int),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildLegendItem(
                                    "Medium",
                                    Color(DashboardService.getPriorityInfo(
                                        'Medium')['color'] as int),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildLegendItem(
                                    "Low",
                                    Color(DashboardService.getPriorityInfo(
                                        'Low')['color'] as int),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              final priority = task['priority'] ?? 'Low';
                              final priorityInfo =
                                  DashboardService.getPriorityInfo(priority);
                              final urgencyColor =
                                  Color(priorityInfo['color'] as int);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TaskDetailsScreen(
                                          task: task,
                                          organizationId: widget
                                              .organization['id']
                                              .toString(),
                                        ),
                                      ),
                                    ).then((taskUpdated) {
                                      if (taskUpdated == true && mounted) {
                                        _loadBalance();
                                      }
                                    });
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border(
                                          left: BorderSide(
                                            color: urgencyColor,
                                            width: 4,
                                          ),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                urgencyColor.withOpacity(0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: urgencyColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  Icons.priority_high,
                                                  size: 14,
                                                  color: urgencyColor,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      task['title'] ??
                                                          'Untitled Task',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                            0xFF111418),
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      task['projectName'] ??
                                                          'No Project',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: urgencyColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  priorityInfo['label']
                                                      as String,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: urgencyColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (task['due_date'] != null)
                                                Text(
                                                  _formatDate(task['due_date']),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsListFromViewModel(BuildContext context) {
    return Consumer<ProjectsViewModel>(
      builder: (context, projectsViewModel, _) {
        if (projectsViewModel.currentOrganizationId == null ||
            projectsViewModel.currentOrganizationId !=
                widget.organization['id'].toString()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            projectsViewModel.fetchProjectsWithProgress(
                widget.organization['id'].toString());
          });
        }

        if (projectsViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (projectsViewModel.projects.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "No projects yet. Create one to get started!",
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
          );
        }

        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: projectsViewModel.projects.length,
            itemBuilder: (context, index) {
              final project = projectsViewModel.projects[index];
              // Use cached progress instead of individual FutureBuilder calls
              final progress = projectsViewModel
                  .getProjectProgressFromCache(project.id)
                  .clamp(0.0, 1.0);

              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 16,
                ),
                child: _buildProjectCard(
                  project.name,
                  project.description ?? 'No description',
                  progress,
                  'In Progress',
                  const Color(0xFF137FEC),
                  project: project,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProjectCard(
    String title,
    String sub,
    double progress,
    String days,
    Color color, {
    Project? project,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectOverviewScreen(
              organization: widget.organization,
              project: project,
              onTabChange: widget.onTabChange,
            ),
          ),
        );
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.rocket_launch, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            Text(sub,
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
            const Spacer(),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF3F4F6),
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(progress * 100).toInt()}% Complete",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  days,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
