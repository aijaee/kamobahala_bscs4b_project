import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../auth/login_screen.dart';
import '../dashboard/main_navigation_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  final String organizationId;
  final Function(int)? onTabChange;

  const ProfileScreen({
    super.key,
    required this.organizationId,
    this.onTabChange,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _displayNameController;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();

    // Initialize profile data on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final viewModel = context.read<ProfileViewModel>();
        viewModel.initializeProfile(widget.organizationId);
      }
    });
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh profile if organization ID changes
    if (oldWidget.organizationId != widget.organizationId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final viewModel = context.read<ProfileViewModel>();
          viewModel.initializeProfile(widget.organizationId);
        }
      });
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Update controller when display name is loaded
        if (viewModel.displayName != null &&
            _displayNameController.text.isEmpty) {
          _displayNameController.text = viewModel.displayName ?? '';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success Message
              if (viewModel.successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          viewModel.successMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.green.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => viewModel.clearMessages(),
                        child:
                            Icon(Icons.close, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error Message
              if (viewModel.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          viewModel.errorMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => viewModel.clearMessages(),
                        child: Icon(Icons.close, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Display Name Field (Editable)
              Text(
                'Display Name',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              if (_isEditingName)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _displayNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter display name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: viewModel.isUpdatingName
                          ? null
                          : () async {
                              final success = await viewModel
                                  .updateDisplayName(
                                      _displayNameController.text);
                              if (success && mounted) {
                                setState(() => _isEditingName = false);
                              }
                            },
                      child: viewModel.isUpdatingName
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Save',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: viewModel.isUpdatingName
                          ? null
                          : () {
                              _displayNameController.text =
                                  viewModel.displayName ?? '';
                              setState(() => _isEditingName = false);
                            },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: () => setState(() => _isEditingName = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          viewModel.displayName ?? 'Not set',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: viewModel.displayName != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                        Icon(
                          Icons.edit,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Email Field (Read-only)
              Text(
                'Email',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Text(
                  viewModel.email ?? 'Not available',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Organization Field (Read-only)
              Text(
                'Organization',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Text(
                  viewModel.currentOrganizationName ?? 'Not available',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Role Field (Read-only)
              Text(
                'Role',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    _buildRoleBadge(viewModel.userRole ?? 'Unknown'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Switch Organization Button
              if (viewModel.organizations.length > 1)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () =>
                        _showSwitchOrganizationDialog(context, viewModel),
                    child: Text(
                      'Switch Organization',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () =>
                      _showLogoutConfirmation(context, viewModel),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(String role) {
    Color backgroundColor;
    Color textColor;

    if (role.toLowerCase() == 'admin') {
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade700;
    } else {
      backgroundColor = Colors.blue.shade100;
      textColor = Colors.blue.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _showSwitchOrganizationDialog(
      BuildContext context, ProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Switch Organization',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...viewModel.organizations.map((org) {
                final isCurrentOrg =
                    org.id == viewModel.currentOrganizationId;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentOrg
                          ? Colors.blue.shade100
                          : Colors.grey.shade100,
                      foregroundColor: isCurrentOrg
                          ? Colors.blue.shade700
                          : Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: isCurrentOrg
                        ? null
                        : () async {
                            Navigator.pop(context); // Close the dialog
                            final success = await viewModel
                                .switchOrganization(org.id);
                            if (success && mounted) {
                              // Replace MainNavigationWrapper with new organization
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MainNavigationWrapper(
                                    organization: org.toMap(),
                                    initialIndex: 3, // Stay on Profile tab
                                  ),
                                ),
                              );
                            }
                          },
                    icon: isCurrentOrg ? const Icon(Icons.check) : null,
                    label: Text(
                      org.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(
      BuildContext context, ProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await viewModel.logout();
              if (success && mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}