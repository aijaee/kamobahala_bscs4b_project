import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../projects/projects_list.dart';
import '../projects/new_proj_screen.dart';
import '../dashboard/organization_dashboard.dart';
import '../dashboard/financial_ledger.dart';
import '../profile/profile_screen.dart';
import '../../core/services/admin_service.dart';
import '../../viewmodels/projects_viewmodel.dart';
import '../../viewmodels/financial_viewmodel.dart';

class MainNavigationWrapper extends StatefulWidget {
  final Map<String, dynamic> organization;
  final int initialIndex;

  const MainNavigationWrapper({
    super.key,
    required this.organization,
    this.initialIndex = 1,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int currentIndex;
  bool _isAdmin = true;
  bool _isLoading = true;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _checkAdminStatus();
    _refreshViewModels();
  }

  @override
  void didUpdateWidget(MainNavigationWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If organization changed, refresh all view models
    if (oldWidget.organization['id'] != widget.organization['id']) {
      _checkAdminStatus();
      _refreshViewModels();
    }
  }

  Future<void> _refreshViewModels() async {
    if (!mounted) return;
    
    try {
      final orgId = widget.organization['id'].toString();
      
      // Refresh Projects ViewModel
      final projectsVM = context.read<ProjectsViewModel>();
      projectsVM.clearProjects(); // Clear old data first
      await projectsVM.fetchProjectsWithProgress(orgId);
      
      // Refresh Financial ViewModel  
      final financialVM = context.read<FinancialViewModel>();
      financialVM.clearTransactions(); // Clear old data first
      await financialVM.fetchTransactions(orgId);
    } catch (e) {
      print('Error refreshing view models: $e');
    }
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isUserAdmin(widget.organization['id']);
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: currentIndex == 1 && !_isLoading && _isAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF137FEC),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateProjectScreen(organization: widget.organization),
                  ),
                ).then((_) async {
                  // Refresh projects when returning
                  if (mounted) {
                    // Refresh the projects list
                    await context.read<ProjectsViewModel>()
                        .fetchProjectsWithProgress(widget.organization['id'].toString());
                    setState(() {});
                  }
                });
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          // Main content
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: [
                // Index 0: Dashboard
                OrganizationDashboard(
                  organization: widget.organization,
                  onTabChange: (index) => setState(() => currentIndex = index),
                ),
                // Index 1: Projects
                ProjectsList(
                  organization: widget.organization,
                  initialIndex: 1,
                  onTabChange: (index) => setState(() => currentIndex = index),
                ),
                // Index 2: Finances
                FinancialLedgerScreen(
                  initialIndex: 2,
                  organization: widget.organization,
                  onTabChange: (index) => setState(() => currentIndex = index),
                ),
                // Index 3: Profile
                ProfileScreen(
                  organizationId: widget.organization['id'],
                  onTabChange: (index) => setState(() => currentIndex = index),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          border: const Border(
            top: BorderSide(color: Color(0xFFF3F4F6)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          selectedItemColor: const Color(0xFF137FEC),
          unselectedItemColor: const Color(0xFF9CA3AF),
          onTap: (idx) {
            setState(() => currentIndex = idx);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          showUnselectedLabels: true,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.grid_view_rounded,
                color: !_isLoading && !_isAdmin ? const Color(0xFFBCC0C8) : null,
              ),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    color:
                        !_isLoading && !_isAdmin ? const Color(0xFFBCC0C8) : null,
                  ),
                  if (!_isLoading && !_isAdmin)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAAA08),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          'M',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: "Projects",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.account_balance_wallet_outlined,
                color:
                    !_isLoading && !_isAdmin ? const Color(0xFFBCC0C8) : null,
              ),
              label: "Finances",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person_outline,
                color: !_isLoading && !_isAdmin ? const Color(0xFFBCC0C8) : null,
              ),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
