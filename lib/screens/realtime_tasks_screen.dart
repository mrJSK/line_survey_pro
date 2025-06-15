// lib/screens/realtime_tasks_screen.dart
// This screen displays assigned tasks for workers and provides a task assignment interface for managers.
// For workers, it also shows a log of their completed surveys under task headers.

import 'package:flutter/material.dart'; // Required for Flutter UI components
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Utility for showing Snackbars
import 'package:line_survey_pro/models/task.dart'; // Import the Task model
import 'package:line_survey_pro/models/user_profile.dart'; // Import the UserProfile model
import 'package:line_survey_pro/models/survey_record.dart'; // Import SurveyRecord model

import 'package:line_survey_pro/services/auth_service.dart'; // Service for authentication and user profiles
import 'package:line_survey_pro/services/task_service.dart'; // Service for task management
import 'package:line_survey_pro/services/local_database_service.dart'; // Local database service (for deleting local records)
import 'package:line_survey_pro/services/survey_firestore_service.dart'; // Service for survey records in Firestore
import 'package:line_survey_pro/screens/assign_task_screen.dart'; // AssignTaskScreen
import 'package:line_survey_pro/screens/line_detail_screen.dart'; // LineDetailScreen (for survey entry)

import 'dart:async'; // For StreamSubscription

// lib/screens/realtime_tasks_screen.dart
// ... (imports)

class RealTimeTasksScreen extends StatefulWidget {
  const RealTimeTasksScreen({super.key});

  @override
  State<RealTimeTasksScreen> createState() => _RealTimeTasksScreenState();
}

class _RealTimeTasksScreenState extends State<RealTimeTasksScreen> {
  UserProfile? _currentUser;
  List<Task> _tasks = [];
  bool _isLoading = true;
  Map<String, List<SurveyRecord>> _surveyRecordsByTask =
      {}; // Grouped survey records for display

  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();
  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService();

  StreamSubscription? _tasksSubscription;
  StreamSubscription?
      _firestoreSurveyRecordsSubscription; // Renamed for clarity
  StreamSubscription?
      _localSurveyRecordsSubscription; // NEW: Subscription for local DB changes

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _firestoreSurveyRecordsSubscription?.cancel();
    _localSurveyRecordsSubscription
        ?.cancel(); // NEW: Cancel local DB subscription
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      _currentUser = await _authService.getCurrentUserProfile();

      if (_currentUser == null) {
        _tasks = [];
        _surveyRecordsByTask = {};
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'User profile not found. Please log in again.',
              isError: true);
        }
        return;
      }

      _tasksSubscription?.cancel();
      _firestoreSurveyRecordsSubscription?.cancel();
      _localSurveyRecordsSubscription?.cancel(); // Cancel local DB stream

      if (_currentUser!.role == 'Worker') {
        _tasksSubscription = _taskService
            .streamTasksForUser(_currentUser!.id)
            .listen((tasks) async {
          if (mounted) {
            _tasks = tasks;
            _updateSurveyRecordsForWorkerTasks(); // Re-process survey records based on new tasks
          }
        }, onError: (e) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
                context, 'Error streaming your tasks: ${e.toString()}',
                isError: true);
          }
          print('RealTimeTasksScreen Worker tasks stream error: $e');
        });

        // Listen to YOUR OWN survey records from Firestore
        _firestoreSurveyRecordsSubscription = _surveyFirestoreService
            .streamSurveyRecordsForUser(_currentUser!.id)
            .listen((records) {
          if (mounted) {
            _updateSurveyRecordsForWorkerTasks(
                firestoreRecords:
                    records); // Trigger update with new Firestore records
          }
        }, onError: (e) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
                context, 'Error streaming your survey records: ${e.toString()}',
                isError: true);
          }
          print('RealTimeTasksScreen Worker survey records stream error: $e');
        });

        // Listen to ALL local survey records (for instant UI update on local saves)
        _localSurveyRecordsSubscription =
            _localDatabaseService.getAllSurveyRecordsStream().listen((records) {
          if (mounted) {
            _updateSurveyRecordsForWorkerTasks(
                localRecords: records); // Trigger update with new local records
          }
        }, onError: (e) {
          if (mounted) {
            SnackBarUtils.showSnackBar(context,
                'Error streaming local survey records: ${e.toString()}',
                isError: true);
          }
          print(
              'RealTimeTasksScreen Worker local survey records stream error: $e');
        });
      } else if (_currentUser!.role == 'Manager') {
        _tasksSubscription = _taskService.streamAllTasks().listen((tasks) {
          if (mounted) {
            _tasks = tasks;
            _updateSurveyRecordsForManagerTasks();
          }
        }, onError: (e) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
                context, 'Error streaming all tasks: ${e.toString()}',
                isError: true);
          }
          print('RealTimeTasksScreen Manager tasks stream error: $e');
        });

        _firestoreSurveyRecordsSubscription =
            _surveyFirestoreService.streamAllSurveyRecords().listen((records) {
          if (mounted) {
            _updateSurveyRecordsForManagerTasks(firestoreRecords: records);
          }
        }, onError: (e) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
                context, 'Error streaming all survey records: ${e.toString()}',
                isError: true);
          }
          print('RealTimeTasksScreen Manager survey records stream error: $e');
        });
      } else {
        _tasks = [];
        _surveyRecordsByTask = {};
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'User role not recognized or assigned.',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error loading initial data: ${e.toString()}',
            isError: true);
      }
      print('RealTimeTasksScreen _loadAllData error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to update and group worker's survey records
  void _updateSurveyRecordsForWorkerTasks(
      {List<SurveyRecord>? firestoreRecords,
      List<SurveyRecord>? localRecords}) async {
    if (!mounted) return;

    // Use latest streamed data, or current state if argument is null
    final currentFirestoreRecords = firestoreRecords ??
        _surveyRecordsByTask.values
            .expand((list) => list)
            .where((r) => r.status == 'uploaded')
            .toList();
    final currentLocalRecords =
        localRecords ?? (await _localDatabaseService.getAllSurveyRecords());

    // Combine local and Firestore records for comprehensive display in logs
    Map<String, SurveyRecord> combinedRecordsMap = {};

    // 1. Add all local records to the map. These will have photoPaths and 'saved' status initially.
    for (var record in currentLocalRecords) {
      combinedRecordsMap[record.id] = record;
    }

    // 2. Overlay with Firestore records. Firestore status takes precedence.
    for (var fRecord in currentFirestoreRecords) {
      final localMatch = combinedRecordsMap[fRecord.id];
      if (localMatch != null) {
        // Record exists both locally and in Firestore. Prioritize Firestore's status.
        combinedRecordsMap[fRecord.id] =
            localMatch.copyWith(status: fRecord.status);
      } else {
        // Record is in Firestore but not local. Add it (photoPath will be empty from Firestore).
        combinedRecordsMap[fRecord.id] = fRecord;
      }
    }

    final List<SurveyRecord> combinedAndFilteredRecords = combinedRecordsMap
        .values
        .where((record) =>
            record.userId == _currentUser!.id) // Filter by current user
        .toList();

    final List<Task> enrichedTasks = [];
    for (var task in _tasks) {
      Set<int> uniqueLocalTowers = {};
      Set<int> uniqueUploadedTowers = {};

      for (var record
          in combinedAndFilteredRecords.where((r) => r.taskId == task.id)) {
        uniqueLocalTowers.add(record.towerNumber);
        if (record.status == 'uploaded') {
          uniqueUploadedTowers.add(record.towerNumber);
        }
      }

      enrichedTasks.add(task.copyWith(
        localCompletedCount: uniqueLocalTowers.length,
        uploadedCompletedCount: uniqueUploadedTowers.length,
      ));
    }

    setState(() {
      _tasks = enrichedTasks;
      _surveyRecordsByTask =
          _groupRecordsByTaskHelper(combinedAndFilteredRecords, enrichedTasks);
    });
  }

  // Helper method to update and group manager's survey records
  void _updateSurveyRecordsForManagerTasks(
      {List<SurveyRecord>? firestoreRecords}) {
    if (!mounted) return;
    // Managers only care about records in Firestore
    final recordsFromFirestore = firestoreRecords ??
        _surveyRecordsByTask.values.expand((list) => list).toList();

    final List<Task> enrichedTasks = [];
    for (var task in _tasks) {
      Set<int> uniqueUploadedTowers = {};

      for (var record in recordsFromFirestore
          .where((r) => r.taskId == task.id && r.status == 'uploaded')) {
        uniqueUploadedTowers.add(record.towerNumber);
      }
      enrichedTasks.add(task.copyWith(
        uploadedCompletedCount: uniqueUploadedTowers.length,
      ));
    }
    setState(() {
      _tasks = enrichedTasks;
      _surveyRecordsByTask =
          _groupRecordsByTaskHelper(recordsFromFirestore, enrichedTasks);
    });
  }

  Map<String, List<SurveyRecord>> _groupRecordsByTaskHelper(
      List<SurveyRecord> records, List<Task> tasks) {
    final Map<String, List<SurveyRecord>> grouped = {};
    for (var task in tasks) {
      grouped[task.id] = [];
    }

    for (var record in records) {
      if (record.taskId != null && grouped.containsKey(record.taskId)) {
        grouped[record.taskId]!.add(record);
      }
    }
    grouped.forEach((key, value) {
      value.sort((a, b) {
        final towerComparison = a.towerNumber.compareTo(b.towerNumber);
        if (towerComparison != 0) return towerComparison;
        return a.timestamp.compareTo(b.timestamp);
      });
    });
    return grouped;
  }

  void _assignNewTask() async {
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AssignTaskScreen()),
      );
    }
  }

  void _editTask(Task task) async {
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AssignTaskScreen(taskToEdit: task),
        ),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text(
                  'Are you sure you want to delete the task for Line: ${task.lineName}, Towers: ${task.targetTowerRange}? This will also delete any associated survey progress in the app for this task. This action cannot be undone.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _taskService.deleteTask(task.id);
        await _surveyFirestoreService.deleteSurveyRecordsByTaskId(task.id);
        await _localDatabaseService.deleteSurveyRecordsByTaskId(task.id);

        if (mounted)
          SnackBarUtils.showSnackBar(context,
              'Task and associated local records deleted successfully!');
      } catch (e) {
        if (mounted)
          SnackBarUtils.showSnackBar(
              context, 'Error deleting task: ${e.toString()}',
              isError: true);
        print('Error deleting task: $e');
      } finally {
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      }
    }
  }

  void _showManagerTaskOptions(Task task) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Task'),
                onTap: () {
                  Navigator.pop(bc);
                  _editTask(task);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Task'),
                onTap: () {
                  Navigator.pop(bc);
                  _deleteTask(task);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateTaskStatus(Task task, String newStatus) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _taskService.updateTaskStatus(task.id, newStatus);
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Task status updated!');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error updating task: ${e.toString()}',
            isError: true);
      }
      print('RealTimeTasksScreen Task status update error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSurveyForTask(Task task) {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LineDetailScreen(task: task),
        ),
      );
    }
  }

  Future<void> _uploadUnsyncedRecords() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final List<SurveyRecord> unsyncedRecords =
          await _localDatabaseService.getUnsyncedSurveyRecords();

      if (unsyncedRecords.isEmpty) {
        if (mounted)
          SnackBarUtils.showSnackBar(context, 'No unsynced records to upload.',
              isError: false);
        return;
      }

      int uploadedCount = 0;
      for (final record in unsyncedRecords) {
        final String? uploadedRecordId =
            await _surveyFirestoreService.uploadSurveyRecordDetails(record);
        if (uploadedRecordId != null) {
          uploadedCount++;
          await _localDatabaseService.updateSurveyRecordStatus(
              record.id, 'uploaded');
        }
      }

      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, '$uploadedCount record details uploaded successfully!',
            isError: false);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error uploading unsynced records: ${e.toString()}',
            isError: true);
      }
      print('Upload unsynced records error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentUser == null) {
      return Center(
        child: Text(
          'Please log in to view tasks.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    if (_currentUser!.role == null ||
        (_currentUser!.role != 'Worker' && _currentUser!.role != 'Manager')) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: colorScheme.error),
              const SizedBox(height: 20),
              Text(
                'Your account role is not assigned or recognized.',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Please ensure your role is correctly assigned by an administrator in the Firebase Console.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Welcome, ${_currentUser!.displayName ?? _currentUser!.email} (${_currentUser!.role})!', // Removed span tags
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: colorScheme.primary),
            textAlign: TextAlign.center,
          ),
        ),
        if (_currentUser!.role == 'Manager')
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _assignNewTask,
              icon: const Icon(Icons.add_task),
              label: const Text('Assign New Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        if (_currentUser!.role == 'Worker')
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _uploadUnsyncedRecords,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload Unsynced Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          _currentUser!.role == 'Worker'
              ? 'Your Assigned Tasks:'
              : 'All Tasks:',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _tasks.isEmpty
              ? Center(
                  child: Text(
                    _currentUser!.role == 'Worker'
                        ? 'No tasks assigned to you yet.'
                        : 'No tasks available.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    final recordsForTask = _surveyRecordsByTask[task.id] ?? [];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 3,
                      child: ExpansionTile(
                        title: Text(
                            'Task: ${task.lineName} - Towers: ${task.targetTowerRange} (${task.numberOfTowersToPatrol} to patrol)'), // Removed span tags
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Due: ${task.dueDate.toLocal().toString().split(' ')[0]}'),
                            Text('Status: ${task.derivedStatus}'),
                            if (_currentUser!.role == 'Manager')
                              Text(
                                  'Assigned to: ${task.assignedToUserName ?? 'N/A'}'),
                          ],
                        ),
                        trailing: _currentUser!.role == 'Manager'
                            ? IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showManagerTaskOptions(task),
                                tooltip: 'Task Options',
                              )
                            : (_currentUser!.role == 'Worker' &&
                                    task.status !=
                                        'Completed' && // Original Firestore status
                                    task.localCompletedCount >
                                        0 && // Has some local progress
                                    task.derivedStatus !=
                                        'Completed' // Not yet derived as completed
                                ? IconButton(
                                    icon: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    onPressed: () =>
                                        _updateTaskStatus(task, 'Completed'),
                                    tooltip: 'Mark as Completed',
                                  )
                                : null),
                        children: [
                          if (_currentUser!.role == 'Worker')
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Completed: ${task.localCompletedCount} / ${task.numberOfTowersToPatrol} (Local)',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    'Uploaded: ${task.uploadedCompletedCount} / ${task.numberOfTowersToPatrol} (Cloud)',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Your Survey Log for this Task:',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  recordsForTask.isEmpty
                                      ? Text(
                                          'No surveys recorded for this task yet.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  fontStyle: FontStyle.italic))
                                      : Column(
                                          children: recordsForTask
                                              .map((record) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 4.0),
                                                    child: Text(
                                                      ' • Tower ${record.towerNumber} at ${record.timestamp.toLocal().toString().split('.')[0]} (Status: ${record.status})',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall,
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _navigateToSurveyForTask(task),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text(
                                        'Continue Survey for this Task'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          colorScheme.primary.withOpacity(0.8),
                                      foregroundColor: colorScheme.onPrimary,
                                      minimumSize:
                                          const Size(double.infinity, 40),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
