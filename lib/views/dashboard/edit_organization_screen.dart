import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  const EditOrganizationScreen({super.key});

  @override
  State<EditOrganizationScreen> createState() => _EditOrganizationScreenState();
}

class _EditOrganizationScreenState extends State<EditOrganizationScreen> {
  // TODO: [MVVM] move organization state and service calls into EditOrganizationViewModel
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  // TODO: [MVVM] manage members list in ViewModel instead of widget state when possible
  List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream
    // TODO: load organization details
=======
    // TODO: [MVVM] initialize ViewModel with widget.organization and remove text controller preset logic from view
    // Napoleon: Implemented live backend functionality.
    // Load organization details from the passed widget data
    nameController.text = widget.organization['name'] ?? '';
    descriptionController.text = widget.organization['description'] ?? '';
    budgetController.text = (widget.organization['budget'] ?? 0.0).toString();
>>>>>>> Stashed changes
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
              
              value: members[index]["role"],
              style: GoogleFonts.inter(fontSize: 14, color: kTextPrimary),
              dropdownColor: kCardBg,
              decoration: InputDecoration(
                filled: true,
                fillColor: kCardBg,
                
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
                ...List.generate(members.length, (index) => _buildMemberRow(index)),
                const SizedBox(height: 10),
                // TODO: [MVVM] delegate member addition to ViewModel.addMember()
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
                        fontSize: 14, color: kPrimary, fontWeight: FontWeight.w500),
                  ),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
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
<<<<<<< Updated upstream
=======
                          // TODO: [MVVM] call ViewModel.updateOrganization() instead of direct method
                          // Napoleon: Implemented live backend functionality.
>>>>>>> Stashed changes
                          if (_formKey.currentState!.validate()) {
                            // TODO: update organization
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
    );
  }
<<<<<<< Updated upstream
}
=======

  // TODO: [MVVM] move update logic to ViewModel and convert to async state updates
  // Napoleon: Implemented live backend functionality.
  void _updateOrganization() async {
    // Show loading indicator
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
      if (!context.mounted) return;
      Navigator.pop(context); // pop loading dialog
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const MainDashboardScreen()));
    } catch (e) {
      Navigator.pop(context); // pop loading dialog
      // TODO: Show a proper error message to the user
    }
  }
}
>>>>>>> Stashed changes
