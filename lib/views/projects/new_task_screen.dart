import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  bool _financialDetailsEnabled = true;
  bool _deductFromBudget = false;
  String _selectedPriority = "Low";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("GENERAL INFORMATION"),
            _buildGeneralInfoCard(),
            _buildSectionHeader("PRIORITY & TIMELINE"),
            _buildPriorityTimelineCard(),
            _buildSectionHeader("FINANCIAL DETAILS", hasSwitch: true),
            if (_financialDetailsEnabled) _buildFinancialDetailsCard(),
            const SizedBox(height: 12),
            _buildNoteCard(),
            const SizedBox(height: 24),
            _buildBudgetAlert(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      // Fixed the "Can-cel" alignment issue by providing more width
      leadingWidth: 80,
      leading: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: GoogleFonts.inter(
              color: const Color(0xFF137FEC),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      title: Text(
        "New Task",
        style: GoogleFonts.inter(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                "Done",
                style: GoogleFonts.inter(
                  color: const Color(0xFF137FEC),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {bool hasSwitch = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF617589),
              letterSpacing: 1.2,
            ),
          ),
          if (hasSwitch)
            Transform.scale(
              scale: 0.8,
              child: Switch.adaptive(
                value: _financialDetailsEnabled,
                activeColor: const Color(0xFF137FEC),
                onChanged: (val) => setState(() => _financialDetailsEnabled = val),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTextField("Task Name"),
          const Divider(height: 1, indent: 16),
          _buildListTile("Category", "Visuals", true),
        ],
      ),
    );
  }

  Widget _buildPriorityTimelineCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ["Low", "Medium", "High"].map((p) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPriority = p),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedPriority == p ? Colors.white : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: _selectedPriority == p ? Border.all(color: const Color(0xFFE5E7EB)) : null,
                      boxShadow: _selectedPriority == p
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                          : null,
                    ),
                    child: Text(
                      p,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: _selectedPriority == p ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          _buildListTile("Assignee", "Franco", true),
          const Divider(height: 1, indent: 16),
          _buildListTile(
            "Due Date",
            "Oct 24, 2023",
            false,
            icon: Icons.calendar_today_outlined,
            iconColor: Colors.redAccent,
            valueColor: const Color(0xFF137FEC),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTextField("Estimated Expense", trailing: "0.00"),
          const Divider(height: 1, indent: 16),
          _buildListTile("Category", "Transportation", true, valueColor: const Color(0xFF137FEC)),
          const Divider(height: 1, indent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Deduct from Project Budget", style: GoogleFonts.inter(fontSize: 15)),
                Transform.scale(
                  scale: 0.8,
                  child: Switch.adaptive(
                    value: _deductFromBudget,
                    activeColor: const Color(0xFF137FEC),
                    onChanged: (val) => setState(() => _deductFromBudget = val),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              "When enabled, the estimated expense will be automatically subtracted from the total remaining project balance.",
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF), height: 1.4),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        maxLines: 4,
        decoration: InputDecoration(
          hintText: "Add a note...",
          hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBudgetAlert() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF137FEC).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF137FEC), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Project Budget: P12,450.00 remaining",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF137FEC),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "This task will reduce the budget by the estimated amount if marked.",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF137FEC).withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 15)),
          const Spacer(),
          if (trailing != null)
            Text(trailing, style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF137FEC))),
          if (trailing == null)
            SizedBox(
              width: 150,
              child: TextField(
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: GoogleFonts.inter(color: const Color(0xFFD1D5DB)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListTile(String label, String value, bool showArrow,
      {IconData? icon, Color? iconColor, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
          ],
          Text(label, style: GoogleFonts.inter(fontSize: 15)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: valueColor ?? const Color(0xFF9CA3AF),
            ),
          ),
          if (showArrow) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFD1D5DB)),
          ]
        ],
      ),
    );
  }
}