import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'financial_ledger.dart';

class OrganizationDashboard extends StatelessWidget {
  const OrganizationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // TOGGLE THIS: Set to true to see the "Empty State" UI
    bool isDashboardEmpty = false;

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
                      _buildFinancialCard(context), // Pass context for navigation
                      const SizedBox(height: 24),
                      if (isDashboardEmpty)
                        _buildEmptyState()
                      else ...[
                        _buildSectionHeader("Priority Deadlines", "View Calendar"),
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
                  "Main Dashboard",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111418),
                  ),
                ),
                Stack(
                  children: [
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
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: "Search tasks, projects, or finances",
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
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
            onPressed: () {
              // Navigates to the Financial Ledger UI
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FinancialLedgerScreen()),
              );
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
          onPressed: () {},
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
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
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(Icons.grid_view_rounded, "Dashboard", true),
          _navItem(Icons.assignment_outlined, "Projects", false),
          _navItem(Icons.account_balance_wallet_outlined, "Finances", false),
          _navItem(Icons.person_outline, "Profile", false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive) {
    final color = isActive ? const Color(0xFF137FEC) : const Color(0xFF9CA3AF);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        Text(label, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}