import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(),
            _buildInfoGrid(),
            _buildDescription(),
            _buildBudgetSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(), // Consistent navigation
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFC76F6F), // Mapped from your gradient
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Task Details",
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF8282), // Updated to match image gradient
            Color(0xFF863131), // Mapped darker red
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC), // Blue badge color
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Logistics".toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
            ],
          ),
          const Spacer(),
          Text(
            "Venue Contract Signing", // NEW TITLE
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28, // Increased size for hero feel
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 24,
        childAspectRatio: 3.5, // Matches the spacing in image
        children: [
          _buildGridItem(Icons.label_important, "Priority", "High Priority",
              color: const Color(0xFFEF4444)), // Red for High
          _buildGridItem(
              Icons.sync, "Status", "In Progress", color: const Color(0xFF137FEC)), // Blue for Progress
          _buildGridItem(
              Icons.calendar_today, "Due Date", "March 20, 2026", color: const Color(0xFF617589)),
          _buildGridItem(Icons.person, "Assigned to", "SELO", color: const Color(0xFF617589)), // Grey/Black
        ],
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color?.withValues(alpha: 0.8) ?? const Color(0xFF617589)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label.toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9CA3AF),
                    letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color ?? Colors.black)),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Description".toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),
          Text(
            "Reserving a Venue of CS Gala : First Class Lounge, year-end celebration and tribute to graduating CS students. Venue Contract Signing with Circle Inn.", // NEW DESCRIPTION
            style: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFF111418), height: 1.6),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF3F4F6), thickness: 1),
        ],
      ),
    );
  }

  Widget _buildBudgetSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Expenses & Budget".toUpperCase(),
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9CA3AF),
                      letterSpacing: 0.8)),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF137FEC)),
                label: Text("Add Entry",
                    style: GoogleFonts.inter(color: const Color(0xFF137FEC), fontWeight: FontWeight.bold, fontSize: 13)),
              )
            ],
          ),
          _buildSummaryCard(),
          const SizedBox(height: 12),
          _buildExpenseItem(Icons.business_center, "Venue Reservation", "Oct 12 • Logistics", "10,000", const Color(0xFF16A34A)), // GREEN
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8), // Grey card background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryText("Task Expenses", "10,000", Colors.black), // Black
              _buildSummaryText("Task Budget Remaining", "79,000", Colors.black), // Black
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.112, // 10k / 89k total budget approx
              minHeight: 10,
              backgroundColor: Color(0xFFE5E7EB),
              color: Color(0xFF137FEC), // Blue progress color
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "11.2% of task allocation used. Updates organization ledger automatically.", // Updated Text
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryText(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text("P$value",
            style: GoogleFonts.inter(
                fontSize: 28, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildExpenseItem(IconData icon, String title, String subtitle, String cost, Color costColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3F4F6))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF617589), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Text("P$cost",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: costColor)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF137FEC),
      unselectedItemColor: const Color(0xFF9CA3AF),
      currentIndex: 1, // Projects
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: "Projects"),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: "Finances"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
      ],
    );
  }
}