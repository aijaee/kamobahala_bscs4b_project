import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/financial_viewmodel.dart';
import '../../core/services/admin_service.dart';
import '../../models/financial_transaction.dart';

class FinancialLedgerScreen extends StatefulWidget {
  final int initialIndex;
  final Map<String, dynamic> organization;
  final Function(int)? onTabChange;
  const FinancialLedgerScreen({
    super.key,
    this.initialIndex = 2,
    required this.organization,
    this.onTabChange,
  });

  @override
  State<FinancialLedgerScreen> createState() => _FinancialLedgerScreenState();
}

class _FinancialLedgerScreenState extends State<FinancialLedgerScreen> {
  late int currentIndex;
  late FinancialViewModel _viewModel;
  bool _isAdmin = false;
  final AdminService _adminService = AdminService();
  bool _balanceHidden = true;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    // Use the global FinancialViewModel from Provider
    _viewModel = context.read<FinancialViewModel>();
    _fetchTransactions();
    _checkAdminStatus();
    _viewModel.addListener(_onViewModelChanged);
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isUserAdmin(widget.organization['id']);
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Fetches transactions for the organization
  Future<void> _fetchTransactions() async {
    await _viewModel.fetchTransactions(widget.organization['id'].toString());
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = _viewModel.groupedTransactions;

    return Material(
      color: Colors.white,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchTransactions,
            color: const Color(0xFF137FEC),
            backgroundColor: Colors.white,
            child: ListView(
            padding: const EdgeInsets.only(bottom: 100, top: 50),
            children: [
              _buildBalanceCard(),
              _buildFilterTabs(),
              if (_viewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (groupedTransactions.isEmpty)
                _buildEmptyState()
              else
                ...groupedTransactions.expand(
                  (group) => _buildDateTransactionSection(group.$1, group.$2),
                ),
            ],
          ),
        ),
        _buildFloatingActionButton(),
      ],
    ),
    );
  }

  /// Builds the balance card using ViewModel balance
  Widget _buildBalanceCard() {
    final fallbackOpeningBudget = _toDouble(widget.organization['budget']);
    final currentBalance =
        _viewModel.calculateDepositoryCardBalance(fallbackOpeningBudget);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.organization['name'] ?? 'ORGANIZATION',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TOTAL DEPOSITORY BALANCE',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _balanceHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _balanceHidden = !_balanceHidden;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _balanceHidden
                ? "••••••••"
                : _formatCurrency(currentBalance),
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

  /// Builds filter tabs using ViewModel filters
  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(
          _viewModel.filters.length,
          (index) => GestureDetector(
            onTap: () {
              _viewModel.updateFilter(index);
            },
            child: _filterChip(
              _viewModel.filters[index],
              _viewModel.selectedFilterIndex == index,
            ),
          ),
        ),
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

  List<Widget> _buildDateTransactionSection(
    String dateHeader,
    List<FinancialTransaction> transactions,
  ) {
    final standaloneTransactions = <FinancialTransaction>[];
    final Map<String, List<FinancialTransaction>> projectTaskGroups = {};
    final Map<String, String> projectLabels = {};

    for (final transaction in transactions) {
      final isTaskTransaction =
          (transaction.taskId?.trim().isNotEmpty ?? false) ||
          transaction.title.toLowerCase().startsWith('task:');

      if (!isTaskTransaction) {
        standaloneTransactions.add(transaction);
        continue;
      }

      final projectKey = (transaction.projectId?.trim().isNotEmpty ?? false)
          ? transaction.projectId!.trim()
          : _extractProjectNameFromTransaction(transaction).toLowerCase();
      projectTaskGroups.putIfAbsent(projectKey, () => []).add(transaction);
      projectLabels.putIfAbsent(
        projectKey,
        () => _extractProjectNameFromTransaction(transaction),
      );
    }

    final section = <Widget>[_buildDateHeader(dateHeader)];
    section.addAll(standaloneTransactions.map(_buildTransactionRow));

    for (final entry in projectTaskGroups.entries) {
      final projectName = projectLabels[entry.key] ?? 'Project';
      section.add(_buildProjectGroupHeader(projectName));
      section.addAll(
        entry.value.map((transaction) => _buildTransactionRow(
              transaction,
              isProjectChild: true,
            )),
      );
    }

    return section;
  }

  Widget _buildProjectGroupHeader(String projectName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          const Icon(
            Icons.folder_open,
            size: 14,
            color: Color(0xFF617589),
          ),
          const SizedBox(width: 6),
          Text(
            'Project: $projectName',
            style: GoogleFonts.inter(
              color: const Color(0xFF617589),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _extractProjectNameFromTransaction(FinancialTransaction transaction) {
    final description = transaction.description ?? '';
    final match = RegExp(
      r'\(Project:\s*([^\)]+)\)',
      caseSensitive: false,
    ).firstMatch(description);
    if (match != null) {
      final projectName = match.group(1)?.trim();
      if (projectName != null && projectName.isNotEmpty) {
        return projectName;
      }
    }

    final title = transaction.title;
    if (title.startsWith('Budget Allocation:')) {
      return title.replaceFirst('Budget Allocation:', '').trim();
    }
    if (title.startsWith('Budget Adjustment:')) {
      return title.replaceFirst('Budget Adjustment:', '').trim();
    }

    return 'Project';
  }

  Widget _buildTransactionRow(
    FinancialTransaction transaction, {
    bool isProjectChild = false,
  }) {
    final amount = _viewModel.getSignedAmount(transaction);
    final occurredAt = transaction.occurredAt;
    final department =
        (transaction.department?.trim().isNotEmpty ?? false)
            ? transaction.department.toString()
            : 'General';
    final description =
        (transaction.description?.trim().isNotEmpty ?? false)
            ? transaction.description.toString()
            : (amount > 0 ? 'Incoming funds' : 'Expense recorded');
    final deptColor = _departmentColor(department);
    final title = transaction.title;

    // Check if this is a budget allocation
    final isBudgetAllocation = title.contains('Budget Allocation') ||
        title.contains('Budget Adjustment');
    bool isIncome = amount > 0 && !isBudgetAllocation;

    return Container(
      padding: EdgeInsets.fromLTRB(isProjectChild ? 40 : 16, 12, 16, 12),
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
              color: isBudgetAllocation
                  ? const Color(
                      0x1AF97316) // Orange background for budget allocations
                  : (isIncome
                      ? const Color(0x1A22C55E)
                      : const Color(0x1A137FEC)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isBudgetAllocation
                  ? Icons
                      .account_balance_wallet // Wallet icon for budget allocations
                  : (isIncome ? Icons.south_west : Icons.north_east),
              color: isBudgetAllocation
                  ? const Color(
                      0xFFF97316) // Orange color for budget allocations
                  : (isIncome
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF137FEC)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(description,
                    style: GoogleFonts.inter(
                        color: const Color(0xFF617589), fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: deptColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    department.toUpperCase(),
                    style: GoogleFonts.inter(
                        color: deptColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount == 0
                    ? _formatCurrency(amount.abs())
                    : '${amount > 0 ? '+' : '-'}${_formatCurrency(amount.abs())}',
                style: GoogleFonts.inter(
                  color: isBudgetAllocation
                      ? const Color(
                          0xFFF97316) // Orange color for budget allocations
                      : (isIncome
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFEF4444)),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(_formatTime(occurredAt),
                  style: GoogleFonts.inter(
                      color: const Color(0xFF617589), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return _isAdmin
        ? Positioned(
            right: 24,
            bottom: 24,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF137FEC),
              onPressed: _openCreateTransactionDialog,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111418),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first income or expense to start tracking the organization depository.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF617589),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => _TransactionFormDialog(
        organizationId: widget.organization['id'].toString(),
        viewModel: _viewModel,
        onTransactionCreated: _fetchTransactions,
        organization: widget.organization,
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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

    return '₱${buffer.toString()}.$decimals';
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Color _departmentColor(String department) {
    const palette = [
      Color(0xFF137FEC),
      Color(0xFF16A34A),
      Color(0xFFF97316),
      Color(0xFFA855F7),
      Color(0xFFEF4444),
    ];
    final hash = department.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return palette[hash % palette.length];
  }
}

class _TransactionFormDialog extends StatefulWidget {
  final String organizationId;
  final FinancialViewModel viewModel;
  final VoidCallback onTransactionCreated;
  final Map<String, dynamic> organization;

  const _TransactionFormDialog({
    required this.organizationId,
    required this.viewModel,
    required this.onTransactionCreated,
    required this.organization,
  });

  @override
  State<_TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<_TransactionFormDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _departmentController;
  late TextEditingController _amountController;

  String _transactionType = 'expense';
  DateTime _occurredAt = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _departmentController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _departmentController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Transaction',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('Title', _titleController, 'e.g. Venue rental'),
              const SizedBox(height: 12),
              _buildTextField('Description', _descriptionController,
                  'What is this payment for?'),
              const SizedBox(height: 12),
              _buildTextField(
                  'Department', _departmentController, 'e.g. Logistics'),
              const SizedBox(height: 12),
              _buildTextField(
                'Amount',
                _amountController,
                '0.00',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              Text('Type',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Expense'),
                      selected: _transactionType == 'expense',
                      onSelected: _isLoading
                          ? null
                          : (_) => setState(() => _transactionType = 'expense'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Income'),
                      selected: _transactionType == 'income',
                      onSelected: _isLoading
                          ? null
                          : (_) => setState(() => _transactionType = 'income'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(_formatDateTime(_occurredAt)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: _isLoading ? null : _pickDateTime,
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF137FEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !_isLoading,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF6F7F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );

    if (pickedTime == null) return;

    setState(() {
      _occurredAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveTransaction() async {
    setState(() => _errorMessage = null);
    final amount = double.tryParse(_amountController.text.trim());
    final title = _titleController.text.trim();

    if (title.isEmpty || amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Enter a title and valid amount > 0';
      });
      return;
    }

    final isExpense = _transactionType == 'expense';
    final isBudgetAllocation =
        title.toLowerCase().contains('budget allocation') ||
            title.toLowerCase().contains('budget adjustment');

    if (isExpense && !isBudgetAllocation) {
      final openingBudget =
        (widget.organization['budget'] as num?)?.toDouble() ?? 0.0;
      final totalAvailableBalance =
        widget.viewModel.calculateAvailableBalance(openingBudget);

      if (amount > totalAvailableBalance) {
        setState(() {
          _errorMessage =
              "Insufficient Funds! Available: ₱${totalAvailableBalance.toStringAsFixed(2)}";
        });
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await widget.viewModel.createTransaction({
        'title': title,
        'description': _descriptionController.text.trim(),
        'department': _departmentController.text.trim(),
        'amount': amount,
        'transaction_type': _transactionType,
        'occurred_at': _occurredAt.toIso8601String(),
      });

      if (!mounted) return;

      Navigator.pop(context);
      widget.onTransactionCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  String _formatDateTime(DateTime date) {
    final monthName = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][date.month - 1];

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$monthName ${date.day}, ${date.year} $hour:$minute $period';
  }
}


