// lib/screens/assign_task_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/task.dart';
import 'package:line_survey_pro/models/user_profile.dart';
import 'package:line_survey_pro/models/transmission_line.dart'; // To get line names if needed
import 'package:line_survey_pro/services/auth_service.dart';
import 'package:line_survey_pro/services/task_service.dart';
import 'package:line_survey_pro/services/firestore_service.dart'; // For fetching transmission lines
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:uuid/uuid.dart'; // For generating unique task IDs

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _targetTowerRangeController =
      TextEditingController();

  UserProfile? _selectedWorker; // For the worker dropdown
  TransmissionLine? _selectedLine; // For the line dropdown
  DateTime? _selectedDueDate;

  List<UserProfile> _workers = [];
  List<TransmissionLine> _transmissionLines = [];
  UserProfile? _currentManager; // To get assignedByUserId/Name

  bool _isLoading = true;
  bool _isAssigning = false;

  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid(); // For generating unique IDs

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _targetTowerRangeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch current manager's profile
      _currentManager = await _authService.getCurrentUserProfile();

      // Fetch all user profiles and filter for workers
      final allUsers = await _authService.getAllUserProfiles();
      _workers = allUsers.where((user) => user.role == 'Worker').toList();

      // Fetch all transmission lines
      _transmissionLines = await _firestoreService.getTransmissionLinesOnce();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error loading data: ${e.toString()}',
            isError: true);
      }
      print('Error loading initial data for task assignment: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ??
          DateTime.now().add(const Duration(days: 1)), // Default to tomorrow
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _assignTask() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedWorker == null) {
        SnackBarUtils.showSnackBar(context, 'Please select a worker.',
            isError: true);
        return;
      }
      if (_selectedLine == null) {
        SnackBarUtils.showSnackBar(context, 'Please select a line.',
            isError: true);
        return;
      }
      if (_selectedDueDate == null) {
        SnackBarUtils.showSnackBar(context, 'Please select a due date.',
            isError: true);
        return;
      }

      setState(() {
        _isAssigning = true;
      });

      try {
        final String taskId = _uuid.v4(); // Generate a unique ID

        final newTask = Task(
          id: taskId,
          assignedToUserId: _selectedWorker!.id,
          assignedToUserName:
              _selectedWorker!.displayName ?? _selectedWorker!.email,
          assignedByUserId: _currentManager!.id,
          assignedByUserName:
              _currentManager!.displayName ?? _currentManager!.email,
          lineName: _selectedLine!.name,
          targetTowerRange: _targetTowerRangeController.text.trim(),
          dueDate: _selectedDueDate!,
          createdAt: DateTime.now(),
          status: 'Pending', // Default status for new tasks
        );

        await _taskService.createTask(newTask);

        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'Task assigned successfully!');
          Navigator.of(context)
              .pop(true); // Go back to RealTimeTasksScreen and indicate success
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Error assigning task: ${e.toString()}',
              isError: true);
        }
        print('Error assigning task: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isAssigning = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assign New Task')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // This check is important as _currentManager might be null if user profile is incomplete or network issue
    if (_currentManager == null ||
        _workers.isEmpty ||
        _transmissionLines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assign New Task')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber,
                    size: 60, color: colorScheme.tertiary),
                const SizedBox(height: 20),
                Text(
                  'Cannot assign tasks at this time.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: colorScheme.onSurface),
                ),
                const SizedBox(height: 10),
                Text(
                  'Possible reasons: \n- Your manager profile is incomplete. \n- No worker accounts found. \n- No transmission lines loaded.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadInitialData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Loading Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign New Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign a new patrolling task to a worker.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Worker Selection Dropdown
              DropdownButtonFormField<UserProfile>(
                value: _selectedWorker,
                decoration: InputDecoration(
                  labelText: 'Assign to Worker',
                  prefixIcon: Icon(Icons.person, color: colorScheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                hint: const Text('Select a worker'),
                isExpanded:
                    true, // Crucial for dropdown to take available width
                items: _workers.map((worker) {
                  return DropdownMenuItem(
                    value: worker,
                    child: Text(
                      worker.displayName ?? worker.email,
                      overflow:
                          TextOverflow.ellipsis, // NEW: Prevent text overflow
                      maxLines: 1, // NEW: Restrict to single line
                    ),
                  );
                }).toList(),
                onChanged: (UserProfile? newValue) {
                  setState(() {
                    _selectedWorker = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a worker' : null,
              ),
              const SizedBox(height: 20),

              // Transmission Line Selection Dropdown
              DropdownButtonFormField<TransmissionLine>(
                value: _selectedLine,
                decoration: InputDecoration(
                  labelText: 'Transmission Line',
                  prefixIcon: Icon(Icons.line_axis, color: colorScheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                hint: const Text('Select a transmission line'),
                isExpanded:
                    true, // Crucial for dropdown to take available width
                items: _transmissionLines.map((line) {
                  return DropdownMenuItem(
                    value: line,
                    child: Text(
                      line.name,
                      overflow:
                          TextOverflow.ellipsis, // NEW: Prevent text overflow
                      maxLines: 1, // NEW: Restrict to single line
                    ),
                  );
                }).toList(),
                onChanged: (TransmissionLine? newValue) {
                  setState(() {
                    _selectedLine = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a line' : null,
              ),
              const SizedBox(height: 20),

              // Target Tower Range Input
              TextFormField(
                controller: _targetTowerRangeController,
                decoration: InputDecoration(
                  labelText: 'Target Tower Range (e.g., 10-30, 15, All)',
                  prefixIcon: Icon(Icons.format_list_numbered,
                      color: colorScheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter target towers (e.g., 10-30, All)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Due Date Picker
              InkWell(
                onTap: () => _selectDueDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Due Date',
                    prefixIcon:
                        Icon(Icons.calendar_today, color: colorScheme.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: Icon(Icons.arrow_drop_down,
                        color: colorScheme.onSurface),
                  ),
                  child: Text(
                    _selectedDueDate == null
                        ? 'Select Due Date'
                        : '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Assign Task Button
              _isAssigning
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.secondary),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _assignTask,
                      icon: const Icon(Icons.assignment_add),
                      label: const Text('Assign Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
