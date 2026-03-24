import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/organization_service.dart';
import 'organization_dashboard.dart';
import '../auth/login_screen.dart';
import 'create_organization_screen.dart';
import 'edit_organization_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {

  // TODO: Implement actual navigation logic and state management for bottom nav
  int currentIndex = 0;
  final AuthService _authService = AuthService();
  final OrganizationService _orgService = OrganizationService();
  final AdminService _adminService = AdminService();

  String _fullName = "User";
  List<Map<String, dynamic>> _organizations = [];
  Map<String, String> _userRoles = {};
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final profile = await _authService.getUserProfile();
    if (profile != null && profile['full_name'] != null) {
      if (mounted) setState(() => _fullName = profile['full_name']);
    }

    var orgs = await _orgService.getOrganizations();
    Map<String, String> roles = {};
    for (var org in orgs) {
      final role = await _adminService.getUserRoleInOrganization(org['id']);
      if (role != null) {
        roles[org['id']] = role;
      }
    }

    if (mounted) {
      setState(() {
        _organizations = orgs;
        _userRoles = roles;
        _isLoading = false;
      });
    }
  }

  Future<void> _leaveOrganization(
      Map<String, dynamic> org, BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Organization?'),
        content: Text(
            'Are you sure you want to leave "${org['name']}"? You won\'t be able to access it anymore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Get current user email
    final currentUserEmail = _authService.currentUser?.email;
    if (currentUserEmail == null) return;

    // Remove user from organization
    final success = await _adminService.removeMember(org['id'], currentUserEmail);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have left the organization')),
      );
      // Refresh the list
      _fetchData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to leave organization')),
      );
    }
  }

  Future<void> _deleteOrganization(
      Map<String, dynamic> org, BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Organization?'),
        content: Text(
            'Are you sure you want to permanently delete "${org['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete the organization
    try {
      await _orgService.deleteOrganization(org['id']);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization deleted successfully')),
      );
      // Refresh the list
      _fetchData();
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete organization: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasOrganizations = _organizations.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromARGB(255, 11, 83, 155),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateOrganizationScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Create Organization",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _authService.getUserProfile(),
                          builder: (context, snapshot) {
                            final displayName = snapshot.data?['full_name'] ??
                                _authService
                                    .currentUser?.userMetadata?['full_name'] ??
                                _fullName;
                            return Text(
                              "Welcome back, $displayName!",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await _authService.signOut();
                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
                child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TODO: [MVVM] bind UI to ViewModel.isLoading and ViewModel.organizations
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (!hasOrganizations)
                      _buildOrgEmptyState()
                    else
                      _buildOrganizationList(_organizations),
                    const SizedBox(height: 24),
                  ]),
            ))
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationList(List<Map<String, dynamic>> orgs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Organizations",
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orgs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final org = orgs[index];
            final userRole = _userRoles[org['id']] ?? 'Member';
            return _buildOrganizationCard(org, userRole, context);
          },
        ),
      ],
    );
  }

  Widget _buildOrganizationCard(
      Map<String, dynamic> org, String userRole, BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrganizationDashboard(organization: org),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF137FEC),
                Color.fromARGB(255, 33, 70, 113),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(255, 255, 255, 255).withOpacity(.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business,
                  color: Color.fromARGB(255, 236, 236, 236),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org['name'] ?? 'Unnamed',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color.fromARGB(255, 243, 243, 243),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userRole,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color.fromARGB(255, 222, 222, 222),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                icon: const Icon(
                  Icons.more_vert,
                  color: Color.fromARGB(255, 208, 208, 208),
                ),
                onSelected: (value) {
                  if (value == 'leave') {
                    _leaveOrganization(org, context);
                  }

                  if (value == 'delete') {
                    _deleteOrganization(org, context);
                  }

                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditOrganizationScreen(organization: org),
                      ),
                    );
                  }
                },
                itemBuilder: (context) {
                  List<PopupMenuEntry<String>> items = [];

                  // Show edit and delete options only for admins
                  if (userRole.toLowerCase() == 'admin') {
                    items.add(
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text("Edit Organization"),
                            ),
                          ],
                        ),
                      ),
                    );
                    items.add(
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text("Delete Organization"),
                            ),
                          ],
                        )),
                  );
                  }

                  items.add(
                    const PopupMenuItem(
                        value: 'leave',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text("Leave Organization"),
                            ),
                          ],
                        )),
                  );

                  return items;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrgEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.domain_disabled,
                size: 80, color: Colors.grey.withOpacity(.3)),
            const SizedBox(height: 16),
            const Text(
              "No Organizations Joined",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "Join or create an organization to get started.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
