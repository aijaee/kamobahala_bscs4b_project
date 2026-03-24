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
import 'financial_ledger.dart';
import '../projects/projects_list.dart';
import '../projects/project_overview.dart';
import '../projects/task_details.dart';

class OrganizationDashboard extends StatefulWidget {
  final Map<String, dynamic> organization;
  const OrganizationDashboard({super.key, required this.organization});

  @override
  State<OrganizationDashboard> createState() => _OrganizationDashboardState();
}

class _OrganizationDashboardState extends State<OrganizationDashboard>
    with WidgetsBindingObserver {
  // track bottom nav selection
  int currentIndex = 0;
  late FinancialViewModel _financialViewModel;
  late OrganizationDashboardViewModel _dashboardViewModel;
  final OrganizationService _orgService = OrganizationService();
  final AdminService _adminService = AdminService();
  bool _balanceHidden = true;
  bool _isAdmin = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize view models immediately with default values
    _financialViewModel = FinancialViewModel();
    _dashboardViewModel = OrganizationDashboardViewModel(
      financialViewModel: _financialViewModel,
    );
    _financialViewModel.addListener(_onViewModelChanged);
    _dashboardViewModel.addListener(_onViewModelChanged);
    
    // Get admin status and user email, then load data
    _getUserEmail();
    _checkAdminStatus();
    
    // Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBalance();
      }
    });
  }

  @override
  void didUpdateWidget(OrganizationDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the organization changed, reinitialize and reload data
    if (oldWidget.organization['id'] != widget.organization['id']) {
      _cleanupViewModels();
      _initializeViewModels();
      _refreshProjects();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh projects when app resumes (e.g., returning from task list)
      _refreshProjects();
      _loadBalance();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupViewModels();
    super.dispose();
  }

  void _initializeViewModels() {
    _financialViewModel = FinancialViewModel();
    _dashboardViewModel = OrganizationDashboardViewModel(
      financialViewModel: _financialViewModel,
    );
    _financialViewModel.addListener(_onViewModelChanged);
    _dashboardViewModel.addListener(_onViewModelChanged);
    
    // Defer loading balance to after frame
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
    final isAdmin = await _adminService.isUserAdmin(widget.organization['id'].toString());
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

  /// Loads balance using ViewModel
  Future<void> _loadBalance() async {
    await _financialViewModel
        .fetchTransactions(widget.organization['id'].toString());
    _dashboardViewModel.calculateFinancialSummary(
      widget.organization,
      _financialViewModel.transactions,
    );
    
    // Fetch priority deadlines based on user role
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
    
    // Sync member names from profiles to ensure they're populated
    await _orgService.syncMemberNamesFromProfiles(widget.organization['id'].toString());
  }

  /// Refreshes projects for the current organization
  void _refreshProjects() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProjectsViewModel>().fetchProjectsWithProgress(
              widget.organization['id'].toString(),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildFinancialCard(context),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        _isAdmin ? "Priority Overview" : "My Priority Tasks",
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectsList(
                                initialIndex: 1,
                                organization: widget.organization,
                              ),
                            ),
                          );
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
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNav(),
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
                Text(
                  widget.organization['name'] ?? 'Organization',
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF111418)),
                ),
                Stack(
                  children: [
                    const Icon(Icons.notifications_none, size: 24), // Simplified SVG for stability
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: "Search tasks, projects, or finances",
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: const Color(0xFFE5E7EB).withOpacity(0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
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
          BoxShadow(color: const Color(0xFF137FEC).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${widget.organization['name'] ?? 'ORGANIZATION'} TOTAL DEPOSITORY BALANCE".toUpperCase(),
                style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 12, letterSpacing: 0.6, fontWeight: FontWeight.w500),
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
          // Bind balance from ViewModel
          Text(
            _balanceHidden ? "••••••••" : _formatCurrency(_dashboardViewModel.currentBalance),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => FinancialLedgerScreen(organization: widget.organization)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF137FEC),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildSectionHeader(String title, String actionText, {VoidCallback? onPressed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onPressed, child: Text(actionText, style: const TextStyle(color: Color(0xFF137FEC)))),
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
      // Admin view: show priority summary cards
      return _buildAdminPriorityCards(context);
    } else {
      // Member view: show assigned tasks list
      return _buildTasksSection(
        "My Priority Tasks",
        _dashboardViewModel.priorityDeadlines,
        context,
      );
    }
  }

  Widget _buildAdminPriorityCards(BuildContext context) {
    final allTasks = _dashboardViewModel.priorityDeadlines;
    final assignedTasks = _dashboardViewModel.assignedDeadlines;

    // Count tasks by priority
    final highCount =
        allTasks.where((t) => (t['priority'] ?? 'Low').toLowerCase() == 'high').length;
    final mediumCount = allTasks
        .where((t) => (t['priority'] ?? 'Low').toLowerCase() == 'medium')
        .length;
    final lowCount =
        allTasks.where((t) => (t['priority'] ?? 'Low').toLowerCase() == 'low').length;

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
        'subtitle': '$mediumCount task${mediumCount != 1 ? 's' : ''} in progress',
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

        return GestureDetector(
          onTap: () {
            // Could navigate to filtered task list
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

  Widget _buildTasksSection(
    String title,
    List<Map<String, dynamic>> tasks,
    BuildContext context,
  ) {
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: Colors.green[300]),
              const SizedBox(height: 12),
              Text(
                "No priority tasks at this time",
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != "All Priority Tasks" && title != "My Priority Tasks")
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.take(5).length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final priority = task['priority'] ?? 'Low';
            final priorityInfo = DashboardService.getPriorityInfo(priority);
            final urgencyColor = Color(priorityInfo['color'] as int);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailsScreen(task: task),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                    boxShadow: [
                      BoxShadow(
                        color: urgencyColor.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: urgencyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task['title'] ?? 'Untitled Task',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111418),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  task['projectName'] ?? 'No Project',
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: urgencyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              priorityInfo['label'] as String,
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
            );
          },
        ),
        if (tasks.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectsList(
                      initialIndex: 1,
                      organization: widget.organization,
                    ),
                  ),
                );
              },
              child: Text(
                'View all ${tasks.length} tasks',
                style: const TextStyle(color: Color(0xFF137FEC)),
              ),
            ),
          ),
      ],
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
    final tasks = _isAdmin
        ? _dashboardViewModel.priorityDeadlines
        : _dashboardViewModel.priorityDeadlines;

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
                        // Legend Header
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
                                    Color(DashboardService.getPriorityInfo('High')['color'] as int),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildLegendItem(
                                    "Medium",
                                    Color(DashboardService.getPriorityInfo('Medium')['color'] as int),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildLegendItem(
                                    "Low",
                                    Color(DashboardService.getPriorityInfo('Low')['color'] as int),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        // Task List
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
                                        builder: (context) => TaskDetailsScreen(task: task),
                                      ),
                                    );
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
                                            color: urgencyColor.withOpacity(0.08),
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
                                                padding: const EdgeInsets.all(6),
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
                                                padding: const EdgeInsets.symmetric(
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
                                                  _formatDate(
                                                      task['due_date']),
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

  // TODO: [MVVM] move project list content into ViewModel and make this data-driven
  Widget _buildProjectsListFromViewModel(BuildContext context) {
    return Consumer<ProjectsViewModel>(
      builder: (context, projectsViewModel, _) {
        // Initialize projects from ViewModel if not already loaded
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
              final progress = (project['progress'] as num?)?.toDouble() ?? 0.0;
              
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 16,
                  right: index == projectsViewModel.projects.length - 1 ? 0 : 0,
                ),
                child: _buildProjectCard(
                  project['name'] ?? 'Untitled',
                  project['description'] ?? 'No description',
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

  Widget _buildProjectCard(String title, String sub, double progress, String days, Color color, {Map<String, dynamic>? project}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectOverviewScreen(
              organization: widget.organization,
              project: project,
            ),
          ),
        );
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF3F4F6))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.rocket_launch, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(sub, style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
            const Spacer(),
            LinearProgressIndicator(value: progress, backgroundColor: const Color(0xFFF3F4F6), color: color, borderRadius: BorderRadius.circular(10)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${(progress * 100).toInt()}% Complete", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(days, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), border: const Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProjectsList(initialIndex: 1, organization: widget.organization)));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FinancialLedgerScreen(initialIndex: 2, organization: widget.organization)));
          } else {
            setState(() { currentIndex = index; });
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF137FEC),
        unselectedItemColor: const Color(0xFF9CA3AF),
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: "Projects"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: "Finances"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}