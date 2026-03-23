import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/financial_viewmodel.dart';
import '../../viewmodels/organization_dashboard_viewmodel.dart';
import '../../viewmodels/projects_viewmodel.dart';
import 'financial_ledger.dart';
import '../projects/projects_list.dart';
import '../projects/project_overview.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeViewModels();
    WidgetsBinding.instance.addObserver(this);
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
    _loadBalance();
    _financialViewModel.addListener(_onViewModelChanged);
  }

  void _cleanupViewModels() {
    _financialViewModel.removeListener(_onViewModelChanged);
    _financialViewModel.dispose();
    _dashboardViewModel.dispose();
  }

  void _onViewModelChanged() {
    setState(() {});
  }

  /// Loads balance using ViewModel
  Future<void> _loadBalance() async {
    await _financialViewModel
        .fetchTransactions(widget.organization['id'].toString());
    _dashboardViewModel.calculateFinancialSummary(
      widget.organization,
      _financialViewModel.transactions,
    );
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
    final List<Map<String, dynamic>> deadlines = [
      {'title': 'Logistics', 'tasks': '3 tasks due today', 'icon': Icons.local_shipping, 'color': Colors.orange},
      {'title': 'Visuals', 'tasks': '5 tasks this week', 'icon': Icons.palette, 'color': Colors.purple},
      {'title': 'Dev Ops', 'tasks': '1 urgent patch', 'icon': Icons.code, 'color': Colors.blue},
      {'title': 'Marketing', 'tasks': 'All clear', 'icon': Icons.campaign, 'color': Colors.green},
    ];

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
                      _buildSectionHeader("Priority Deadlines", "View Calendar"),
                      const SizedBox(height: 12),
                      _buildDeadlinesGrid(deadlines),
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
              const Icon(Icons.visibility_outlined, color: Colors.white, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          // Bind balance from ViewModel
          Text(
            _formatCurrency(_dashboardViewModel.currentBalance),
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

  Widget _buildDeadlinesGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF3F4F6))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(item['icon'], size: 16, color: item['color']),
                  const SizedBox(width: 8),
                  Text(item['title'], style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ],
              ),
              const Spacer(),
              Text(item['tasks'], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
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