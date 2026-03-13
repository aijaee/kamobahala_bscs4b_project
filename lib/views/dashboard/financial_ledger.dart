import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FinancialLedgerScreen extends StatelessWidget {
  const FinancialLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              _buildBalanceCard(),
              _buildFilterTabs(),
              _buildDateHeader("TODAY"),
              _buildTransactionItem(
                label: "Venue Rental",
                status: "Budget Proposal Approved",
                department: "Logistics",
                amount: -2500.00,
                time: "10:45 AM",
                deptColor: Colors.blue,
              ),
              _buildTransactionItem(
                label: "Sponsorship Grant",
                status: "Sponsorship",
                department: "Finance",
                amount: 5000.00,
                time: "09:15 AM",
                deptColor: Colors.green,
              ),
              _buildDateHeader("YESTERDAY"),
              _buildTransactionItem(
                label: "Food Budget",
                status: "For reimbursement",
                department: "Human Relations",
                amount: -890.50,
                time: "04:20 PM",
                deptColor: Colors.orange,
              ),
              _buildTransactionItem(
                label: "Event Prizes",
                status: "Approved",
                department: "Academic Affairs",
                amount: -1250.00,
                time: "01:30 PM",
                deptColor: Colors.purple,
              ),
            ],
          ),
          _buildFloatingActionButton(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.8),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF111418), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Financial Ledger",
        style: GoogleFonts.inter(
          color: const Color(0xFF111418),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Color(0xFF111418)),
          onPressed: () {},
        ),
      ],
      shape: const Border(bottom: BorderSide(color: Color(0x0D137FEC))),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF137FEC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF137FEC).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TOTAL DEPOSITORY BALANCE",
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "P12,450.00",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip("All", true),
          _filterChip("Income", false),
          _filterChip("Expenses", false),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF137FEC) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: isActive ? Colors.white : const Color(0xFF617589),
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDateHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF6F7F8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: const Color(0xFF617589),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required String label,
    required String status,
    required String department,
    required double amount,
    required String time,
    required Color deptColor,
  }) {
    bool isIncome = amount > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0x0D137FEC))),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isIncome ? const Color(0x1A22C55E) : const Color(0x1A137FEC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome ? Icons.south_west : Icons.north_east,
              color: isIncome ? const Color(0xFF16A34A) : const Color(0xFF137FEC),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(status, style: GoogleFonts.inter(color: const Color(0xFF617589), fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: deptColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    department.toUpperCase(),
                    style: GoogleFonts.inter(color: deptColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isIncome ? '+' : ''}P${amount.abs().toStringAsFixed(2)}",
                style: GoogleFonts.inter(
                  color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(time, style: GoogleFonts.inter(color: const Color(0xFF617589), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      right: 24,
      bottom: 24,
      child: FloatingActionButton(
        backgroundColor: const Color(0xFF137FEC),
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}