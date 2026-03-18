import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'task_details.dart';
import 'new_task_screen.dart';
import '../dashboard/organization_dashboard.dart';
import '../dashboard/financial_ledger.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildDateHeader("3/20/2026"),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TaskDetailsScreen()),
                    );
                  },
                  child: _buildTaskItem(
                    title: "Venue Contract Signing",
                    assignee: "Executive President",
                    cost: "P10,000",
                    priority: "HIGH",
                    priorityColor: Colors.redAccent,
                    isCompleted: false,
                  ),
                ),
                _buildTaskItem(
                  title: "Buffet Menu Selection",
                  assignee: "DHR",
                  cost: "P0",
                  priority: "MEDIUM",
                  priorityColor: Colors.orangeAccent,
                  isCompleted: false,
                ),
                _buildTaskItem(
                  title: "Local off Campus Process",
                  assignee: "Executive Secretary",
                  cost: "P0",
                  priority: "HIGH",
                  priorityColor: Colors.blueGrey,
                  isCompleted: true,
                ),
                _buildDateHeader("4/5/2026"),
                _buildTaskItem(
                  title: "Medals and Trophies Procurement",
                  assignee: "DAA",
                  cost: "P8,500",
                  priority: "MEDIUM",
                  priorityColor: Colors.orangeAccent,
                  isCompleted: false,
                ),
                _buildTaskItem(
                  title: "Marketing Posts",
                  assignee: "DPR",
                  cost: "P0",
                  priority: "MEDIUM",
                  priorityColor: Colors.orangeAccent,
                  isCompleted: false,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewTaskScreen()),
          );
        },
        backgroundColor: const Color(0xFF137FEC),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF137FEC)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "CS Gala Preparation",
        style: GoogleFonts.inter(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Project Progress", style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
              Text("68%", style: GoogleFonts.inter(color: const Color(0xFF137FEC), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.68,
              minHeight: 8,
              backgroundColor: Color(0xFFF3F4F6),
              color: Color(0xFF137FEC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        date,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF617589),
        ),
      ),
    );
  }

  Widget _buildTaskItem({
    required String title,
    required String assignee,
    required String cost,
    required String priority,
    required Color priorityColor,
    required bool isCompleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        priority,
                        style: GoogleFonts.inter(
                          color: priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "$assignee • $cost",
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          isCompleted
              ? const Icon(Icons.check_circle, color: Color(0xFF137FEC))
              : const Icon(Icons.delete_outline, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF137FEC),
      unselectedItemColor: Colors.grey,
      currentIndex: 1,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrganizationDashboard(organization: {'name': 'Sample Org'})));
        } else if (index == 2) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FinancialLedgerScreen(organization: {'name': 'Sample Org'})));
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: "Projects"),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: "Finances"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
      ],
    );
  }
}