import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/financial_viewmodel.dart';
import '../../viewmodels/organization_dashboard_viewmodel.dart';
import 'organization_dashboard.dart';
import '../projects/projects_list.dart';

class FinancialLedgerScreen extends StatefulWidget {
  final int initialIndex;
  final Map<String, dynamic> organization;
  const FinancialLedgerScreen(
      {super.key, this.initialIndex = 2, required this.organization});

  @override
  State<FinancialLedgerScreen> createState() => _FinancialLedgerScreenState();
}

class _FinancialLedgerScreenState extends State<FinancialLedgerScreen> {
  late int currentIndex;
  late FinancialViewModel _viewModel;
  late OrganizationDashboardViewModel _dashboardViewModel;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    // Use the global FinancialViewModel from Provider
    _viewModel = context.read<FinancialViewModel>();
    _dashboardViewModel = OrganizationDashboardViewModel(
      financialViewModel: _viewModel,
    );
    _fetchTransactions();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    // Note: Don't dispose of _viewModel since it's managed by Provider
    _dashboardViewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    setState(() {
      // Update balance calculation when transactions change
      _dashboardViewModel.calculateFinancialSummary(
        widget.organization,
        _viewModel.transactions,
      );
    });
  }

  /// Fetches transactions for the organization
  Future<void> _fetchTransactions() async {
    await _viewModel.fetchTransactions(widget.organization['id'].toString());
    _dashboardViewModel.calculateFinancialSummary(
      widget.organization,
      _viewModel.transactions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = _viewModel.groupedTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildBottomNav(),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 100),
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
                  (group) => [
                    _buildDateHeader(group.$1),
                    ...group.$2.map(_buildTransactionRow),
                  ],
                ),
            ],
          ),
          _buildFloatingActionButton(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (idx) {
        if (idx == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    OrganizationDashboard(organization: widget.organization)),
          );
        } else if (idx == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => ProjectsList(
                    initialIndex: 1, organization: widget.organization)),
          );
        } else {
          setState(() {
            currentIndex = idx;
          });
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
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
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios,
            color: Color(0xFF111418), size: 20),
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

  /// Builds the balance card using ViewModel balance
  Widget _buildBalanceCard() {
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
          Text(
            "${widget.organization['name'] ?? 'ORGANIZATION'} TOTAL DEPOSITORY BALANCE".toUpperCase(),
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(_dashboardViewModel.currentBalance),
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

  Widget _buildTransactionRow(Map<String, dynamic> transaction) {
    final amount = _viewModel.getSignedAmount(transaction);
    final occurredAt = DateTime.tryParse(
          transaction['occurred_at']?.toString() ?? '',
        ) ??
        DateTime.now();
    final department = (transaction['department']?.toString().trim().isNotEmpty ?? false)
        ? transaction['department'].toString()
        : 'General';
    final description = (transaction['description']?.toString().trim().isNotEmpty ?? false)
        ? transaction['description'].toString()
        : (amount > 0 ? 'Incoming funds' : 'Expense recorded');
    final deptColor = _departmentColor(department);
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
              color:
                  isIncome ? const Color(0x1A22C55E) : const Color(0x1A137FEC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome ? Icons.south_west : Icons.north_east,
              color:
                  isIncome ? const Color(0xFF16A34A) : const Color(0xFF137FEC),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction['title']?.toString() ?? 'Untitled transaction',
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
                '${isIncome ? '+' : '-'}${_formatCurrency(amount.abs())}',
                style: GoogleFonts.inter(
                  color: isIncome
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFEF4444),
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
    return Positioned(
      right: 24,
      bottom: 24,
      child: FloatingActionButton(
        backgroundColor: const Color(0xFF137FEC),
        onPressed: _openCreateTransactionDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
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

  const _TransactionFormDialog({
    required this.organizationId,
    required this.viewModel,
    required this.onTransactionCreated,
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
              _buildTextField('Description', _descriptionController, 'What is this payment for?'),
              const SizedBox(height: 12),
              _buildTextField('Department', _departmentController, 'e.g. Logistics'),
              const SizedBox(height: 12),
              _buildTextField(
                'Amount',
                _amountController,
                '0.00',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              Text('Type', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    final amount = double.tryParse(_amountController.text.trim());

    if (_titleController.text.trim().isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title and valid amount > 0')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.viewModel.createTransaction({
        'title': _titleController.text.trim(),
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
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String _formatDateTime(DateTime date) {
    final monthName = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ][date.month - 1];
    
    final hour = date.hour == 0 ? 12 : date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    
    return '$monthName ${date.day}, ${date.year} $hour:$minute $period';
  }
}
