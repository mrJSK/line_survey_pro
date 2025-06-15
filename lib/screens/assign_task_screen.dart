// lib/screens/assign_task_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/task.dart';
import 'package:line_survey_pro/models/user_profile.dart';
import 'package:line_survey_pro/models/transmission_line.dart';
import 'package:line_survey_pro/services/auth_service.dart';
import 'package:line_survey_pro/services/task_service.dart';
import 'package:line_survey_pro/services/firestore_service.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

class AssignTaskScreen extends StatefulWidget {
  final Task? taskToEdit;

  const AssignTaskScreen({
    super.key,
    this.taskToEdit,
  });

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  // Replaced _targetTowerRangeController
  final TextEditingController _fromTowerController = TextEditingController();
  final TextEditingController _toTowerController = TextEditingController();

  UserProfile? _selectedWorker;
  TransmissionLine? _selectedLine;
  DateTime? _selectedDueDate;

  List<UserProfile> _workers = [];
  List<TransmissionLine> _transmissionLines = [];
  UserProfile? _currentManager;

  bool _isLoading = true;
  bool _isAssigning = false;

  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // If editing an existing task, populate fields
    if (widget.taskToEdit != null) {
      // Parse the targetTowerRange string (e.g., "10-30") to populate From/To fields
      _selectedDueDate = widget.taskToEdit!.dueDate;

      final range = widget.taskToEdit!.targetTowerRange.trim();
      if (range.contains('-')) {
        final parts = range.split('-');
        if (parts.length == 2) {
          _fromTowerController.text = parts[0].trim();
          _toTowerController.text = parts[1].trim();
        }
      } else if (int.tryParse(range) != null) {
        // Single tower case
        _fromTowerController.text = range;
        _toTowerController.text = range;
      }
      // If "All" or complex, manager has to re-enter
    }
  }

  @override
  void dispose() {
    _fromTowerController.dispose();
    _toTowerController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _currentManager = await _authService.getCurrentUserProfile();

      final allUsers = await _authService.getAllUserProfiles();
      _workers = allUsers.where((user) => user.role == 'Worker').toList();

      _transmissionLines = await _firestoreService.getTransmissionLinesOnce();

      // If editing, find the selected worker and line from loaded data
      if (widget.taskToEdit != null) {
        _selectedWorker = _workers.firstWhereOrNull(// Use firstWhereOrNull
            (worker) => worker.id == widget.taskToEdit!.assignedToUserId);
        _selectedLine =
            _transmissionLines.firstWhereOrNull(// Use firstWhereOrNull
                (line) => line.name == widget.taskToEdit!.lineName);

        // Handle cases where worker or line from taskToEdit might not be found
        if (_selectedWorker == null && _workers.isNotEmpty)
          _selectedWorker = _workers.first;
        if (_selectedLine == null && _transmissionLines.isNotEmpty)
          _selectedLine = _transmissionLines.first;
      } else {
        // For new task, pre-select first worker/line if available
        if (_workers.isNotEmpty) _selectedWorker = _workers.first;
        if (_transmissionLines.isNotEmpty)
          _selectedLine = _transmissionLines.first;
      }
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
      initialDate:
          _selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _assignOrUpdateTask() async {
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
        final String taskId = widget.taskToEdit?.id ?? _uuid.v4();

        // New logic for targetTowerRange and numberOfTowersToPatrol
        final String targetRangeString;
        final int numberOfTowers;

        final int? fromTower = int.tryParse(_fromTowerController.text.trim());
        final int? toTower = int.tryParse(_toTowerController.text.trim());

        if (fromTower != null && toTower != null && fromTower <= toTower) {
          targetRangeString = '$fromTower-$toTower';
          numberOfTowers = toTower - fromTower + 1;
        } else if (fromTower != null &&
            _toTowerController.text.trim().isEmpty) {
          // Single tower case
          targetRangeString = fromTower.toString();
          numberOfTowers = 1;
        } else if (_fromTowerController.text.trim().toLowerCase() == 'all' &&
            _toTowerController.text.trim().isEmpty) {
          targetRangeString = 'All';
          numberOfTowers = _selectedLine?.totalTowers ??
              0; // Use totalTowers from the selected line
        } else {
          // This case should ideally be caught by validator, but as a fallback
          if (mounted) {
            SnackBarUtils.showSnackBar(
                context, 'Invalid tower range. Please check From/To values.',
                isError: true);
          }
          return;
        }

        if (numberOfTowers == 0 && targetRangeString.toLowerCase() != 'all') {
          // If it's "All" and totalTowers is 0, allow.
          if (mounted) {
            SnackBarUtils.showSnackBar(context,
                'Number of towers to patrol cannot be zero. Check range or line total towers.',
                isError: true);
          }
          return;
        }

        final Task task = Task(
          id: taskId,
          assignedToUserId: _selectedWorker!.id,
          assignedToUserName:
              _selectedWorker!.displayName ?? _selectedWorker!.email,
          assignedByUserId: _currentManager!.id,
          assignedByUserName:
              _currentManager!.displayName ?? _currentManager!.email,
          lineName: _selectedLine!.name,
          targetTowerRange: targetRangeString, // Use the new string format
          numberOfTowersToPatrol: numberOfTowers, // Use the calculated number
          dueDate: _selectedDueDate!,
          createdAt: widget.taskToEdit?.createdAt ?? DateTime.now(),
          status: widget.taskToEdit?.status ?? 'Pending',
          completionDate: widget.taskToEdit?.completionDate,
          reviewNotes: widget.taskToEdit?.reviewNotes,
          associatedSurveyRecordIds:
              widget.taskToEdit?.associatedSurveyRecordIds ?? [],
        );

        if (widget.taskToEdit == null) {
          await _taskService.createTask(task);
          if (mounted)
            SnackBarUtils.showSnackBar(context, 'Task assigned successfully!');
        } else {
          await _taskService.updateTask(task);
          if (mounted)
            SnackBarUtils.showSnackBar(context, 'Task updated successfully!');
        }

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Error saving task: ${e.toString()}',
              isError: true);
        }
        print('Error saving task: $e');
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
        appBar: AppBar(
            title: Text(
                widget.taskToEdit == null ? 'Assign New Task' : 'Edit Task')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentManager == null ||
        _workers.isEmpty ||
        _transmissionLines.isEmpty) {
      return Scaffold(
        appBar: AppBar(
            title: Text(
                widget.taskToEdit == null ? 'Assign New Task' : 'Edit Task')),
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
                  'Cannot ${widget.taskToEdit == null ? 'assign' : 'edit'} tasks at this time.',
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
        title:
            Text(widget.taskToEdit == null ? 'Assign New Task' : 'Edit Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.taskToEdit == null
                    ? 'Assign a new patrolling task to a worker.'
                    : 'Edit the details of this task.',
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
                isExpanded: true,
                items: _workers.map((worker) {
                  return DropdownMenuItem(
                    value: worker,
                    child: Text(
                      worker.displayName ?? worker.email,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
                isExpanded: true,
                items: _transmissionLines.map((line) {
                  return DropdownMenuItem(
                    value: line,
                    child: Text(
                      line.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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

              // NEW: From Tower Input
              TextFormField(
                controller: _fromTowerController,
                decoration: InputDecoration(
                  labelText: 'From Tower Number (e.g., 10)',
                  prefixIcon:
                      Icon(Icons.arrow_right_alt, color: colorScheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a "From" tower number or "All"';
                  }
                  if (value.trim().toLowerCase() == 'all')
                    return null; // "All" is valid

                  final int? num = int.tryParse(value.trim());
                  if (num == null || num <= 0) {
                    return 'Must be a positive number or "All"';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // NEW: To Tower Input
              TextFormField(
                controller: _toTowerController,
                decoration: InputDecoration(
                  labelText:
                      'To Tower Number (e.g., 30, leave empty for single tower)',
                  prefixIcon:
                      Icon(Icons.arrow_left, color: colorScheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final String fromText = _fromTowerController.text.trim();
                  if (fromText.toLowerCase() == 'all')
                    return null; // If "All", no "To" needed

                  final int? fromNum = int.tryParse(fromText);
                  if (fromNum == null)
                    return null; // If From is invalid, this field is not responsible

                  if (value == null || value.trim().isEmpty) {
                    // If "To" is empty, it implies a single tower (From)
                    return null;
                  }

                  final int? toNum = int.tryParse(value.trim());
                  if (toNum == null || toNum <= 0) {
                    return 'Must be a positive number or empty for single tower';
                  }

                  if (fromNum > toNum) {
                    return '"From" tower cannot be greater than "To" tower';
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
                      onPressed: _assignOrUpdateTask,
                      icon: Icon(widget.taskToEdit == null
                          ? Icons.assignment_add
                          : Icons.save),
                      label: Text(widget.taskToEdit == null
                          ? 'Assign Task'
                          : 'Save Changes'),
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
