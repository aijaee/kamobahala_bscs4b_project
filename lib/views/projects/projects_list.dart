import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dashboard/organization_dashboard.dart';
import '../../core/services/financial_service.dart';
import '../../core/services/project_service.dart';
import 'new_proj_screen.dart';
import '../dashboard/financial_ledger.dart';
import '../../core/services/financial_service.dart';
import '../../core/services/project_service.dart';

import '../dashboard/financial_ledger.dart';

class ProjectsList extends StatefulWidget {
  final int initialIndex;
  final Map<String, dynamic> organization;
  const ProjectsList(
      {super.key, this.initialIndex = 1, required this.organization});

  @override
  State<ProjectsList> createState() => _ProjectsListState();
}

class _ProjectsListState extends State<ProjectsList> {
  // TODO: [MVVM] move these into ViewModel: currentIndex, selectedTab, projects, completedProjects, isLoading, balance, searchQuery
  late int currentIndex;
  late int currentIndex;
  int selectedTab = 0;
  final ProjectService _projectService = ProjectService();
  final FinancialService _financialService = FinancialService();
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _completedProjects = [];
  bool _isLoading = true;
  double _balance = 0;
  String _searchQuery = "";

  final List<String> tabs = [
    "All Projects",
    "Marketing",
    "Product Launch",
    "IT"
  ];

  @override
  void initState() {
    super.initState();
    // TODO: [MVVM] move this to ViewModel initialization and remove direct service calls
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _fetchProjects();
    _fetchCompletedProjects();
    _fetchBalance();
  }

  // TODO: [MVVM] implement fetchProjects() in ViewModel and call from init
  Future<void> _fetchProjects() async {
    final projects = await _projectService
        .fetchProjects(widget.organization['id'].toString());
    if (mounted) {
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    }
  }

  // TODO: [MVVM] replace with ViewModel.fetchBalance() and observe via Provider
  Future<void> _fetchBalance() async {
    try {
      final transactions = await _financialService
          .fetchTransactions(widget.organization['id'].toString());

      if (mounted) {
        setState(() {
          _balance = _financialService.calculateBalance(
            widget.organization,
            transactions,
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _balance =
              double.tryParse(widget.organization['budget']?.toString() ?? '') ?? 0;
        });
      }
    }
  }

  Future<void> _fetchCompletedProjects() async {
    try {
      final projects = await _projectService
          .fetchProjects(widget.organization['id'].toString());
      final completed = projects.where((p) => p['status'] == 'completed').toList();
      
      if (mounted) {
        setState(() {
          _completedProjects = completed;
        });
      }
    } catch (e) {
      debugPrint('Error fetching completed projects: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredProjects() {
    return _projects.where((project) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty ||
          project['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Filter by selected tab
      final matchesTab = selectedTab == 0 ||
          project['department'] == tabs[selectedTab];

      return matchesSearch && matchesTab;
    }).toList();
  }

  @override

  Widget build(BuildContext context) {

  Future<void> _fetchCompletedProjects() async {
    try {
      final projects = await _projectService
          .fetchProjects(widget.organization['id'].toString());
      final completed = projects.where((p) => p['status'] == 'completed').toList();
      
      if (mounted) {
        setState(() {
          _completedProjects = completed;
        });
      }
    } catch (e) {
      debugPrint('Error fetching completed projects: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredProjects() {
    return _projects.where((project) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty ||
          project['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Filter by selected tab
      final matchesTab = selectedTab == 0 ||
          project['department'] == tabs[selectedTab];

      return matchesSearch && matchesTab;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF137FEC),
        onPressed: () {
          // Show dialog to create new project
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Create new project functionality coming soon..."),
            ),
          );
          // TODO: Implement create project dialog/form
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFF137FEC),
        unselectedItemColor: Colors.grey,
        onTap: (idx) {
          if (idx == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    OrganizationDashboard(organization: widget.organization),
              ),
            );
          } else if (idx == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => FinancialLedgerScreen(
                      initialIndex: 2, organization: widget.organization)),
            );
          } else if (idx == 3) {
            // TODO: Navigate to profile screen when ProfileScreen is implemented
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Profile screen coming soon..."),
              ),
            );
          } else {
            setState(() {
              currentIndex = idx;
            });
          }
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
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  _buildFinancialCard(),
                  const SizedBox(height: 20),
                  // TODO: add if condition to allow user to delete a project if they are an admin
                  _sectionHeader("Ongoing Projects", ""),
                  const SizedBox(height: 12),
                  // Dynamic data fetching with search and tab filtering
                  // TODO: [MVVM] remove direct loading condition and use ViewModel.isLoading instead
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ..._getFilteredProjects().isEmpty
                        ? [
                            const Center(
                                child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text("No projects found."),
                            ))
                          ]
                        : _getFilteredProjects()
                            .map((project) {
                            // Calculate placeholder progress/spent since schema might not have it yet
                            double progress = 0.0;
                            // Ensure budget is parsed safely
                            String budget = project['budget'] != null
                                ? "₱${project['budget']}"
                                : "₱0";
                  _buildFinancialCard(),
                  const SizedBox(height: 20),
                  _sectionHeader("Ongoing Projects", ""),
                  const SizedBox(height: 12),
                  // Dynamic data fetching with search and tab filtering
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ..._getFilteredProjects().isEmpty
                        ? [
                            const Center(
                                child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text("No projects found."),
                            ))
                          ]
                        : _getFilteredProjects()
                            .map((project) {
                            // Calculate placeholder progress/spent since schema might not have it yet
                            double progress = 0.0;
                            // Ensure budget is parsed safely
                            String budget = project['budget'] != null
                                ? "₱${project['budget']}"
                                : "₱0";

                            return _projectCard(
                              tag: project['status'] ?? "Active",
                              title: project['name'] ?? "Untitled Project",
                              progress: progress,
                              spent: "₱0",
                              limit: budget,
                              color: const Color(0xFF137FEC),
                              onTap: () {
                                // Navigate to project details
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Navigating to ${project['name']} details..."),
                                  ),
                                );
                                // TODO: Replace with actual project details navigation
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (_) => ProjectDetailsScreen(
                                //       project: project,
                                //       organization: widget.organization,
                                //     ),
                                //   ),
                                // );
                              },
                            );
                          }).toList(),
                  const SizedBox(height: 20),
                  _sectionHeader("Completed", ""),
                  const SizedBox(height: 12),
                  ..._completedProjects.isEmpty
                      ? [
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text("No completed projects yet."),
                            ),
                          )
                        ]
                      : _completedProjects.map((project) {
                          final budget = project['budget'] != null
                              ? "₱${project['budget']}"
                              : "₱0";
                          return _completedCard(
                            title: project['name'] ?? "Project",
                            amount: budget,
                            completedDate:
                                project['due_date'] ?? "Recently completed",
                          );
                        }).toList(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// HEADER
  Widget _header() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
          color: const Color(0xFFF6F7F8).withOpacity(.92),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Projects",
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    onPressed:(){},
                    icon: const Icon(Icons.add_circle_outline)
                  )
                  IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Create new project functionality coming soon..."),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline))
                ],
              ),

              const SizedBox(height: 8),

              TextField(
                // TODO: Implement search functionality
                // TODO: [MVVM] bind search input to ViewModel.searchQuery
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                    hintText: "Search projects, teams, or tasks…",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFE5E7EB),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none)),
              ),

              const SizedBox(height: 10),
              // Tab filters for project categories
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(tabs.length, (i) {
                    final active = selectedTab == i;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tabs[i]),
                        selected: active,
                        onSelected: (_) {
                          setState(() {
                            selectedTab = i;
                          });
                        },
                        selectedColor: const Color(0xFF137FEC),
                        labelStyle: TextStyle(
                            color: active ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// FINANCE CARD
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
              const Icon(Icons.visibility_outlined,
                  color: Colors.white, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          // Displays actual balance data fetched from _fetchBalance()
          Text(
            _formatCurrency(_balance),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FinancialLedgerScreen(
                    organization: widget.organization,
                  ),
                ),
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

  /// SECTION HEADER
  Widget _sectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        Text(
          action,
          style: const TextStyle(
              color: Color(0xFF137FEC), fontWeight: FontWeight.w600),
        )
      ],
    );
  }

  /// PROJECT CARD
  Widget _projectCard(
      {required String tag,
      required String title,
      required double progress,
      required String spent,
      required String limit,
      required Color color,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3F4F6)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1))
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(tag),
                  backgroundColor: color.withOpacity(.1),
                ),
                const Icon(Icons.chevron_right)
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Completion"),
                Text("${(progress * 100).toInt()}%")
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              color: color,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Budget Spent"),
                Text("$spent / $limit",
                    style: const TextStyle(fontWeight: FontWeight.bold))
              ],
            )
          ],
        ),
      ),
    );
  }

  /// COMPLETED CARD
  Widget _completedCard({
    required String title,
    required String amount,
    String completedDate = "Recently completed",
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6))),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Finished $completedDate",
                    style: const TextStyle(color: Colors.grey, fontSize: 12))
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.bold),
          )
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
}
