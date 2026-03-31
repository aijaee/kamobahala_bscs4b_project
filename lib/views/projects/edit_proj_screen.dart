import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kamobahala_bscs4b_project/viewmodels/financial_viewmodel.dart';
import 'projects_list.dart';
import '../../viewmodels/projects_viewmodel.dart';

// ── Brand constants (shared with CreateOrganizationScreen) ───────────────────
const kPrimary = Color(0xFF1A73E8);
const kPrimaryDark = Color(0xFF0B539B);
const kSurface = Color(0xFFF5F7FA);
const kCardBg = Color(0xFFFFFFFF);
const kBorder = Color(0xFFDDE1E7);
const kTextPrimary = Color(0xFF1A1D23);
const kTextSecondary = Color(0xFF6B7280);
const kRed = Color(0xFFE53935);

class EditProjectScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> organization;
  const EditProjectScreen(
      {super.key, required this.projectId, required this.organization});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    // Load project data from ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsViewModel>().fetchProject(widget.projectId);
      context
          .read<FinancialViewModel>()
          .fetchTransactions(widget.organization['id']);
    });
  }

  void _initializeForm(Map<String, dynamic> project) {
    nameController.text = project['name']?.toString() ?? '';
    descriptionController.text = project['description']?.toString() ?? '';
    budgetController.text = project['budget']?.toString() ?? '';

    startDate = project['start_date'] is String
        ? DateTime.tryParse(project['start_date'])
        : project['start_date'] as DateTime?;
    endDate = project['due_date'] is String
        ? DateTime.tryParse(project['due_date'])
        : project['due_date'] as DateTime?;
  }

  // ── Shared input decoration ─────────────────────────────────────────────────
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: kTextSecondary),
      filled: true,
      fillColor: kCardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kRed, width: 1.5),
      ),
    );
  }

  // ── Section label ────────────────────────────────────────────────────────────
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: kTextPrimary,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  // ── Date picker helper ───────────────────────────────────────────────────────
  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (startDate ?? now) : (endDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              surface: kCardBg,
              onSurface: kTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Select...";
    return "${_monthAbbr(date.month)} ${date.day}, ${date.year}";
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _monthAbbr(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  /// Get the true available balance from the FinancialViewModel.
  /// This is the single source of truth for all balance calculations.
  double _getAvailableBalance() {
    final financialViewModel =
        Provider.of<FinancialViewModel>(context, listen: false);
    final openingBudget = _toDouble(widget.organization['budget']);
    return financialViewModel.calculateAvailableBalance(openingBudget);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kCardBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: kRed),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => ProjectsList(
                    initialIndex: 1, organization: widget.organization)),
          ),
        ),
        title: Text(
          "Edit Project",
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: kBorder),
        ),
      ),
      body: Consumer<ProjectsViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading && viewModel.currentProject == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.currentProject != null && nameController.text.isEmpty) {
            _initializeForm(viewModel.currentProject!);
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Project Name"),
                    TextFormField(
                      controller: nameController,
                      style:
                          GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
                      decoration:
                          _inputDecoration("e.g. Q4 Marketing Campaign"),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "Project name is required";
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    _label("Description"),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      style:
                          GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
                      decoration: _inputDecoration(
                          "Outline project goals and deliverables..."),
                    ),
                    const SizedBox(height: 18),
                    _buildTimelineCard(),
                    const SizedBox(height: 14),
                    _buildBudgetCard(viewModel.currentProject),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: viewModel.isLoading
                            ? null
                            : () => _handleSaveProject(context, viewModel),
                        child: Text(
                          viewModel.isLoading ? "Saving..." : "Save Changes",
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: viewModel.isLoading
                            ? null
                            : () => _handleDeleteProject(viewModel),
                        child: Text(
                          viewModel.isLoading
                              ? "Deleting..."
                              : "Delete Project",
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSaveProject(
      BuildContext context, ProjectsViewModel viewModel) async {
    // Reset validation error at the start
    setState(() {
      _validationError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    // Calculate the maximum allowable budget using the unified balance from FinancialViewModel
    final globalAvailableBalance = _getAvailableBalance();
    final existingProjectBudget =
        (viewModel.currentProject?['budget'] as num).toDouble();
    final maxAllowableBudget = globalAvailableBalance + existingProjectBudget;
    final newBudget = _toDouble(budgetController.text);

    // Validate: prevent save if new budget exceeds available funds
    if (newBudget > maxAllowableBudget) {
      setState(() {
        _validationError =
            'Insufficient Funds! Available in Depository: ₱${globalAvailableBalance.toStringAsFixed(2)}';
      });
      return;
    }

    final updates = {
      'name': nameController.text,
      'description': descriptionController.text,
      'budget': newBudget,
      'start_date': startDate?.toIso8601String(),
      'due_date': endDate?.toIso8601String(),
    };

    final success = await viewModel.updateProject(widget.projectId, updates);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project updated successfully')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => ProjectsList(
                initialIndex: 1, organization: widget.organization)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(viewModel.errorMessage ?? 'Failed to update project')),
      );
    }
  }

  Future<void> _handleDeleteProject(ProjectsViewModel viewModel) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: kCardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Delete Project?',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary)),
          content: Text(
              'Are you sure you want to delete this project? This action cannot be undone.',
              style: GoogleFonts.inter(fontSize: 14, color: kTextSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kPrimary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final success = await viewModel.deleteProject(widget.projectId);
                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Project deleted successfully')));
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProjectsList(
                              initialIndex: 1,
                              organization: widget.organization)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(viewModel.errorMessage ??
                          'Failed to delete project')));
                }
              },
              child: Text('Delete',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder)),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Project Timeline",
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _buildDateField(label: "START DATE", isStart: true)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildDateField(label: "END DATE", isStart: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({required String label, required bool isStart}) {
    final date = isStart ? startDate : endDate;
    final isPlaceholder = date == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
                letterSpacing: 0.8)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pickDate(isStart: isStart),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder)),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 15, color: isPlaceholder ? kTextSecondary : kPrimary),
                const SizedBox(width: 6),
                Text(_formatDate(date),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isPlaceholder ? kTextSecondary : kTextPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(Map<String, dynamic>? project) {
    return Container(
      decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder)),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, size: 18, color: kPrimary),
              const SizedBox(width: 8),
              Text("Budget Allocation",
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text("LINKED TO DEPOSITORY",
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                        letterSpacing: 0.4)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("₱",
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: kTextPrimary)),
                const SizedBox(width: 6),
                Expanded(
                  child: TextFormField(
                    controller: budgetController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: kTextPrimary),
                    decoration: InputDecoration(
                      hintText: "0.00",
                      hintStyle: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: kTextSecondary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
              "${widget.organization['name'] ?? 'Organization'} Depository Balance",
              style: GoogleFonts.inter(fontSize: 12, color: kTextSecondary)),
          const SizedBox(height: 4),
          Consumer<FinancialViewModel>(
            builder: (context, financialViewModel, _) {
              // Display the actual organization depository balance (not inflated by project budget)
              final globalAvailableBalance = _getAvailableBalance();
              return Text(
                "Available to Allocate: ₱${globalAvailableBalance.toStringAsFixed(2)}",
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary),
              );
            },
          ),
          const SizedBox(height: 10),
          if (_validationError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _validationError!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kRed,
                ),
              ),
            ),
          Divider(color: kBorder, height: 1),
          const SizedBox(height: 10),
          Text(
              "Changing the budget will create a new transaction in the financial depository.",
              style: GoogleFonts.inter(fontSize: 11, color: kTextSecondary)),
        ],
      ),
    );
  }
}
