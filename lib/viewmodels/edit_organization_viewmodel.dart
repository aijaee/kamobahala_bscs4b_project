import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/admin_service.dart';
import '../core/services/organization_service.dart';

class EditableOrganizationMember {
  EditableOrganizationMember({
    required this.emailController,
    required this.role,
  });

  final TextEditingController emailController;
  String role;

  void dispose() {
    emailController.dispose();
  }
}

class EditOrganizationViewModel extends ChangeNotifier {
  EditOrganizationViewModel({
    OrganizationService? organizationService,
    AdminService? adminService,
  })  : _organizationService = organizationService ?? OrganizationService(),
        _adminService = adminService ?? AdminService();

  final OrganizationService _organizationService;
  final AdminService _adminService;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  final List<EditableOrganizationMember> members = [];
  final List<String> _existingMemberEmails = [];

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get existingMemberEmails =>
      List.unmodifiable(_existingMemberEmails);

  void initialize(Map<String, dynamic> organization) {
    nameController.text = organization['name']?.toString() ?? '';
    descriptionController.text = organization['description']?.toString() ?? '';
    budgetController.text = (organization['budget'] ?? 0.0).toString();
  }

  Future<void> loadExistingMembers(String organizationId) async {
    _setLoading(true);

    try {
      final existingMembers =
          await _adminService.getOrganizationMembers(organizationId);

      for (final member in members) {
        member.dispose();
      }
      members.clear();

      _existingMemberEmails
        ..clear()
        ..addAll(existingMembers
            .map((member) => member['email']?.toString())
            .whereType<String>());

      for (final member in existingMembers) {
        members.add(
          EditableOrganizationMember(
            emailController: TextEditingController(
              text: member['email']?.toString() ?? '',
            ),
            role: member['role']?.toString() ?? 'Member',
          ),
        );
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error loading members: $e';
    } finally {
      _setLoading(false);
    }
  }

  void addMember() {
    members.add(
      EditableOrganizationMember(
        emailController: TextEditingController(),
        role: 'Member',
      ),
    );
    notifyListeners();
  }

  void removeMember(int index) {
    if (index < 0 || index >= members.length) return;

    members[index].dispose();
    members.removeAt(index);
    notifyListeners();
  }

  void updateMemberRole(int index, String role) {
    if (index < 0 || index >= members.length) return;

    members[index].role = role;
    notifyListeners();
  }

  Future<bool> updateOrganization(String organizationId) async {
    _setLoading(true);

    try {
      final updatedOrganization = {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'budget': double.tryParse(budgetController.text.trim()) ?? 0.0,
      };

      await _organizationService.updateOrganization(
          organizationId, updatedOrganization);

      final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;
      final newMemberEmails = <String, String>{};

      for (final member in members) {
        final email = member.emailController.text.trim();
        if (email.isNotEmpty) {
          newMemberEmails[email] = member.role;
        }
      }

      for (final entry in newMemberEmails.entries) {
        if (!_existingMemberEmails.contains(entry.key)) {
          await _adminService.addMemberByEmail(
              organizationId, entry.key, entry.value);
        }
      }

      final existingMembers =
          await _adminService.getOrganizationMembers(organizationId);
      for (final entry in newMemberEmails.entries) {
        if (_existingMemberEmails.contains(entry.key)) {
          final existingMember = existingMembers.firstWhere(
            (member) => member['email']?.toString() == entry.key,
            orElse: () => <String, dynamic>{},
          );

          if (existingMember.isNotEmpty &&
              existingMember['role']?.toString() != entry.value) {
            await _adminService.updateUserRole(
                organizationId, entry.key, entry.value);
          }
        }
      }

      for (final email in _existingMemberEmails) {
        if (!newMemberEmails.containsKey(email) && email != currentUserEmail) {
          await _adminService.removeMember(organizationId, email);
        }
      }

      _existingMemberEmails
        ..clear()
        ..addAll(newMemberEmails.keys);

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error updating organization: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final member in members) {
      member.dispose();
    }
    nameController.dispose();
    descriptionController.dispose();
    budgetController.dispose();
    super.dispose();
  }
}
