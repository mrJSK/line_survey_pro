import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/user_profile.dart';
import 'package:line_survey_pro/services/auth_service.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:line_survey_pro/screens/assign_lines_to_manager_screen.dart'; // Import for assigning lines

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final AuthService _authService = AuthService();
  List<UserProfile> _allUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Stream all user profiles for real-time updates
      _authService.streamAllUserProfiles().listen((users) {
        if (mounted) {
          setState(() {
            _allUsers = users;
            _isLoading = false;
          });
        }
      }, onError: (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Error loading users: ${e.toString()}',
              isError: true);
          setState(() {
            _isLoading = false;
          });
        }
        print('Error streaming all user profiles: $e');
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error initiating user stream: ${e.toString()}',
            isError: true);
        setState(() {
          _isLoading = false;
        });
      }
      print('Error initiating user stream: $e');
    }
  }

  Future<void> _updateUserRole(UserProfile user, String? newRole) async {
    try {
      await _authService.updateUserRole(user.id, newRole);
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, '${user.email} role updated to ${newRole ?? 'None'}.');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Failed to update role: ${e.toString()}',
            isError: true);
      }
    }
  }

  Future<void> _updateUserStatus(UserProfile user, String newStatus) async {
    try {
      await _authService.updateUserStatus(user.id, newStatus);
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, '${user.email} status updated to $newStatus.');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Failed to update status: ${e.toString()}',
            isError: true);
      }
    }
  }

  void _assignLinesToManager(UserProfile manager) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssignLinesToManagerScreen(manager: manager),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allUsers.isEmpty
              ? Center(
                  child: Text(
                    'No user profiles found in the system.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _allUsers.length,
                  itemBuilder: (context, index) {
                    final user = _allUsers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? user.email,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Role: ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                DropdownButton<String>(
                                  value: user.role,
                                  hint: const Text('Set Role'),
                                  items: const <String>[
                                    'Worker',
                                    'Manager',
                                    'Admin'
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null &&
                                        newValue != user.role) {
                                      _updateUserRole(user, newValue);
                                    }
                                  },
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text('Status: ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                DropdownButton<String>(
                                  value: user.status,
                                  hint: const Text('Set Status'),
                                  items: const <String>[
                                    'pending',
                                    'approved',
                                    'rejected'
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null &&
                                        newValue != user.status) {
                                      _updateUserStatus(user, newValue);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.circle,
                                    size: 12,
                                    color: _getStatusColor(user.status)),
                              ],
                            ),
                            if (user.role == 'Manager')
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () => _assignLinesToManager(user),
                                  icon: const Icon(Icons.line_axis),
                                  label: const Text('Assign Lines'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.secondary,
                                    foregroundColor: colorScheme.onSecondary,
                                  ),
                                ),
                              ),
                            if (user.status == 'approved' &&
                                user.role !=
                                    null) // If approved and has role, can delete profile
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final bool? confirm =
                                        await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext dialogContext) {
                                        return AlertDialog(
                                          title: const Text('Confirm Deletion'),
                                          content: Text(
                                              'Are you sure you want to delete the profile for ${user.email}? This action is irreversible.'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(dialogContext)
                                                      .pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(dialogContext)
                                                      .pop(true),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      colorScheme.error),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (confirm == true) {
                                      try {
                                        await _authService
                                            .deleteUserProfile(user.id);
                                        if (mounted) {
                                          SnackBarUtils.showSnackBar(context,
                                              'User profile for ${user.email} deleted.');
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          SnackBarUtils.showSnackBar(context,
                                              'Failed to delete user profile: ${e.toString()}',
                                              isError: true);
                                        }
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete_forever,
                                      color: Colors.red),
                                  label: const Text('Delete Profile',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
