import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kamobahala_bscs4b_project/viewmodels/tasks_viewmodel.dart';
import 'package:kamobahala_bscs4b_project/core/services/organization_service.dart';
import 'package:kamobahala_bscs4b_project/core/services/project_service.dart';
import 'package:kamobahala_bscs4b_project/core/services/task_service.dart';

class NewTaskScreen extends StatefulWidget {
  final String projectId;
  final String organizationId;

  const NewTaskScreen({
    super.key,
    required this.projectId,
    required this.organizationId,
  });

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  bool _financialDetailsEnabled = true;
  bool _deductFromBudget = false;
  String _selectedPriority = "Low";

  // Form controllers
  late TextEditingController _taskNameController;
  late TextEditingController _estimatedExpenseController;
  late TextEditingController _noteController;

  // Selected values
  String? _selectedCategory;
  String? _selectedAssignee;
  String? _selectedAssigneeFullName;
  String? _selectedExpenseCategory;
  DateTime? _selectedDueDate;
  List<String> _categories = [];
  List<String> _teamMemberEmails = [];
  bool _isLoadingData = true;
  String? _loadError;

  // Budget-related state
  double _projectBudget = 0.0;
  double _trueProjectCeiling =
      0.0; // Static ceiling - does not change based on user input
  bool _isLoadingBudget = true;

  @override
  void initState() {
    super.initState();
    _taskNameController = TextEditingController();
    _estimatedExpenseController = TextEditingController();
    _noteController = TextEditingController();

    _loadTeamData();
    _loadProjectFinancials();
  }

  Future<void> _loadProjectFinancials() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBudget = true;
    });

    try {
      final projectService = ProjectService();
      final project = await projectService.fetchProject(widget.projectId);
      final allocatedBudget = project.budget ?? 0.0;

      final taskService = TaskService();
      final projectTasks =
          await taskService.fetchProjectTasks(widget.projectId);
      final existingTasksExpenses = projectTasks
          .where((task) =>
              task.deductFromBudget == true && (task.estimatedExpense ?? 0) > 0)
          .fold<double>(0.0, (sum, task) => sum + (task.estimatedExpense ?? 0));

      if (mounted) {
        setState(() {
          _projectBudget = allocatedBudget;
          _trueProjectCeiling = (allocatedBudget - existingTasksExpenses)
              .clamp(0.0, allocatedBudget);
          _isLoadingBudget = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBudget = false;
          _trueProjectCeiling = 0;
        });
      }
    }
  }

  Future<void> _loadTeamData() async {
    try {
      final orgService = OrganizationService();
      final response =
          await orgService.getOrganizationMembers(widget.organizationId);
      final categories =
          await orgService.getTaskCategories(widget.organizationId);

      setState(() {
        _teamMemberEmails = response.map((m) => m.email).toList();
        _categories = categories.map((c) => c['name'] as String).toList();

        // Provide default categories if none exist
        if (_categories.isEmpty) {
          _categories = [
            'Development',
            'Design',
            'Marketing',
            'Documentation',
            'Testing',
          ];
        }

        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
          _selectedExpenseCategory = _categories.first;
        }
        if (_teamMemberEmails.isNotEmpty) {
          _selectedAssignee = _teamMemberEmails.first;
          _selectedAssigneeFullName = _selectedAssignee;
        }
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Failed to load team data: ${e.toString()}';
        _isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _estimatedExpenseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (_taskNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task name')),
      );
      return;
    }

    // CALCULATE THE "TRUE FIXED CEILING" (Pre-Input)
    // Formula: fixedProjectCeiling = (Project_Total_Budget) - (Sum of ALL existing tasks)
    // CRITICAL: Do NOT include the value from _estimatedExpenseController.text
    final double fixedProjectCeiling =
        (_trueProjectCeiling as num? ?? 0).toDouble();

    // Get the user's input amount with proper type conversion
    double userInput = double.tryParse(_estimatedExpenseController.text) ?? 0.0;

    // Check 1: Block save if project budget is exceeded
    if (_deductFromBudget && userInput > fixedProjectCeiling) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'INSUFFICIENT PROJECT BUDGET: You only have ₱${fixedProjectCeiling.toStringAsFixed(2)} left.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return; // THIS KILLS THE FUNCTION. DO NOT PROCEED TO SAVE.
    }

    final taskData = <String, dynamic>{
      'title': _taskNameController.text,
      'category': _selectedCategory ?? 'Uncategorized',
      'priority': _selectedPriority,
      'assignee': _selectedAssignee,
      'due_date': _selectedDueDate?.toIso8601String(),
      'description': _noteController.text,
      'status': 'todo',
      'organization_id': widget.organizationId,
      'project_id': widget.projectId,
    };

    if (_financialDetailsEnabled) {
      taskData['estimated_expense'] =
          double.tryParse(_estimatedExpenseController.text) ?? 0.0;
      taskData['expense_category'] =
          _selectedExpenseCategory ?? 'Uncategorized';
      taskData['deduct_from_budget'] = _deductFromBudget;
    }

    if (!mounted) return;

    final viewModel = Provider.of<TasksViewModel>(context, listen: false);

    // Make sure ViewModel has the right project context
    if (viewModel.currentProjectId != widget.projectId) {
      await viewModel.fetchProjectTasks(widget.projectId);
    }

    final success = await viewModel.createTask(taskData);

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(viewModel.errorMessage ?? 'Failed to create task')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7F8),
        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7F8),
        appBar: _buildAppBar(context),
        body: Center(child: Text(_loadError!)),
      );
    }

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
            child: Consumer<TasksViewModel>(
              builder: (context, viewModel, child) {
                return GestureDetector(
                  onTap: viewModel.isLoading ? null : _saveTask,
                  child: Text(
                    viewModel.isLoading ? "Saving..." : "Done",
                    style: GoogleFonts.inter(
                      color: viewModel.isLoading
                          ? Colors.grey
                          : const Color(0xFF137FEC),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
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
                activeThumbColor: const Color(0xFF137FEC),
                onChanged: (val) {
                  setState(() => _financialDetailsEnabled = val);
                },
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
          _buildTextField("Task Name", controller: _taskNameController),
          const Divider(height: 1, indent: 16),
          GestureDetector(
            onTap: _showCategoryPicker,
            child: _buildListTile(
              "Category",
              _selectedCategory ?? "Select Category",
              true,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryPicker() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._categories.map((cat) => ListTile(
                    title: Text(cat),
                    onTap: () => Navigator.pop(context, cat),
                  )),
              ListTile(
                title: const Text('+ New Category'),
                onTap: () => _showNewCategoryDialog(),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      setState(() => _selectedCategory = selected);
    }
  }

  Future<void> _showNewCategoryDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final orgService = OrganizationService();
      await orgService.createTaskCategory(widget.organizationId, result);

      setState(() {
        if (!_categories.contains(result)) {
          _categories.add(result);
        }
        _selectedCategory = result;
      });
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showExpenseCategoryPicker() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Expense Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._categories.map((cat) => ListTile(
                    title: Text(cat),
                    onTap: () => Navigator.pop(context, cat),
                  )),
              ListTile(
                title: const Text('+ New Category'),
                onTap: () => _showNewExpenseCategoryDialog(),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      setState(() => _selectedExpenseCategory = selected);
    }
  }

  Future<void> _showNewExpenseCategoryDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Expense Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final orgService = OrganizationService();
      await orgService.createTaskCategory(widget.organizationId, result);

      setState(() {
        if (!_categories.contains(result)) {
          _categories.add(result);
        }
        _selectedExpenseCategory = result;
      });
      if (mounted) Navigator.pop(context);
    }
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
              children: ["Low", "Medium", "High"]
                  .map((p) => Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPriority = p),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedPriority == p
                                  ? _getPriorityColor(p).withValues(alpha: 0.2)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                              border: _selectedPriority == p
                                  ? Border.all(
                                      color: _getPriorityColor(p), width: 2)
                                  : null,
                              boxShadow: _selectedPriority == p
                                  ? [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 4)
                                    ]
                                  : null,
                            ),
                            child: Text(
                              p,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: _selectedPriority == p
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _selectedPriority == p
                                    ? _getPriorityColor(p)
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          GestureDetector(
            onTap: _showAssigneePicker,
            child: _buildListTile(
              "Assignee",
              _selectedAssigneeFullName ??
                  _selectedAssignee ??
                  "Select Assignee",
              true,
            ),
          ),
          const Divider(height: 1, indent: 16),
          GestureDetector(
            onTap: _showDatePicker,
            child: _buildListTile(
              "Due Date",
              _selectedDueDate != null
                  ? "${_selectedDueDate!.month.toString().padLeft(2, '0')}/${_selectedDueDate!.day.toString().padLeft(2, '0')}/${_selectedDueDate!.year}"
                  : "Select Date",
              false,
              icon: Icons.calendar_today_outlined,
              iconColor: Colors.redAccent,
              valueColor: const Color(0xFF137FEC),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssigneePicker() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Assignee'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _teamMemberEmails
                .map((email) => ListTile(
                      title: Text(email),
                      subtitle: Text(email),
                      onTap: () => Navigator.pop(context, email),
                    ))
                .toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedAssignee = selected;
        _selectedAssigneeFullName = selected;
      });
    }
  }

  /// Get the color for a priority level
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444); // Red
      case 'medium':
        return const Color(0xFFF59E0B); // Orange
      case 'low':
        return const Color(0xFF10B981); // Green
      default:
        return const Color(0xFF6B7280);
    }
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                    _deductFromBudget
                        ? "Estimated Expense"
                        : "Estimated Income",
                    style: GoogleFonts.inter(fontSize: 15)),
                const Spacer(),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _estimatedExpenseController,
                    textAlign: TextAlign.right,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: "0.00",
                      hintStyle:
                          GoogleFonts.inter(color: const Color(0xFFD1D5DB)),
                      prefix: Text("₱ ",
                          style: GoogleFonts.inter(
                              fontSize: 15, color: Colors.black)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16),
          GestureDetector(
            onTap: _showExpenseCategoryPicker,
            child: _buildListTile(
                "Category", _selectedExpenseCategory ?? "Uncategorized", true,
                valueColor: const Color(0xFF137FEC)),
          ),
          const Divider(height: 1, indent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _deductFromBudget = true),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _deductFromBudget
                            ? const Color(0xFFEF4444).withOpacity(0.2)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: _deductFromBudget
                            ? Border.all(
                                color: const Color(0xFFEF4444), width: 2)
                            : null,
                        boxShadow: _deductFromBudget
                            ? [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4)
                              ]
                            : null,
                      ),
                      child: Text(
                        "Deduct from Budget",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: _deductFromBudget
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _deductFromBudget
                              ? const Color(0xFFEF4444)
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _deductFromBudget = false),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_deductFromBudget
                            ? const Color(0xFF10B981).withOpacity(0.2)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: !_deductFromBudget
                            ? Border.all(
                                color: const Color(0xFF10B981), width: 2)
                            : null,
                        boxShadow: !_deductFromBudget
                            ? [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4)
                              ]
                            : null,
                      ),
                      child: Text(
                        "Add to Budget",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: !_deductFromBudget
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: !_deductFromBudget
                              ? const Color(0xFF10B981)
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              _deductFromBudget
                  ? "The estimated expense will be subtracted from the project budget."
                  : "The income will be added to the project budget. Changes are recorded when the project is marked complete.",
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF9CA3AF), height: 1.4),
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
        controller: _noteController,
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
    // Display the project budget for task validation context
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
                  _isLoadingBudget
                      ? "Project Budget: Loading..."
                      : "Project Budget: ₱${_projectBudget.toStringAsFixed(2)} (₱${_trueProjectCeiling.toStringAsFixed(2)} remaining)",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF137FEC),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Task expense validation is based on remaining project budget only.",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF137FEC).withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Budget changes recorded when project is marked complete.",
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

  Widget _buildTextField(String label,
      {TextEditingController? controller,
      String? trailing,
      bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 15)),
          const Spacer(),
          if (trailing != null)
            Text(trailing,
                style: GoogleFonts.inter(
                    fontSize: 15, color: const Color(0xFF137FEC))),
          if (trailing == null && controller != null)
            SizedBox(
              width: 150,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.right,
                keyboardType: isNumeric
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
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
