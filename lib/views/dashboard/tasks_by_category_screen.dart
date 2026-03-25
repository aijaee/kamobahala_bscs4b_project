import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../projects/task_details.dart';

class TasksByCategoryScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> tasks;
  final Color categoryColor;

  const TasksByCategoryScreen({
    super.key,
    required this.title,
    required this.tasks,
    required this.categoryColor,
  });

  @override
  State<TasksByCategoryScreen> createState() => _TasksByCategoryScreenState();
}

class _TasksByCategoryScreenState extends State<TasksByCategoryScreen> {
  late List<Map<String, dynamic>> _filteredTasks;
  String _sortBy = 'due_date'; // 'due_date' or 'priority'

  @override
  void initState() {
    super.initState();
    _filteredTasks = List.from(widget.tasks);
    _sortTasks();
  }

  void _sortTasks() {
    if (_sortBy == 'due_date') {
      _filteredTasks.sort((a, b) {
        final aDate = a['due_date'] != null ? DateTime.tryParse(a['due_date']) : null;
        final bDate = b['due_date'] != null ? DateTime.tryParse(b['due_date']) : null;
        
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
    } else if (_sortBy == 'priority') {
      final priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
      _filteredTasks.sort((a, b) {
        final aPriority = priorityOrder[a['priority'] ?? 'Low'] ?? 2;
        final bPriority = priorityOrder[b['priority'] ?? 'Low'] ?? 2;
        return aPriority.compareTo(bPriority);
      });
    }
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
      final now = DateTime.now();
      final difference = date.difference(now).inDays;
      
      if (difference < 0) return 'Overdue';
      if (difference == 0) return 'Today';
      if (difference == 1) return 'Tomorrow';
      
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
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
          widget.title,
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _filteredTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks in this category',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Sorting controls
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredTasks.length} task${_filteredTasks.length != 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      PopupMenuButton<String>(
                        initialValue: _sortBy,
                        onSelected: (value) {
                          setState(() {
                            _sortBy = value;
                            _sortTasks();
                          });
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'due_date',
                            child: Row(
                              children: [
                                Icon(
                                  _sortBy == 'due_date' ? Icons.check : Icons.schedule,
                                  size: 18,
                                  color: const Color(0xFF137FEC),
                                ),
                                const SizedBox(width: 8),
                                const Text('Due Date'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'priority',
                            child: Row(
                              children: [
                                Icon(
                                  _sortBy == 'priority' ? Icons.check : Icons.priority_high,
                                  size: 18,
                                  color: const Color(0xFF137FEC),
                                ),
                                const SizedBox(width: 8),
                                const Text('Priority'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Tasks list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
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
                          ).then((result) {
                            if (result == true) {
                              // Pop back to dashboard to refresh
                              Navigator.pop(context, true);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF3F4F6)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Task title and priority badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task['title'] ?? 'Untitled Task',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: priorityColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                priority,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: priorityColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: widget.categoryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: widget.categoryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Project and due date
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.folder_outlined,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            task['projectName'] ?? 'Unknown Project',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
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
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDate(task['due_date']),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
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
                  ),
                ),
              ],
            ),
    );
  }
}
