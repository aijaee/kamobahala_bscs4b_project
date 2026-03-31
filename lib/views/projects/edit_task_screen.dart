import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kamobahala_bscs4b_project/viewmodels/tasks_viewmodel.dart';
import 'package:kamobahala_bscs4b_project/viewmodels/financial_viewmodel.dart';
import 'package:kamobahala_bscs4b_project/core/services/organization_service.dart';
import 'package:kamobahala_bscs4b_project/core/services/project_service.dart';
import 'package:kamobahala_bscs4b_project/core/services/task_service.dart';

class EditTaskScreen extends StatefulWidget {
  final String taskId;
  final String projectId;
  final String organizationId;
  final Map<String, dynamic> task;

  const EditTaskScreen({
    super.key,
    required this.taskId,
    required this.projectId,
    required this.organizationId,
    required this.task,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  bool _financialDetailsEnabled = true;
  bool _deductFromBudget = false;
  String _selectedPriority = "Low";
  late TextEditingController _taskNameController;
  late TextEditingController _estimatedExpenseController;
  late TextEditingController _noteController;
  String? _selectedCategory;
  String? _selectedAssignee;
  String? _selectedStatus = 'todo';
  String? _selectedExpenseCategory;
  DateTime? _selectedDueDate;
  List<String> _categories = [];
  List<Map<String, dynamic>> _teamMembers = [];
  String? _selectedAssigneeFullName;
  bool _isLoadingData = true;
  String? _loadError;

  // Budget-related state
  double _projectBudget = 0.0;
  double _trueProjectCeiling =
      0.0; // Static ceiling - does not change based on user input
  bool _isLoadingBudget = true;
  String? _errorMessage;
  double _originalTaskExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _taskNameController =
        TextEditingController(text: widget.task['title'] ?? '');
    _estimatedExpenseController = TextEditingController(
        text: (widget.task['estimated_expense'] ?? 0.0).toString());
    _noteController =
        TextEditingController(text: widget.task['description'] ?? '');

    _selectedPriority = widget.task['priority'] ?? 'Low';
    _selectedStatus = widget.task['status'] ?? 'todo';
    _deductFromBudget = widget.task['deduct_from_budget'] ?? false;
    _selectedCategory = widget.task['category'] ?? 'Uncategorized';
    _selectedAssignee = widget.task['assignee'];
    _selectedExpenseCategory =
        widget.task['expense_category'] ?? 'Transportation';
    _originalTaskExpense =
        (widget.task['estimated_expense'] as num? ?? 0).toDouble();

    if (_selectedAssignee != null) {
      _loadAssigneeFullName(_selectedAssignee!);
    }

    if (widget.task['due_date'] != null) {
      _selectedDueDate = DateTime.tryParse(widget.task['due_date'].toString());
    }

    _estimatedExpenseController.addListener(() {
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    });

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
      final allocatedBudget = (project['budget'] as num? ?? 0).toDouble();

      final taskService = TaskService();
      final projectTasks =
          await taskService.fetchProjectTasks(widget.projectId);

      double existingTasksExpenses = projectTasks.fold(0.0, (sum, task) {
        // Exclude the current task's old expense from the sum to avoid double-counting
        final taskId = task['task_id'] ?? task['id'];
        if (taskId == widget.taskId) {
          return sum;
        }
        if (task['deduct_from_budget'] == true) {
          final taskExpense = (task['estimated_expense'] as num?) ?? 0;
          return sum + taskExpense.toDouble();
        }
        return sum;
      });

      if (mounted) {
        setState(() {
          _projectBudget = allocatedBudget;
          _trueProjectCeiling = allocatedBudget - existingTasksExpenses;
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
        _teamMembers = response;
        _categories = categories.map((c) => c['name'] as String).toList();
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Failed to load team data: ${e.toString()}';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _loadAssigneeFullName(String email) async {
    try {
      final member = _teamMembers.firstWhere(
        (m) => m['email'] == email,
        orElse: () => {},
      );
      if (member.isNotEmpty && mounted) {
        setState(() {
          _selectedAssigneeFullName = member['name'];
        });
      }
    } catch (e) {
      print('Error loading assignee name: $e');
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
    // Clear previous error first
    setState(() {
      _errorMessage = null;
    });

    if (_taskNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task name')),
      );
      return;
    }

    // CALCULATE THE "TRUE FIXED CEILING" (Pre-Input)
    // Formula: fixedProjectCeiling = (Project_Total_Budget) - (Sum of OTHER tasks) + (This Task's Original Expense)
    // This allows budget reallocation without adding the current user input
    final double originalTaskExpense =
        (_originalTaskExpense as num? ?? 0).toDouble();
    final double fixedProjectCeiling =
        (_trueProjectCeiling as num? ?? 0).toDouble() + originalTaskExpense;

    // Get the user's input amount with proper type conversion
    double userInput = double.tryParse(_estimatedExpenseController.text) ?? 0.0;

    // THE "HARD STOP" GATEKEEPER: Block save if budget is exceeded
    if (_deductFromBudget && userInput > fixedProjectCeiling) {
      setState(() {
        _errorMessage =
            "INSUFFICIENT PROJECT BUDGET: You only have ₱${fixedProjectCeiling.toStringAsFixed(2)} left.";
      });
      return; // THIS KILLS THE FUNCTION. DO NOT PROCEED TO SAVE.
    }

    final taskData = <String, dynamic>{
      'title': _taskNameController.text,
      'category': _selectedCategory ?? 'Uncategorized',
      'priority': _selectedPriority,
      'assignee': _selectedAssignee,
      'due_date': _selectedDueDate?.toIso8601String(),
      'description': _noteController.text,
      'status': _selectedStatus,
    };

    if (_financialDetailsEnabled) {
      taskData['estimated_expense'] =
          double.tryParse(_estimatedExpenseController.text) ?? 0.0;
      taskData['expense_category'] =
          _selectedExpenseCategory ?? 'Transportation';
      taskData['deduct_from_budget'] = _deductFromBudget;
    }

    if (!mounted) return;

    final viewModel = Provider.of<TasksViewModel>(context, listen: false);
    final success = await viewModel.updateTask(widget.taskId, taskData);

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(viewModel.errorMessage ?? 'Failed to update task')),
      );
    }
  }

  Future<void> _handleDeleteTask(BuildContext context) async {
    final taskTitle = widget.task['title'] ?? 'Untitled Task';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text(
              'Are you sure you want to delete "$taskTitle"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final taskId = widget.task['task_id'] ?? widget.task['id'];

      if (taskId == null || taskId.isEmpty) throw Exception('Invalid task ID');
      final success = await Provider.of<TasksViewModel>(context, listen: false)
          .deleteTask(taskId);

      if (!success) throw Exception('Delete failed');
      if (mounted) {
        await Provider.of<TasksViewModel>(context, listen: false)
            .fetchProjectTasks(widget.projectId);
        await Provider.of<FinancialViewModel>(context, listen: false)
            .fetchTransactions(widget.organizationId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task "$taskTitle" deleted successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: $e')),
        );
      }
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
            _buildSectionHeader("STATUS"),
            _buildStatusCard(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            _buildSectionHeader("FINANCIAL DETAILS", hasSwitch: true),
            if (_financialDetailsEnabled) _buildFinancialDetailsCard(),
            const SizedBox(height: 12),
            _buildNoteCard(),
            const SizedBox(height: 24),
            if (_financialDetailsEnabled) _buildBudgetAlert(),
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
        "Edit Task",
        style: GoogleFonts.inter(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: GestureDetector(
              onTap: () => _handleDeleteTask(context),
              child: Text(
                "Delete",
                style: GoogleFonts.inter(
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: GestureDetector(
              onTap: _saveTask,
              child: Text(
                "Save",
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
                onChanged: (val) =>
                    setState(() => _financialDetailsEnabled = val),
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

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text("Status", style: GoogleFonts.inter(fontSize: 15)),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: 'todo', child: Text('To Do')),
                DropdownMenuItem(
                    value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedStatus = value);
                }
              },
            ),
          ],
        ),
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
      // Save to database
      final orgService = OrganizationService();
      await orgService.createTaskCategory(widget.organizationId, result);

      setState(() {
        if (!_categories.contains(result)) {
          _categories.add(result);
        }
        _selectedCategory = result;
      });
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
                                  ? Colors.white
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                              border: _selectedPriority == p
                                  ? Border.all(color: const Color(0xFFE5E7EB))
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
            children: _teamMembers
                .map((member) => ListTile(
                      title:
                          Text(member['name'] ?? member['email'] ?? 'Unknown'),
                      subtitle: Text(member['email'] ?? ''),
                      onTap: () => Navigator.pop(context, member['email']),
                    ))
                .toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      // Find the name of the selected member
      final member = _teamMembers.firstWhere(
        (m) => m['email'] == selected,
        orElse: () => {},
      );
      setState(() {
        _selectedAssignee = selected;
        _selectedAssigneeFullName = member.isNotEmpty ? member['name'] : null;
      });
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
      // Save to database
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

  Widget _buildFinancialDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTextField("Estimated Expense",
              controller: _estimatedExpenseController, isNumeric: true),
          const Divider(height: 1, indent: 16),
          GestureDetector(
            onTap: _showExpenseCategoryPicker,
            child: _buildListTile(
              "Category",
              _selectedExpenseCategory ?? "Transportation",
              true,
              valueColor: const Color(0xFF137FEC),
            ),
          ),
          const Divider(height: 1, indent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Deduct from Project Budget",
                    style: GoogleFonts.inter(fontSize: 15)),
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
    // For edit mode: show the static ceiling (original remaining + this task's current expense)
    final displayCeiling = _trueProjectCeiling + _originalTaskExpense;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF137FEC).withOpacity(0.1),
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
                      : "Project Budget: ₱${displayCeiling.toStringAsFixed(2)} remaining",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF137FEC),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "This task's estimated expense will be deducted from the budget.",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF137FEC).withOpacity(0.7),
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
                    ? TextInputType.numberWithOptions(decimal: true)
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
