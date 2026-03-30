import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_dashboard_screen.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/organization_service.dart';

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
  // TODO: [MVVM] move organization state and service calls into EditOrganizationViewModel
  final _formKey = GlobalKey<FormState>();
  final OrganizationService _orgService = OrganizationService();
  final AdminService _adminService = AdminService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  // TODO: [MVVM] manage members list in ViewModel instead of widget state when possible
  List<Map<String, dynamic>> members = [];
  List<String> _existingMemberEmails = [];

  @override
  void initState() {
    super.initState();
    // TODO: [MVVM] initialize ViewModel with widget.organization and remove text controller preset logic from view
    nameController.text = widget.organization['name'] ?? '';
    descriptionController.text = widget.organization['description'] ?? '';
    budgetController.text = (widget.organization['budget'] ?? 0.0).toString();
    
    _loadExistingMembers();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isUserAdmin(widget.organization['id']);
    if (!isAdmin && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can edit organization settings')),
      );
    }
  }

  Future<void> _loadExistingMembers() async {
    try {
      final existingMembers =
          await _adminService.getOrganizationMembers(widget.organization['id']);
      
      setState(() {
        _existingMemberEmails =
            existingMembers.map((m) => m['email'] as String).toList();
        members = existingMembers.map((member) {
          return {
            'controller': TextEditingController(text: member['email'] as String),
            'role': member['role'] as String,
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading members: $e');
    }
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
                "Budget Depository",
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
            controller: budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: kTextPrimary,
            ),
            decoration: InputDecoration(
              prefixText: "₱  ",
              prefixStyle: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: kTextPrimary,
              ),
              hintText: "0.00",
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
            "Funds will be locked upon organization update.",
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: members[index]["controller"],
              style: GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
              decoration: _inputDecoration("Member email"),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: members[index]["role"] as String,
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
                DropdownMenuItem(value: "Admin", child: Text("Admin")),
                DropdownMenuItem(value: "Member", child: Text("Member")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => members[index]["role"] = value as Object);
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kRed, size: 20),
            onPressed: () {
              setState(() => members.removeAt(index));
            },
          ),
        ],
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
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
          ),
        ),
        title: Text(
          "Edit Organization",
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
        child: RefreshIndicator(
          onRefresh: _loadExistingMembers,
          color: const Color(0xFF137FEC),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _label("Organization Name"),
                TextFormField(
                  controller: nameController,
                  style: GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
                  decoration: _inputDecoration("e.g. Student Council 2025"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Organization name is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _label("Description (Optional)"),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  style: GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
                  decoration: _inputDecoration(
                      "Outline organization goals and purpose..."),
                ),
                const SizedBox(height: 18),
                _buildBudgetCard(),
                const SizedBox(height: 24),
                _label("Members"),
                ...List.generate(
                    members.length, (index) => _buildMemberRow(index)),
                const SizedBox(height: 10),
                // TODO: [MVVM] delegate member addition to ViewModel.addMember()
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      members.add({
                        "controller": TextEditingController(),
                        "role": "Member",
                      } as Map<String, dynamic>);
                    });
                  },
                  icon: const Icon(Icons.add, size: 18, color: kPrimary),
                  label: Text(
                    "Add Member",
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: kPrimary,
                        fontWeight: FontWeight.w500),
                  ),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4)),
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
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () {
                          // TODO: [MVVM] call ViewModel.updateOrganization() instead of direct method
                          if (_formKey.currentState!.validate()) {
                            _updateOrganization();
                          }
                        },
                        child: Text(
                          "Update Organization",
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  void _updateOrganization() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    final data = {
      'name': nameController.text,
      'description': descriptionController.text,
      'budget': double.tryParse(budgetController.text) ?? 0.0,
    };

    try {
      await _orgService.updateOrganization(widget.organization['id'], data);

      final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;

      final newMemberEmails = <String, String>{};
      for (final member in members) {
        final email = member['controller'].text.trim();
        if (email.isNotEmpty) {
          newMemberEmails[email] = member['role'];
        }
      }
      for (final email in newMemberEmails.keys) {
        if (!_existingMemberEmails.contains(email)) {
          await _adminService.addMemberByEmail(
              widget.organization['id'], email, newMemberEmails[email]!);
        }
      }

      for (final email in newMemberEmails.keys) {
        if (_existingMemberEmails.contains(email)) {
          final existingMembers =
              await _adminService.getOrganizationMembers(widget.organization['id']);
          final existingMember = existingMembers.firstWhere(
            (m) => m['email'] == email,
            orElse: () => {},
          );
          
          if (existingMember.isNotEmpty && existingMember['role'] != newMemberEmails[email]) {
            await _adminService.updateUserRole(
                widget.organization['id'], email, newMemberEmails[email]!);
          }
        }
      }

      // Remove deleted members but never remove the current admin user
      for (final email in _existingMemberEmails) {
        if (!newMemberEmails.containsKey(email) &&
            email != currentUserEmail) {
          await _adminService.removeMember(widget.organization['id'], email);
        }
      }

      if (!context.mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const MainDashboardScreen()));
    } catch (e) {
      Navigator.pop(context);
      // TODO: Show a proper error message to the user
      print('Error updating organization: $e');
    }
  }
}

