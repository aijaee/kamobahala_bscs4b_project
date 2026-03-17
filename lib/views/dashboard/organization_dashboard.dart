import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/services/financial_service.dart';
import 'financial_ledger.dart';
import '../projects/projects_list.dart';

class OrganizationDashboard extends StatefulWidget {
  final Map<String, dynamic> organization;
  const OrganizationDashboard({super.key, required this.organization});

  @override
  State<OrganizationDashboard> createState() => _OrganizationDashboardState();
}

class _OrganizationDashboardState extends State<OrganizationDashboard> {
  // track bottom nav selection
  int currentIndex = 0;
  // TODO: [MVVM] move UI state (selectedIndex, balance fetch) into OrganizationDashboardViewModel
  int _selectedIndex = 0;
  final FinancialService _financialService = FinancialService();
  late Future<double> _balanceFuture;

  @override
  void initState() {
    super.initState();
    _balanceFuture = _loadBalance();
  }

  // TODO: [MVVM] replace with ViewModel.loadBalance() and observe via Provider/Consumer
  Future<double> _loadBalance() async {
    try {
      final transactions = await _financialService
          .fetchTransactions(widget.organization['id'].toString());
      return _financialService.calculateBalance(widget.organization, transactions);
    } catch (_) {
      return double.tryParse(widget.organization['budget']?.toString() ?? '') ?? 0;
    }
  }
  int _selectedIndex = 0;
  final FinancialService _financialService = FinancialService();
  late Future<double> _balanceFuture;

  @override
  void initState() {
    super.initState();
    _balanceFuture = _loadBalance();
  }

  Future<double> _loadBalance() async {
    try {
      final transactions = await _financialService
          .fetchTransactions(widget.organization['id'].toString());
      return _financialService.calculateBalance(widget.organization, transactions);
    } catch (_) {
      return double.tryParse(widget.organization['budget']?.toString() ?? '') ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> deadlines = [
      {
        'title': 'Logistics',
        'tasks': '3 tasks due today',
        'icon': Icons.local_shipping,
        'color': Colors.orange
      },
      {
        'title': 'Visuals',
        'tasks': '5 tasks this week',
        'icon': Icons.palette,
        'color': Colors.purple
      },
      {
        'title': 'Dev Ops',
        'tasks': '1 urgent patch',
        'icon': Icons.code,
        'color': Colors.blue
      },
      {
        'title': 'Marketing',
        'tasks': 'All clear',
        'icon': Icons.campaign,
        'color': Colors.green
      },
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
                      // TODO: [MVVM] use ViewModel.balance and avoid FutureBuilder in view
                      _buildFinancialCard(
                          context), // Pass context for navigation
                      const SizedBox(height: 24),
                      _buildFinancialCard(
                          context), // Pass context for navigation
                      const SizedBox(height: 24),
                      _buildSectionHeader("Priority Deadlines", "View Calendar"),
                      const SizedBox(height: 12),
                      _buildDeadlinesGrid(deadlines),
                      const SizedBox(height: 24),

                      _buildSectionHeader(
                        "Active Projects",
                        "See All",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectsList(
                                initialIndex: 1,
                                organization: widget.organization,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildProjectsList(),
                      _buildSectionHeader("Active Projects", "See All"),
                      const SizedBox(height: 12),
                      _buildProjectsList(),
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
                  // Napoleon: Standardized navigation, secured config keys, and implemented dynamic data fetching.
                  widget.organization['name'] ?? 'Organization',
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
              const Icon(Icons.visibility_outlined,
                  color: Colors.white, size: 18),
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
          // TODO: [MVVM] bind balance from ViewModel instead of local FutureBuilder
          FutureBuilder<double>(
            future: _balanceFuture,
            builder: (context, snapshot) {
              final balance = snapshot.data ??
                  (double.tryParse(widget.organization['budget']?.toString() ?? '') ??
                      0);

              return Text(
                _formatCurrency(balance),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigates to the Financial Ledger UI
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FinancialLedgerScreen(
                        organization: widget.organization)),
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

  String _formatCurrency(double amount) {
    final absolute = amount.abs().toStringAsFixed(2);
    final parts = absolute.split('.');
    final whole = parts[0];
    final decimals = parts[1];
    final buffer = StringBuffer();

    for (var index = 0; index < whole.length; index++) {
      final reversedIndex = whole.length - index;
      buffer.write(whole[index]);
      if (reversedIndex > 1 && reversedIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    final prefix = amount < 0 ? '-₱' : '₱';
    return '$prefix${buffer.toString()}.$decimals';
  }

  Widget _buildSectionHeader(String title, String actionText, {VoidCallback? onPressed}) {
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
          onPressed: onPressed ?? () {},
          child: Text(actionText,
              style: const TextStyle(color: Color(0xFF137FEC))),
          onPressed: () {},
          child: Text(actionText,
              style: const TextStyle(color: Color(0xFF137FEC))),
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
                  Text(item['title'],
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const Spacer(),
              Text(item['tasks'],
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  // TODO: [MVVM] move project list content into ViewModel and make this data-driven
  Widget _buildProjectsList() {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildProjectCard("Project Phoenix", "Q3 Product Revamp", 0.75,
              "12 Days Left", const Color(0xFF137FEC)),
          const SizedBox(width: 16),
          _buildProjectCard("Global Retail", "Expansion Phase 1", 0.40,
              "45 Days Left", Colors.green),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
      String title, String sub, double progress, String days, Color color) {
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
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.rocket_launch, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title,
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(sub, style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
          const Spacer(),
          LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF3F4F6),
              color: color,
              borderRadius: BorderRadius.circular(10)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${(progress * 100).toInt()}% Complete",
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(days,
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    // TODO: [MVVM] move _selectedIndex and nav logic into ViewModel, e.g. OrganizationDashboardViewModel.currentTab

  Widget _buildBottomNav() {
    // Napoleon: Removed BottomNav from Org Selection and consolidated logic in Main Dashboard.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => ProjectsList(
                      initialIndex: 1, organization: widget.organization)),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => FinancialLedgerScreen(
                      initialIndex: 2, organization: widget.organization)),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
          // TODO: Handle Profile navigation
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF137FEC),
        unselectedItemColor: const Color(0xFF9CA3AF),
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined), label: "Projects"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: "Finances"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}
