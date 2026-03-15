import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // Napoleon: Removed BottomNav from Org Selection and consolidated logic in Main Dashboard.
  final AuthService _authService = AuthService();
  final OrganizationService _orgService = OrganizationService();

  String _fullName = "User";
  List<Map<String, dynamic>> _organizations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Napoleon: Implemented live backend integration.
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

    if (mounted) {
      setState(() {
        _organizations = orgs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Napoleon: Implemented live backend functionality.
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
            /// HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _authService.getUserProfile(),
                        builder: (context, snapshot) {
                          // Napoleon: Fixed atomic registration and database sync.
                          final displayName = snapshot.data?['full_name'] ??
                              _authService
                                  .currentUser?.userMetadata?['full_name'] ??
                              _fullName;
                          return Text(
                            "Welcome back, $displayName!",
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          // Napoleon: Implemented live backend integration.
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

            /// SCROLLABLE CONTENT
            Expanded(
                child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ORGANIZATIONS
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
            // Napoleon: Implemented live backend functionality.
            return _buildOrganizationCard(org, context);
          },
        ),
      ],
    );
  }

  Widget _buildOrganizationCard(
      Map<String, dynamic> org, BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // navigate to organization's dashboard
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
                      // BACKEND PLACEHOLDER: Role is hardcoded as all orgs are user-owned for now
                      'Admin',
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
                    // TODO: leave organization
                  }

                  if (value == 'edit') {
                    // Napoleon: Implemented live backend functionality.
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

                  // Only admins can edit
                  // BACKEND PLACEHOLDER: Role is hardcoded as all orgs are user-owned for now
                  if ('admin' == "admin") {
                    items.add(
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 10),
                            Text("Edit Organization"),
                          ],
                        ),
                      ),
                    );
                  }

                  items.add(
                    const PopupMenuItem(
                        value: 'leave',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18),
                            SizedBox(width: 10),
                            Text("Leave Organization"),
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
