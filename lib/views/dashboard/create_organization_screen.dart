import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/organization_service.dart';
import '../../core/services/admin_service.dart';
import 'main_dashboard_screen.dart';

// Brand colors extracted from the "New Project" screen design
const kPrimary = Color(0xFF1A73E8); // Bright blue (buttons, links, icons)
const kPrimaryDark = Color(0xFF0B539B); // Deep blue (elevated button bg)
const kSurface = Color(0xFFF5F7FA); // Light gray page background
const kCardBg = Color(0xFFFFFFFF); // White card / input background
const kBorder = Color(0xFFDDE1E7); // Subtle border color
const kTextPrimary = Color(0xFF1A1D23); // Near-black headings
const kTextSecondary = Color(0xFF6B7280); // Gray hint / label text
const kRed = Color(0xFFE53935); // Cancel / delete red

class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  State<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final OrganizationService _organizationService = OrganizationService();
  final AdminService _adminService = AdminService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  List<Map<String, dynamic>> members = [
    {"controller": TextEditingController(), "role": "Member"}
  ];

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    budgetController.dispose();
    for (final member in members) {
      final controller = member['controller'];
      if (controller is TextEditingController) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  // ── Shared input decoration ─────────────────────────────────────────────────
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: kTextSecondary,
      ),
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
          icon: const Icon(
            Icons.close, // "X" icon
            color: kRed, // your red color constant
            size: 24, // adjust size if needed
          ),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
          ),
        ),
        title: Text(
          "New Organization",
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Organization Name ────────────────────────────────────────
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

                // ── Description ──────────────────────────────────────────────
                _label("Description (Optional)"),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  style: GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
                  decoration: _inputDecoration(
                      "Outline organization goals and purpose..."),
                ),

                const SizedBox(height: 18),

                // ── Budget Depository ────────────────────────────────────────
                _buildBudgetCard(),

                const SizedBox(height: 24),

                // ── Members ──────────────────────────────────────────────────
                _label("Members"),
                ...List.generate(
                    members.length, (index) => _buildMemberRow(index)),

                const SizedBox(height: 10),

                // ── Add Member Button ────────────────────────────────────────
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      members.add({
                        "controller": TextEditingController(),
                        "role": "Member",
                      });
                    });
                  },
                  icon: const Icon(Icons.add, size: 18, color: kPrimary),
                  label: Text(
                    "Add Member",
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

                // ── Create Organization Button ────────────────────────────────
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _createOrganization();
                      }
                    },
                    child: Text(
                      "Create Organization",
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
      ),
    );
  }

  // ── Budget Card (mirrors "Budget Allocation" card in the reference image) ────
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
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          Divider(color: kBorder, height: 16),
          Text(
            "State the initial budget for this organization. This can be updated later in the organization settings.",
            style: GoogleFonts.inter(
              fontSize: 11,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Member Row ───────────────────────────────────────────────────────────────
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
              initialValue: members[index]["role"],
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
                setState(() => members[index]["role"] = value);
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

  Future<void> _createOrganization() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final budget = double.tryParse(budgetController.text.trim()) ?? 0.0;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
              content:
                  Text('You must be logged in to create an organization.')),
        );
      return;
    }
    final data = {
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'budget': budget,
      'owner_id': userId,
    };

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final newOrg = await _organizationService.createOrganization(data);

      // Add members from the form
      for (final member in members) {
        final email = member['controller'].text.trim();
        final role = member['role'] as String;
        if (email.isNotEmpty) {
          await _adminService.addMemberByEmail(newOrg.id, email, role);
        }
      }

      if (!mounted) return;

      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Organization created successfully.')),
        );
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
      );
    } catch (error) {
      if (!mounted) return;

      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Failed to create organization: $error')),
        );
    }
  }
}
