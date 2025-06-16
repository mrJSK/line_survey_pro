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
  final TextEditingController _fromTowerController = TextEditingController();
  final TextEditingController _toTowerController = TextEditingController();

  UserProfile? _selectedWorker;
  TransmissionLine? _selectedLine;
  DateTime? _selectedDueDate;

  List<UserProfile> _workers = [];
  List<TransmissionLine> _transmissionLines = [];
  UserProfile?
      _currentManager; // Will also hold Admin profile if Admin is logged in

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
    if (widget.taskToEdit != null) {
      _selectedDueDate = widget.taskToEdit!.dueDate;

      final range = widget.taskToEdit!.targetTowerRange.trim();
      if (range.contains('-')) {
        final parts = range.split('-');
        if (parts.length == 2) {
          _fromTowerController.text = parts[0].trim();
          _toTowerController.text = parts[1].trim();
        }
      } else if (int.tryParse(range) != null) {
        _fromTowerController.text = range;
        _toTowerController.text = range;
      }
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

      List<TransmissionLine> allAvailableLines =
          await _firestoreService.getTransmissionLinesOnce();

      // NEW: Filter lines based on manager's assigned lines, unless it's an Admin
      if (_currentManager!.role == 'Manager') {
        _transmissionLines = allAvailableLines
            .where((line) => _currentManager!.assignedLineIds.contains(line.id))
            .toList();
      } else {
        // Admin can see and assign all lines
        _transmissionLines = allAvailableLines;
      }

      if (widget.taskToEdit != null) {
        _selectedWorker = _workers.firstWhereOrNull(
            (worker) => worker.id == widget.taskToEdit!.assignedToUserId);
        _selectedLine = _transmissionLines.firstWhereOrNull(
            (line) => line.name == widget.taskToEdit!.lineName);

        if (_selectedWorker == null && _workers.isNotEmpty) {
          _selectedWorker = _workers.first;
        }
        if (_selectedLine == null && _transmissionLines.isNotEmpty) {
          _selectedLine = _transmissionLines.first;
        }
      } else {
        if (_workers.isNotEmpty) {
          _selectedWorker = _workers.first;
        }
        if (_transmissionLines.isNotEmpty) {
          _selectedLine = _transmissionLines.first;
        }
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

  // Helper function to parse tower range into a list of integers
  // Returns empty list if "All" or invalid range
  List<int> _parseRangeToTowers(String rangeString) {
    rangeString = rangeString.trim().toLowerCase();
    if (rangeString == 'all') {
      return []; // Special case, implies all towers on the line.
    }

    final List<int> towers = [];
    if (rangeString.contains('-')) {
      final parts = rangeString.split('-');
      if (parts.length == 2) {
        final start = int.tryParse(parts[0].trim());
        final end = int.tryParse(parts[1].trim());
        if (start != null && end != null && start <= end) {
          for (int i = start; i <= end; i++) {
            towers.add(i);
          }
        }
      }
    } else {
      final singleTower = int.tryParse(rangeString);
      if (singleTower != null) {
        towers.add(singleTower);
      }
    }
    return towers;
  }

  // Helper to check for overlapping ranges
  bool _doRangesOverlap(String range1, String range2) {
    if (range1.toLowerCase() == 'all' || range2.toLowerCase() == 'all') {
      return true; // "All" always conflicts with anything else.
    }

    final List<int> towers1 = _parseRangeToTowers(range1);
    final List<int> towers2 = _parseRangeToTowers(range2);

    if (towers1.isEmpty || towers2.isEmpty) {
      return false; // Cannot determine overlap for invalid ranges
    }

    // Find min and max for each range
    final int min1 = towers1.reduce((a, b) => a < b ? a : b);
    final int max1 = towers1.reduce((a, b) => a > b ? a : b);
    final int min2 = towers2.reduce((a, b) => a < b ? a : b);
    final int max2 = towers2.reduce((a, b) => a > b ? a : b);

    // Check for overlap: [min1, max1] overlaps [min2, max2] if max1 >= min2 AND max2 >= min1
    return max1 >= min2 && max2 >= min1;
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

      final String targetRangeString;
      final int numberOfTowers;

      final String fromText = _fromTowerController.text.trim();
      final String toText = _toTowerController.text.trim();

      if (fromText.toLowerCase() == 'all' && toText.isEmpty) {
        targetRangeString = 'All';
        // Use computedTotalTowers from selectedLine
        numberOfTowers = _selectedLine?.computedTotalTowers ?? 0;
      } else {
        final int? fromTower = int.tryParse(fromText);
        final int? toTower = int.tryParse(toText.isEmpty ? fromText : toText);
        if (fromTower != null && toTower != null && fromTower <= toTower) {
          targetRangeString = (fromTower == toTower)
              ? fromTower.toString()
              : '$fromTower-$toTower';
          numberOfTowers = toTower - fromTower + 1;
        } else {
          SnackBarUtils.showSnackBar(
              context, 'Invalid tower range. Please check From/To values.',
              isError: true);
          return;
        }
      }

      if (numberOfTowers <= 0 && targetRangeString.toLowerCase() != 'all') {
        SnackBarUtils.showSnackBar(context,
            'Number of towers to patrol cannot be zero. Check range or line total towers if "All" is selected.',
            isError: true);
        return;
      }

      // --- NEW VALIDATION: Check that sum of assigned towers doesn't exceed total towers in line ---
      // This applies to the *selected line*, not just this specific task.
      // We need to sum up all currently assigned towers for this line, then add the current task's towers.
      // This is a complex check because 'All' implies the line's total towers.
      int currentlyAssignedTowersForThisLine = 0;
      final List<Task> allTasksForSelectedLine =
          (await _taskService.getAllTasks())
              .where((task) =>
                  task.lineName == _selectedLine!.name &&
                  task.id !=
                      widget.taskToEdit?.id) // Exclude current task if editing
              .toList();

      for (var task in allTasksForSelectedLine) {
        if (task.targetTowerRange.toLowerCase() == 'all') {
          currentlyAssignedTowersForThisLine +=
              _selectedLine!.computedTotalTowers;
        } else {
          final List<int> towersInTask =
              _parseRangeToTowers(task.targetTowerRange);
          if (towersInTask.isNotEmpty) {
            currentlyAssignedTowersForThisLine += towersInTask.length;
          }
        }
      }

      final int totalTowersToBeAssignedIncludingThis =
          currentlyAssignedTowersForThisLine + numberOfTowers;
      final int lineTotalTowers = _selectedLine!.computedTotalTowers;

      if (totalTowersToBeAssignedIncludingThis > lineTotalTowers) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'The total number of towers assigned to this line (${totalTowersToBeAssignedIncludingThis}) exceeds the line\'s total towers (${lineTotalTowers}). Please adjust the range.',
            isError: true,
          );
        }
        setState(() {
          _isAssigning = false;
        });
        return;
      }
      // --- END NEW VALIDATION ---

      // --- NEW VALIDATION: Check for conflicting incomplete tasks ---
      if (widget.taskToEdit == null) {
        // Only for new task creation
        final existingTasks = await _taskService
            .getTasksForUser(_selectedWorker!.id); // Get worker's tasks

        for (var existingTask in existingTasks) {
          // If the existing task is not 'Completed'
          // And if it's for the same line
          // And if the tower ranges overlap
          if (existingTask.status !=
                  'Completed' && // Use actual Firestore status to determine if incomplete
              existingTask.lineName == _selectedLine!.name &&
              _doRangesOverlap(
                  targetRangeString, existingTask.targetTowerRange)) {
            if (mounted) {
              SnackBarUtils.showSnackBar(
                context,
                'Conflict: Worker already has an incomplete task (${existingTask.lineName}, Towers: ${existingTask.targetTowerRange}, Status: ${existingTask.status}) that overlaps with this assignment. Please complete/resolve the existing task first.',
                isError: true,
              );
            }
            return; // Prevent assignment due to conflict
          }
        }
      }
      // --- END NEW VALIDATION ---

      setState(() {
        _isAssigning = true;
      });

      try {
        final String taskId = widget.taskToEdit?.id ?? _uuid.v4();

        final Task task = Task(
          id: taskId,
          assignedToUserId: _selectedWorker!.id,
          assignedToUserName:
              _selectedWorker!.displayName ?? _selectedWorker!.email,
          assignedByUserId: _currentManager!.id,
          assignedByUserName:
              _currentManager!.displayName ?? _currentManager!.email,
          lineName: _selectedLine!.name,
          targetTowerRange: targetRangeString,
          numberOfTowersToPatrol: numberOfTowers,
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
        // _currentManager!.status != 'approved' || // Ensure manager is approved (removed, as 'status' is not defined)
        (_currentManager!.role != 'Manager' &&
            _currentManager!.role != 'Admin') || // Must be manager or admin
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
                  'Possible reasons: \n- Your account is not approved or you lack Manager/Admin role. \n- No worker accounts found. \n- No transmission lines loaded (or assigned to you if you are a Manager). (Add/Manage lines from "Manage Lines" in drawer)',
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
                      line.name, // Display consolidated name
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (TransmissionLine? newValue) {
                  setState(() {
                    _selectedLine = newValue;
                    // If a line is selected, pre-fill tower range if available
                    if (newValue != null) {
                      _fromTowerController.text =
                          newValue.towerRangeStart?.toString() ?? '';
                      _toTowerController.text =
                          newValue.towerRangeEnd?.toString() ?? '';
                    } else {
                      _fromTowerController.clear();
                      _toTowerController.clear();
                    }
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a line' : null,
              ),
              const SizedBox(height: 20),

              // From Tower Input
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
                  if (value.trim().toLowerCase() == 'all') {
                    if (_selectedLine == null ||
                        _selectedLine!.computedTotalTowers <= 0) {
                      return '"All" requires a selected line with defined towers.';
                    }
                    return null; // "All" is valid if line selected
                  }

                  final int? num = int.tryParse(value.trim());
                  if (num == null || num <= 0) {
                    return 'Must be a positive number or "All"';
                  }
                  // Validate against selected line's range
                  if (_selectedLine != null &&
                      (_selectedLine!.towerRangeStart != null &&
                          _selectedLine!.towerRangeEnd != null)) {
                    if (num < _selectedLine!.towerRangeStart! ||
                        num > _selectedLine!.towerRangeEnd!) {
                      return 'Must be within line\'s range (${_selectedLine!.towerRangeStart}-${_selectedLine!.towerRangeEnd})';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // To Tower Input
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
                    return null; // If From is 'All', To is irrelevant

                  final int? fromNum = int.tryParse(fromText);
                  if (fromNum == null)
                    return null; // If From is invalid, this field is not responsible

                  if (value == null || value.trim().isEmpty) {
                    return null; // If "To" is empty, it implies a single tower (From)
                  }

                  final int? toNum = int.tryParse(value.trim());
                  if (toNum == null || toNum <= 0) {
                    return 'Must be a positive number or empty for single tower';
                  }

                  if (fromNum > toNum) {
                    return '"From" tower cannot be greater than "To" tower';
                  }
                  // Validate against selected line's range
                  if (_selectedLine != null &&
                      (_selectedLine!.towerRangeStart != null &&
                          _selectedLine!.towerRangeEnd != null)) {
                    if (toNum < _selectedLine!.towerRangeStart! ||
                        toNum > _selectedLine!.towerRangeEnd!) {
                      return 'Must be within line\'s range (${_selectedLine!.towerRangeStart}-${_selectedLine!.towerRangeEnd})';
                    }
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
