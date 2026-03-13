import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../projects/projects_list.dart';
import 'main_dashboard_screen.dart';

class OrganizationDashboard extends StatefulWidget {
  const OrganizationDashboard({super.key});

  @override
  State<OrganizationDashboard> createState() => _OrganizationDashboardState();
}

class _OrganizationDashboardState extends State<OrganizationDashboard> {
  // track bottom nav selection
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // TOGGLE THIS: Set to true to see the "Empty State" UI
    // TODO: Replace with actual logic to determine if dashboard has content
    bool isDashboardEmpty = false;

    final List<Map<String, dynamic>> deadlines = [
      {'title': 'Logistics', 'tasks': '3 tasks due today', 'icon': Icons.local_shipping, 'color': Colors.orange},
      {'title': 'Visuals', 'tasks': '5 tasks due tomorrow', 'icon': Icons.palette, 'color': Colors.purple},
      {'title': 'Dev Ops', 'tasks': '1 task due on 3/15/26', 'icon': Icons.code, 'color': Colors.blue},
      {'title': 'Marketing', 'tasks': '1 task due on 3/20/26', 'icon': Icons.campaign, 'color': Colors.green},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFF137FEC),
        unselectedItemColor: Colors.grey,
        onTap: (idx) {
          setState(() {
            currentIndex = idx;
          });
          // simple tab navigation placeholder
          if (idx == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProjectsList(),
              ),
            );
          }
          // TODO: handle other indexes for naviagtion
        },
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
                      _buildFinancialCard(),
                      const SizedBox(height: 24),
                      if (isDashboardEmpty)
                        _buildEmptyState()
                      else ...[
                        _buildSectionHeader("Priority Deadlines", ""),
                        const SizedBox(height: 12),
                        _buildDeadlinesGrid(deadlines),
                        const SizedBox(height: 24),
                        _buildSectionHeader("Active Projects", "See All"),
                        const SizedBox(height: 12),
                        _buildProjectsList(),
                      ],
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
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
                  // TODO: Replace with actual organization name
                  "[Organization] Workspace",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111418),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainDashboardScreen(),
                              ),
                            );
                  },
                  child: Stack(
                    children: [
                      // TODO: implement notifications (low priority) and show red dot only when there are unread notifications
                      SvgPicture.asset(
                        'assets/icons/bell.svg',
                        width: 24,
                        height: 24,
                        placeholderBuilder: (context) => const Icon(Icons.notifications_none),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF137FEC),
            Color.fromARGB(255, 33, 70, 113),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF137FEC).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TOTAL DEPOSITORY BALANCE",
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.visibility_outlined, color: Colors.white, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          // TODO: Replace with actual balance data
          Text(
            "P45,280.00",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            // TODO: Implement financial details navigation
            onPressed: () {
              
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF137FEC),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text("View Financial Details"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.assignment_add, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              "No Active Projects Yet",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              "Get started by creating your first organization task or project.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProjectsList(),
              ),
            );
          },
          child: Text(actionText, style: const TextStyle(color: Color(0xFF137FEC))),
        ),
      ],
    );
  }

  Widget _buildDeadlinesGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
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

  Widget _buildProjectsList() {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          //TODO: Replace with actual project data
          _buildProjectCard("Project Phoenix", "Q3 Product Revamp", 0.75, "12 Days Left", const Color(0xFF137FEC)),
          const SizedBox(width: 16),
          _buildProjectCard("Global Retail", "Expansion Phase 1", 0.40, "45 Days Left", Colors.green),
        ],
      ),
    );
  }

  Widget _buildProjectCard(String title, String sub, double progress, String days, Color color) {
    return Container(
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
              color: color.withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(8)
              ),
            child: Icon(
              Icons.rocket_launch, 
              color: color, 
              size: 20
              ),
          ),
          const SizedBox(height: 12),
          Text(
            title, 
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold, 
              fontSize: 14)
              ),
          Text(
            sub, 
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 12
              )),
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
    );
  }
}
