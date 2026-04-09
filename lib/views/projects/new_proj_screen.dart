import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/projects_viewmodel.dart';
import '../../viewmodels/financial_viewmodel.dart';

// ── Brand constants (shared with CreateOrganizationScreen) ───────────────────
const kPrimary = Color(0xFF1A73E8);
const kPrimaryDark = Color(0xFF0B539B);
const kSurface = Color(0xFFF5F7FA);
const kCardBg = Color(0xFFFFFFFF);
const kBorder = Color(0xFFDDE1E7);
const kTextPrimary = Color(0xFF1A1D23);
const kTextSecondary = Color(0xFF6B7280);
const kRed = Color(0xFFE53935);

class CreateProjectScreen extends StatefulWidget {
  final Map<String, dynamic> organization;
  const CreateProjectScreen({super.key, required this.organization});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<FinancialViewModel>()
          .fetchTransactions(widget.organization['id'].toString());
    });
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

  /// Get the true available balance from the FinancialViewModel.
  /// This is the single source of truth for depository calculations.
  double _getAvailableBalance() {
    final financialViewModel =
        Provider.of<FinancialViewModel>(context, listen: false);
    final openingBudget = _toDouble(widget.organization['budget']);
    return financialViewModel.calculateAvailableBalance(openingBudget);
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _monthAbbr(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: kCardBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: kRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "New Project",
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
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Project Name ─────────────────────────────────────────────
                    _label("Project Name"),
                    TextFormField(
                      controller: nameController,
                      style: GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
                      decoration: _inputDecoration("e.g. Q4 Marketing Campaign"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Project name is required";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // ── Description ──────────────────────────────────────────────
                    _label("Description"),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      style: GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
                      decoration: _inputDecoration("Outline project goals and deliverables..."),
                    ),

                    const SizedBox(height: 18),

                    // ── Project Timeline ─────────────────────────────────────────
                    _buildTimelineCard(),

                    const SizedBox(height: 14),

                    // ── Budget Allocation ────────────────────────────────────────
                    _buildBudgetCard(),

                    const SizedBox(height: 32),

                    // ── Create Project Button ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: viewModel.isLoading
                            ? null
                            : () => _handleCreateProject(context, viewModel),
                        child: Text(
                          viewModel.isLoading ? "Creating..." : "Create Project",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
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

  Future<void> _handleCreateProject(BuildContext context, ProjectsViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final financialViewModel = context.read<FinancialViewModel>();
    final targetOrganizationId = widget.organization['id']?.toString();
    if (targetOrganizationId != null &&
        financialViewModel.currentOrganizationId != targetOrganizationId) {
      await financialViewModel.fetchTransactions(targetOrganizationId);
    }

    final inputBudget = _toDouble(budgetController.text);
    final availableBalance = _getAvailableBalance();

    if (inputBudget > availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('INSUFFICIENT DEPOSITORY BALANCE: Available in depository is only ₱${availableBalance.toStringAsFixed(2)}.'),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    final projectData = {
      'name': nameController.text,
      'description': descriptionController.text,
      'budget': inputBudget,
      'start_date': startDate?.toIso8601String(),
      'due_date': endDate?.toIso8601String(),
      'status': 'active',
    };

    // Set the organization for the viewModel if not already set
    if (viewModel.currentOrganizationId == null ||
        viewModel.currentOrganizationId != widget.organization['id'].toString()) {
      viewModel.fetchProjects(widget.organization['id'].toString());
    }

    final success = await viewModel.createProject(projectData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project created successfully')),
      );
      Navigator.pop(context, true); // Pop with success flag to trigger refresh
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Failed to create project')),
      );
    }
  }

  // ── Project Timeline Card ────────────────────────────────────────────────────
  Widget _buildTimelineCard() {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Project Timeline",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Start Date
              Expanded(child: _buildDateField(label: "START DATE", isStart: true)),
              const SizedBox(width: 12),
              // End Date
              Expanded(child: _buildDateField(label: "END DATE", isStart: false)),
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
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: kTextSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pickDate(isStart: isStart),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: isPlaceholder ? kTextSecondary : kPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(date),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isPlaceholder ? kTextSecondary : kTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Budget Allocation Card ───────────────────────────────────────────────────
  Widget _buildBudgetCard() {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.account_balance, size: 18, color: kPrimary),
              const SizedBox(width: 8),
              Text(
                "Budget Allocation",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "LINKED TO DEPOSITORY",
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Amount input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "₱",
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextFormField(
                    controller: budgetController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: kTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: "0.00",
                      hintStyle: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: kTextSecondary,
                      ),
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
          Divider(color: kBorder, height: 1),
          const SizedBox(height: 10),

          // Organization Depository Balance row
          Text(
            "${widget.organization['name'] ?? 'Organization'} Total Depository Balance",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Consumer<FinancialViewModel>(
            builder: (context, financialViewModel, _) {
              final balance = _getAvailableBalance();
              return Text(
                "₱${balance.toStringAsFixed(2)}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          Text(
            "Funds will be locked upon project creation.",
            style: GoogleFonts.inter(
              fontSize: 11,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}