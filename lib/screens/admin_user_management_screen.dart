// lib/screens/admin_user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/user_profile.dart';
import 'package:line_survey_pro/services/auth_service.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:line_survey_pro/screens/assign_lines_to_manager_screen.dart'; // Import for assigning lines
import 'dart:async'; // For StreamSubscription

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final AuthService _authService = AuthService();
  List<UserProfile> _allUsers = []; // Full list of users
  List<UserProfile> _filteredUsers = []; // List after applying search/filters
  bool _isLoading = true;

  // Search and Filter State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, Set<String>> _selectedFilters =
      {}; // Map of fieldName -> Set of selectedOptions

  // Filter options for User Management
  final Map<String, List<String>> _filterOptions = {
    'role': ['Admin', 'Manager', 'Worker', 'None'], // 'None' for null roles
    'status': ['pending', 'approved', 'rejected'],
  };

  StreamSubscription? _usersSubscription; // Stream subscription for user data

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _usersSubscription?.cancel(); // Cancel the subscription
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters(); // Apply filters when search query changes
    });
  }

  void _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Stream all user profiles for real-time updates
      _usersSubscription?.cancel(); // Cancel previous subscription if exists
      _usersSubscription = _authService.streamAllUserProfiles().listen((users) {
        if (mounted) {
          setState(() {
            _allUsers = users;
            _applyFilters(); // Apply filters after new data loads
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

  // NEW: Method to apply search and filters
  void _applyFilters() {
    List<UserProfile> tempUsers = List.from(_allUsers);

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      final String lowerCaseQuery = _searchQuery.toLowerCase();
      tempUsers = tempUsers.where((user) {
        return (user.displayName?.toLowerCase().contains(lowerCaseQuery) ??
                false) ||
            user.email.toLowerCase().contains(lowerCaseQuery) ||
            (user.role?.toLowerCase().contains(lowerCaseQuery) ?? false) ||
            user.status.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }

    // Apply selected filter options (Role and Status)
    _selectedFilters.forEach((fieldName, selectedOptions) {
      if (selectedOptions.isNotEmpty) {
        tempUsers = tempUsers.where((user) {
          String? fieldValue;
          if (fieldName == 'role') {
            fieldValue = user.role;
          } else if (fieldName == 'status') {
            fieldValue = user.status;
          }
          // Special handling for 'None' role filter
          if (selectedOptions.contains('None') && fieldName == 'role') {
            return fieldValue == null || selectedOptions.contains(fieldValue);
          }
          return fieldValue != null && selectedOptions.contains(fieldValue);
        }).toList();
      }
    });

    setState(() {
      _filteredUsers = tempUsers;
    });
  }

  void _toggleFilterOption(String fieldName, String option) {
    setState(() {
      _selectedFilters.putIfAbsent(fieldName, () => {});
      if (_selectedFilters[fieldName]!.contains(option)) {
        _selectedFilters[fieldName]!.remove(option);
      } else {
        _selectedFilters[fieldName]!.add(option);
      }
      _applyFilters(); // Re-apply filters immediately
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedFilters.clear();
      _searchController.clear();
      _searchQuery = '';
      _applyFilters(); // Re-apply to show all users
    });
  }

  // Helper to convert camelCase to Human Readable Title Case (used in filter panel)
  String _toHumanReadable(String camelCase) {
    return camelCase
        .replaceAllMapped(
            RegExp(r'(^[a-z])|[A-Z]'),
            (m) =>
                m[1] == null ? ' ${m[0] ?? ''}' : (m[0]?.toUpperCase() ?? ''))
        .trim();
  }

  // Build the filter panel UI (as an EndDrawer)
  Widget _buildFilterPanel() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Filter Users',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            Expanded(
              child: ListView(
                children: _filterOptions.entries.map((entry) {
                  final fieldName = entry.key;
                  final options = entry.value;
                  return ExpansionTile(
                    title: Text(_toHumanReadable(fieldName)),
                    children: options.map((option) {
                      final bool isSelected =
                          _selectedFilters[fieldName]?.contains(option) ??
                              false;
                      return CheckboxListTile(
                        title: Text(option),
                        value: isSelected,
                        onChanged: (bool? value) {
                          _toggleFilterOption(fieldName, option);
                        },
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _clearFilters,
                child: const Text('Clear Filters & Search'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NOTE: These methods are now called from the _showManageUserModal
  // They will internally trigger the caching logic in AuthService.
  Future<void> _updateUserRole(String userId, String? newRole) async {
    try {
      await _authService.updateUserRole(userId, newRole);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _updateUserStatus(String userId, String newStatus) async {
    try {
      // NEW LOGIC: If status is set to 'rejected', delete the user profile entirely.
      if (newStatus == 'rejected') {
        final bool? confirmDelete = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Confirm Rejection and Deletion'),
              content: Text(
                  'Are you sure you want to REJECT and DELETE this user\'s profile (${_allUsers.firstWhere((u) => u.id == userId).email})? This action is irreversible.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );

        if (confirmDelete == true) {
          await _authService.deleteUserProfile(userId); // Delete user profile
          if (mounted) {
            SnackBarUtils.showSnackBar(
                context, 'User profile rejected and deleted successfully!');
          }
        } else {
          // If deletion is cancelled, do not proceed with status update
          if (mounted) {
            SnackBarUtils.showSnackBar(context, 'Rejection/deletion cancelled.',
                isError: false);
          }
          throw Exception(
              'Rejection/deletion cancelled.'); // Propagate error to signal that save operation was interrupted
        }
      } else {
        // For 'pending' or 'approved' statuses, just update the status.
        await _authService.updateUserStatus(userId, newStatus);
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'User status updated to $newStatus.');
        }
      }
    } catch (e) {
      rethrow; // Propagate any errors from auth service
    }
  }

  // Show a modal bottom sheet to manage user (edit role/status)
  Future<void> _showManageUserModal(UserProfile user) async {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    String? selectedRole = user.role;
    String selectedStatus = user.status;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage User',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text('Email: ${user.email}'),
                  const SizedBox(height: 8),
                  // Role Dropdown
                  DropdownButtonFormField<String?>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None'),
                      ),
                      ...['Admin', 'Manager', 'Worker']
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ))
                          .toList(),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        selectedRole = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ['pending', 'approved', 'rejected']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() {
                          selectedStatus = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(modalContext).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            if (selectedRole != user.role) {
                              await _updateUserRole(user.id, selectedRole);
                            }
                            if (selectedStatus != user.status) {
                              await _updateUserStatus(user.id, selectedStatus);
                            }
                            if (mounted) {
                              Navigator.of(modalContext).pop();
                            }
                          } catch (e) {
                            if (mounted) {
                              SnackBarUtils.showSnackBar(
                                context,
                                'Failed to update user: ${e.toString()}',
                                isError: true,
                              );
                            }
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Method to navigate to the AssignLinesToManagerScreen
  void _assignLinesToManager(UserProfile user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssignLinesToManagerScreen(manager: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          Builder(
            // Use a Builder to get a context that can open the EndDrawer
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  Scaffold.of(context)
                      .openEndDrawer(); // Open the filter drawer
                },
              );
            },
          ),
        ],
      ),
      endDrawer: _buildFilterPanel(), // Add the filter panel as an end drawer
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty && _selectedFilters.isEmpty
                              ? 'No user profiles found in the system.'
                              : 'No users found matching current filters/search.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
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
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  // Consolidated Role and Status Display
                                  Row(
                                    children: [
                                      Text('Role: ',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      Expanded(
                                        // Use Expanded to prevent overflow
                                        child: Text(
                                            user.role?.toUpperCase() ?? 'NONE',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      const SizedBox(width: 16),
                                      Text('Status: ',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      Expanded(
                                        // Use Expanded to prevent overflow
                                        child: Text(user.status.toUpperCase(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.circle,
                                          size: 12,
                                          color: _getStatusColor(user.status)),
                                    ],
                                  ),
                                  const SizedBox(
                                      height: 16), // Spacing before buttons
                                  // Action Buttons wrapped in a Wrap for overflow handling
                                  Wrap(
                                    spacing:
                                        8.0, // Horizontal spacing between buttons
                                    runSpacing:
                                        4.0, // Vertical spacing between lines of buttons
                                    alignment: WrapAlignment
                                        .end, // Align buttons to the end
                                    children: [
                                      // Edit/Manage Button to open modal
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _showManageUserModal(user),
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Manage'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary
                                              .withOpacity(0.8),
                                          foregroundColor:
                                              colorScheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical:
                                                  8), // Smaller padding for compactness
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .labelSmall, // Smaller text
                                        ),
                                      ),
                                      // Assign Lines Button (only for Managers)
                                      if (user.role == 'Manager' &&
                                          user.status == 'approved')
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              _assignLinesToManager(user),
                                          icon: const Icon(Icons.line_axis),
                                          label: const Text('Assign Lines'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                colorScheme.secondary,
                                            foregroundColor:
                                                colorScheme.onSecondary,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ),
                                      // Delete Profile Button (Icon only)
                                      if (user.status == 'approved' &&
                                          user.role != null)
                                        OutlinedButton(
                                          // Changed to OutlinedButton
                                          onPressed: () async {
                                            final bool? confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder:
                                                  (BuildContext dialogContext) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Confirm Deletion'),
                                                  content: Text(
                                                      'Are you sure you want to delete the profile for ${user.email}? This action is irreversible.'),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                                  dialogContext)
                                                              .pop(false),
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                                  dialogContext)
                                                              .pop(true),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  colorScheme
                                                                      .error),
                                                      child:
                                                          const Text('Delete'),
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
                                                  SnackBarUtils.showSnackBar(
                                                      context,
                                                      'User profile for ${user.email} deleted.');
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  SnackBarUtils.showSnackBar(
                                                      context,
                                                      'Failed to delete user profile: ${e.toString()}',
                                                      isError: true);
                                                }
                                              }
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            // Style for icon only button
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                                color: Colors.red),
                                            padding: const EdgeInsets.all(
                                                8), // Reduced padding for icon only
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                          ),
                                          child: const Icon(Icons
                                              .delete_forever), // Only icon
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
