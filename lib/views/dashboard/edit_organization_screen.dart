import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/admin_service.dart';
import '../../viewmodels/edit_organization_viewmodel.dart';
import 'main_dashboard_screen.dart';

const kPrimary = Color(0xFF1A73E8);
const kPrimaryDark = Color(0xFF0B539B);
const kSurface = Color(0xFFF5F7FA);
const kCardBg = Color(0xFFFFFFFF);
const kBorder = Color(0xFFDDE1E7);
const kTextPrimary = Color(0xFF1A1D23);
const kTextSecondary = Color(0xFF6B7280);
const kRed = Color(0xFFE53935);

class EditOrganizationScreen extends StatefulWidget {
  final Map<String, dynamic> organization;

  const EditOrganizationScreen({super.key, required this.organization});

  @override
  State<EditOrganizationScreen> createState() => _EditOrganizationScreenState();
}

class _EditOrganizationScreenState extends State<EditOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  late final EditOrganizationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EditOrganizationViewModel();
    _viewModel.initialize(widget.organization);
    _checkAdminStatus();
    _viewModel.loadExistingMembers(widget.organization['id']);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isUserAdmin(widget.organization['id']);
    if (!mounted) return;

    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admins can edit organization settings'),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _refreshMembers() {
    return _viewModel.loadExistingMembers(widget.organization['id']);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: kTextSecondary),
      filled: true,
      fillColor: kCardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
    );
  }

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
          Row(
            children: [
              const Icon(Icons.account_balance, size: 18, color: kPrimary),
              const SizedBox(width: 8),
              Text(
                'Budget Depository',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _viewModel.budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: kTextPrimary,
            ),
            decoration: InputDecoration(
              prefixText: '₱  ',
              prefixStyle: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: kTextPrimary,
              ),
              hintText: '0.00',
              hintStyle: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: kTextSecondary,
              ),
              filled: true,
              fillColor: kCardBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              border: InputBorder.none,
            ),
          ),
          Divider(color: kBorder, height: 16),
          Text(
            'Funds will be locked upon organization update.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(int index) {
    final member = _viewModel.members[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: member.emailController,
              style: GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
              decoration: _inputDecoration('Member email'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: member.role,
              style: GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
              dropdownColor: kCardBg,
              decoration: InputDecoration(
                filled: true,
                fillColor: kCardBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kPrimary, width: 1.5),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                DropdownMenuItem(value: 'Member', child: Text('Member')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _viewModel.updateMemberRole(index, value);
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kRed, size: 20),
            onPressed: () => _viewModel.removeMember(index),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success =
        await _viewModel.updateOrganization(widget.organization['id']);
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _viewModel.errorMessage ?? 'Failed to update organization',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MainDashboardScreen(),
      ),
    );
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
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const MainDashboardScreen(),
              ),
            );
          },
        ),
        title: Text(
          'Edit Organization',
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
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return RefreshIndicator(
              onRefresh: _refreshMembers,
              color: const Color(0xFF137FEC),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Organization Name'),
                      TextFormField(
                        controller: _viewModel.nameController,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: kTextPrimary),
                        decoration:
                            _inputDecoration('e.g. Student Council 2025'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Organization name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _label('Description (Optional)'),
                      TextFormField(
                        controller: _viewModel.descriptionController,
                        maxLines: 4,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: kTextPrimary),
                        decoration: _inputDecoration(
                          'Outline organization goals and purpose...',
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildBudgetCard(),
                      const SizedBox(height: 24),
                      _label('Members'),
                      ...List.generate(
                        _viewModel.members.length,
                        _buildMemberRow,
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _viewModel.addMember,
                        icon: const Icon(Icons.add, size: 18, color: kPrimary),
                        label: Text(
                          'Add Member',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: kPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: _viewModel.isLoading ? null : _submit,
                              child: _viewModel.isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Update Organization',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
