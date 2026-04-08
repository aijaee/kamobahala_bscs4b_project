import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../projects/task_details.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> transactions;

  const SearchResultsScreen({
    super.key,
    required this.query,
    required this.tasks,
    required this.projects,
    required this.transactions,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late List<Map<String, dynamic>> _filteredTasks;
  late List<Map<String, dynamic>> _filteredProjects;
  late List<Map<String, dynamic>> _filteredTransactions;

  @override
  void initState() {
    super.initState();
    _filterResults();
  }

  void _filterResults() {
    final queryLower = widget.query.toLowerCase();

    _filteredTasks = widget.tasks
        .where((task) =>
            (task['title'] ?? '').toString().toLowerCase().contains(queryLower) ||
            (task['description'] ?? '').toString().toLowerCase().contains(queryLower) ||
            (task['projectName'] ?? '').toString().toLowerCase().contains(queryLower))
        .toList();

    _filteredProjects = widget.projects
        .where((project) =>
            (project['name'] ?? '').toString().toLowerCase().contains(queryLower) ||
            (project['description'] ?? '').toString().toLowerCase().contains(queryLower))
        .toList();

    _filteredTransactions = widget.transactions
        .where((transaction) =>
            (transaction['title'] ?? '').toString().toLowerCase().contains(queryLower) ||
            (transaction['category'] ?? '').toString().toLowerCase().contains(queryLower) ||
            (transaction['department'] ?? '').toString().toLowerCase().contains(queryLower))
        .toList();
  }

  Color _getPriorityColor(String? priority) {
    switch ((priority ?? 'Low').toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF97316);
      case 'low':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No date';
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatCurrency(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final totalResults = _filteredTasks.length + _filteredProjects.length + _filteredTransactions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'Search Results',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: totalResults == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No results found for "${widget.query}"',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Tasks section
                if (_filteredTasks.isNotEmpty)
                  _buildSection(
                    'Tasks',
                    _filteredTasks.length,
                    _buildTasksList(),
                  ),

                // Projects section
                if (_filteredProjects.isNotEmpty)
                  _buildSection(
                    'Projects',
                    _filteredProjects.length,
                    _buildProjectsList(),
                  ),

                // Transactions section
                if (_filteredTransactions.isNotEmpty)
                  _buildSection(
                    'Financial Transactions',
                    _filteredTransactions.length,
                    _buildTransactionsList(),
                  ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, int count, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            '$title ($count)',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        content,
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTasksList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        final priority = task['priority'] ?? 'Low';
        final priorityColor = _getPriorityColor(priority);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TaskDetailsScreen(task: task),
              ),
            ).then((_) {
              // Pop back to previous screen after task update
              Navigator.pop(context, true);
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
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
                    Expanded(
                      child: Text(
                        task['title'] ?? 'Untitled Task',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priority,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.folder_outlined, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              task['projectName'] ?? 'Unknown Project',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(task['due_date']),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredProjects.length,
      itemBuilder: (context, index) {
        final project = _filteredProjects[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
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
                  Icon(Icons.assignment_outlined, size: 20, color: const Color(0xFF137FEC)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project['name'] ?? 'Untitled Project',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if ((project['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project['description'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        final isIncome = (transaction['transaction_type'] ?? 'expense').toString().toLowerCase() == 'income';
        final amount = (transaction['amount'] ?? 0.0) as num;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      transaction['title'] ?? 'Transaction',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amount == 0
                        ? _formatCurrency(amount.toDouble())
                        : '${isIncome ? '+' : '-'}${_formatCurrency(amount.toDouble())}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${transaction['category'] ?? 'Uncategorized'} • ${transaction['department'] ?? 'Unknown'}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
