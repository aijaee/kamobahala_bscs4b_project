import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'organization_dashboard.dart';
import '../auth/login_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {

  // TODO: Implement actual navigation logic and state management for bottom nav
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // TODO: replace with logic that loads organizations for current user
    bool hasOrganizations = true;
    
    final List<Map<String, String>> organizations = [
      {'name': 'Acme Corp', 'role': 'Member'},
      {'name': 'Beta Solutions', 'role': 'Admin'},
      {'name': 'Gamma Initiatives', 'role': 'Contributor'},
    ];

    // TODO: fetch organization data from database/service

    return Scaffold(

      backgroundColor: const Color(0xFFF6F7F8),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFF137FEC),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });

          // TODO: Navigate to pages 
        },
        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Dashboard",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
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
                      Text(
                        // TODO : replace with actual user name
                        "Welcome back, User!",
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () {
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
                    if (!hasOrganizations) 
                      _buildOrgEmptyState()
                    else
                      _buildOrganizationList(organizations),
                    const SizedBox(height: 24),

                  ]  
                ),
              )
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationList(List<Map<String, String>> orgs) {
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
            return _buildOrganizationCard(org['name']!, org['role']!, context);
          },
        ),
      ],
    );
  }

  Widget _buildOrganizationCard(String name, String role, BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // navigate to organization's dashboard (placeholder)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OrganizationDashboard(),
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
                  color: const Color.fromARGB(255, 255, 255, 255).withOpacity(.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business, color: Color.fromARGB(255, 236, 236, 236)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: const Color.fromARGB(255, 243, 243, 243))),
                    const SizedBox(height: 4),
                    Text(role, style: GoogleFonts.inter(fontSize: 12, color: const Color.fromARGB(255, 222, 222, 222))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color.fromARGB(255, 208, 208, 208)),
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
            Icon(Icons.domain_disabled, size: 80, color: Colors.grey.withOpacity(.3)),
            const SizedBox(height: 16),
            const Text(
              "No Organizations Joined",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "Join or create an organization to get started.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: navigate to join/create org screen
              },
              child: const Text('Join or Create'),
            )
          ],
        ),
      ),
    );
  }
}
