// lib/screens/realtime_tasks_screen.dart
// This screen displays assigned tasks for workers and provides a task assignment interface for managers.
// For workers, it also shows a log of their completed surveys under task headers.

import 'package:flutter/material.dart'; // Required for Flutter UI components
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Utility for showing Snackbars
import 'package:line_survey_pro/models/task.dart'; // Import the Task model
import 'package:line_survey_pro/models/user_profile.dart'; // Import the UserProfile model
import 'package:line_survey_pro/models/survey_record.dart'; // Import SurveyRecord model
import 'package:line_survey_pro/models/transmission_line.dart'; // NEW: For filtering lines

import 'package:line_survey_pro/services/auth_service.dart'; // Service for authentication and user profiles
import 'package:line_survey_pro/services/task_service.dart'; // Service for task management
import 'package:line_survey_pro/services/local_database_service.dart'; // Local database service (for deleting local records)
import 'package:line_survey_pro/services/survey_firestore_service.dart'; // Service for survey records in Firestore
import 'package:line_survey_pro/services/firestore_service.dart'; // NEW: For fetching transmission lines

import 'package:line_survey_pro/screens/assign_task_screen.dart'; // AssignTaskScreen
import 'package:line_survey_pro/screens/line_detail_screen.dart'; // LineDetailScreen (for survey entry)

import 'dart:async'; // For StreamSubscription
import 'package:collection/collection.dart'
    as collection; // For firstWhereOrNull
import 'package:line_survey_pro/l10n/app_localizations.dart'; // Import AppLocalizations

class RealTimeTasksScreen extends StatefulWidget {
  final UserProfile? currentUserProfile; // NEW: Accept currentUserProfile

  const RealTimeTasksScreen(
      {super.key, required this.currentUserProfile}); // UPDATED Constructor

  @override
  State<RealTimeTasksScreen> createState() => _RealTimeTasksScreenState();
}

class _RealTimeTasksScreenState extends State<RealTimeTasksScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true; // Overall loading flag
  Map<String, List<SurveyRecord>> _surveyRecordsByTask = {};

  List<SurveyRecord> _allLocalSurveyRecords = [];
  List<TransmissionLine> _allTransmissionLines = [];

  // Individual loading flags for each data source
  bool _isLoadingTasks = true;
  bool _isLoadingFirestoreRecords = true;
  bool _isLoadingLocalRecords = true;
  bool _isLoadingTransmissionLines = true;

  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();
  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService();
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription? _tasksSubscription;
  StreamSubscription? _firestoreSurveyRecordsSubscription;
  StreamSubscription? _localSurveyRecordsSubscription;
  StreamSubscription? _transmissionLinesSubscription;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _firestoreSurveyRecordsSubscription?.cancel();
    _localSurveyRecordsSubscription?.cancel();
    _transmissionLinesSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RealTimeTasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUserProfile != oldWidget.currentUserProfile) {
      _loadAllData();
    }
  }

  void _checkOverallLoadingStatus() {
    if (mounted) {
      setState(() {
        _isLoading = _isLoadingTasks ||
            _isLoadingFirestoreRecords ||
            _isLoadingLocalRecords ||
            _isLoadingTransmissionLines;
      });
    }
  }

  Future<void> _loadAllData() async {
    if (!mounted || widget.currentUserProfile == null) {
      return;
    }
    setState(() {
      _isLoading = true; // Start overall loading
      _isLoadingTasks = true;
      _isLoadingFirestoreRecords = true;
      _isLoadingLocalRecords = true;
      _isLoadingTransmissionLines = true;
    });

    // Listen to ALL local survey records (for instant UI update on local saves)
    _localSurveyRecordsSubscription?.cancel();
    _localSurveyRecordsSubscription =
        _localDatabaseService.getAllSurveyRecordsStream().listen((records) {
      if (mounted) {
        setState(() {
          _allLocalSurveyRecords = records;
          _isLoadingLocalRecords = false; // Local records loaded
        });
        _updateSurveyRecordsForWorkerTasks(localRecords: records);
        _checkOverallLoadingStatus();
      }
    }, onError: (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context,
            AppLocalizations.of(context)!.errorStreamingLocalSurveyRecords(
                e.toString()), // Access directly
            isError: true);
        setState(() {
          _isLoadingLocalRecords = false; // Mark as loaded even on error
        });
        _checkOverallLoadingStatus();
      }
      print('RealTimeTasksScreen Worker local survey records stream error: $e');
    });

    // Setup other streams
    _setupDataStreamsBasedOnRole();
  }

  void _setupDataStreamsBasedOnRole() {
    // Stream all transmission lines
    _transmissionLinesSubscription?.cancel();
    _transmissionLinesSubscription =
        _firestoreService.getTransmissionLinesStream().listen((lines) {
      if (mounted) {
        setState(() {
          _allTransmissionLines = lines;
          _isLoadingTransmissionLines = false; // Transmission lines loaded
        });
        _setupDataStreamsBasedOnRoleInner(); // Re-evaluate streams if lines change
        _checkOverallLoadingStatus();
      }
    }, onError: (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context,
            AppLocalizations.of(context)!
                .errorStreamingManagerLines(e.toString()), // Access directly
            isError: true);
        setState(() {
          _isLoadingTransmissionLines = false; // Mark as loaded even on error
        });
        _checkOverallLoadingStatus();
      }
      print('RealTimeTasksScreen transmission lines stream error: $e');
    });

    // Clear existing task and firestore survey records subscriptions if any
    _tasksSubscription?.cancel();
    _firestoreSurveyRecordsSubscription?.cancel();

    if (widget.currentUserProfile == null ||
        widget.currentUserProfile!.status != 'approved') {
      _tasks = [];
      _surveyRecordsByTask = {};
      if (mounted) {
        setState(() {
          _isLoadingTasks = false;
          _isLoadingFirestoreRecords = false;
        });
        _checkOverallLoadingStatus();
      }
      return;
    }
  }

  void _setupDataStreamsBasedOnRoleInner() {
    final UserProfile user = widget.currentUserProfile!;

    // Re-setup tasks and firestore survey streams after transmission lines are loaded
    // Ensure existing subscriptions are cancelled before new ones are created
    _tasksSubscription?.cancel();
    _firestoreSurveyRecordsSubscription?.cancel();

    if (user.role == 'Worker') {
      _tasksSubscription =
          _taskService.streamTasksForUser(user.id).listen((tasks) async {
        if (mounted) {
          setState(() {
            _tasks = tasks;
            _isLoadingTasks = false; // Tasks loaded
          });
          _updateSurveyRecordsForWorkerTasks();
          _checkOverallLoadingStatus();
        }
      }, onError: (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context,
              AppLocalizations.of(context)!
                  .errorStreamingYourTasks(e.toString()), // Access directly
              isError: true);
          setState(() {
            _isLoadingTasks = false; // Mark as loaded even on error
          });
          _checkOverallLoadingStatus();
        }
        print('RealTimeTasksScreen Worker tasks stream error: $e');
      });

      _firestoreSurveyRecordsSubscription = _surveyFirestoreService
          .streamSurveyRecordsForUser(user.id)
          .listen((records) {
        if (mounted) {
          setState(() {
            _isLoadingFirestoreRecords = false; // Firestore records loaded
          });
          _updateSurveyRecordsForWorkerTasks(firestoreRecords: records);
          _checkOverallLoadingStatus();
        }
      }, onError: (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context,
              AppLocalizations.of(context)!.errorStreamingYourSurveyRecords(
                  e.toString()), // Access directly
              isError: true);
          setState(() {
            _isLoadingFirestoreRecords = false; // Mark as loaded even on error
          });
          _checkOverallLoadingStatus();
        }
        print('RealTimeTasksScreen Worker survey records stream error: $e');
      });
    } else if (user.role == 'Manager' || user.role == 'Admin') {
      _tasksSubscription = _taskService.streamAllTasks().listen((tasks) {
        if (mounted) {
          setState(() {
            _isLoadingTasks = false; // Tasks loaded
          });
          if (user.role == 'Manager') {
            _tasks = tasks.where((task) {
              final TransmissionLine? taskLine =
                  collection.IterableExtension<TransmissionLine>(
                          _allTransmissionLines)
                      .firstWhereOrNull(
                (l) => l.name == task.lineName,
              );
              return taskLine != null &&
                  user.assignedLineIds.contains(taskLine.id);
            }).toList();
          } else {
            _tasks = tasks;
          }
          _updateSurveyRecordsForManagerTasks();
          _checkOverallLoadingStatus();
        }
      }, onError: (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context,
              AppLocalizations.of(context)!
                  .errorStreamingAllTasks(e.toString()), // Access directly
              isError: true);
          setState(() {
            _isLoadingTasks = false; // Mark as loaded even on error
          });
          _checkOverallLoadingStatus();
        }
        print('RealTimeTasksScreen Manager/Admin tasks stream error: $e');
      });

      _firestoreSurveyRecordsSubscription =
          _surveyFirestoreService.streamAllSurveyRecords().listen((records) {
        if (mounted) {
          setState(() {
            _isLoadingFirestoreRecords = false; // Firestore records loaded
          });
          if (user.role == 'Manager') {
            final Set<String> assignedLineNames = _allTransmissionLines
                .where((line) => user.assignedLineIds.contains(line.id))
                .map((line) => line.name)
                .toSet();
            _updateSurveyRecordsForManagerTasks(
                firestoreRecords: records
                    .where(
                        (record) => assignedLineNames.contains(record.lineName))
                    .toList());
          } else {
            _updateSurveyRecordsForManagerTasks(firestoreRecords: records);
          }
          _checkOverallLoadingStatus();
        }
      }, onError: (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context,
              AppLocalizations.of(context)!.errorStreamingAllSurveyRecords(
                  e.toString()), // Access directly
              isError: true);
          setState(() {
            _isLoadingFirestoreRecords = false; // Mark as loaded even on error
          });
          _checkOverallLoadingStatus();
        }
        print(
            'RealTimeTasksScreen Manager/Admin survey records stream error: $e');
      });
    } else {
      _tasks = [];
      _surveyRecordsByTask = {};
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context,
            AppLocalizations.of(context)!
                .unassignedRoleTitle, // Access directly
            isError: true);
        setState(() {
          _isLoadingTasks = false;
          _isLoadingFirestoreRecords = false;
        });
        _checkOverallLoadingStatus();
      }
    }
  }

  void _updateSurveyRecordsForWorkerTasks(
      {List<SurveyRecord>? firestoreRecords,
      List<SurveyRecord>? localRecords}) async {
    if (!mounted) return;

    final UserProfile user = widget.currentUserProfile!;

    final currentFirestoreRecords = firestoreRecords ??
        _surveyRecordsByTask.values
            .expand((list) => list)
            .where((r) => r.status == 'uploaded')
            .toList();
    final currentLocalRecords =
        localRecords ?? (await _localDatabaseService.getAllSurveyRecords());

    Map<String, SurveyRecord> combinedRecordsMap = {};

    for (var record in currentLocalRecords) {
      combinedRecordsMap[record.id] = record;
    }

    for (var fRecord in currentFirestoreRecords) {
      final localMatch = combinedRecordsMap[fRecord.id];
      if (localMatch != null) {
        combinedRecordsMap[fRecord.id] =
            localMatch.copyWith(status: fRecord.status);
      } else {
        combinedRecordsMap[fRecord.id] = fRecord;
      }
    }

    final List<SurveyRecord> combinedAndFilteredRecords = combinedRecordsMap
        .values
        .where((record) => record.userId == user.id)
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

  void _updateSurveyRecordsForManagerTasks(
      {List<SurveyRecord>? firestoreRecords}) {
    if (!mounted) return;
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
    final localizations = AppLocalizations.of(context)!;
    final bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(localizations.confirmDeletion),
              content: Text(localizations.deleteTaskConfirmation(
                  task.lineName, task.targetTowerRange)),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(localizations.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error),
                  child: Text(localizations.delete),
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

        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, localizations.taskAndAssociatedRecordsDeleted);
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, localizations.errorDeletingTask(e.toString()),
              isError: true);
        }
        print('Error deleting task: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showManagerTaskOptions(Task task) {
    final localizations = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(localizations.editTask),
                onTap: () {
                  Navigator.pop(bc);
                  _editTask(task);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(localizations.deleteTask),
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
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });
    try {
      await _taskService.updateTaskStatus(task.id, newStatus);
      if (mounted) {
        SnackBarUtils.showSnackBar(context, localizations.taskStatusUpdated);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, localizations.errorUpdatingTask(e.toString()),
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
          builder: (context) => LineDetailScreen(
            task: task,
            transmissionLine: _allTransmissionLines.firstWhere(
              (line) => line.name == task.lineName,
              orElse: () => throw Exception(
                  'TransmissionLine not found for task ${task.lineName}'),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _uploadUnsyncedRecords() async {
    final localizations = AppLocalizations.of(context)!;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final List<SurveyRecord> unsyncedRecords =
          await _localDatabaseService.getUnsyncedSurveyRecords();

      if (unsyncedRecords.isEmpty) {
        if (mounted) {
          SnackBarUtils.showSnackBar(context, localizations.noUnsyncedRecords,
              isError: false);
        }
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
            context, localizations.uploadSuccess(uploadedCount),
            isError: false);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, localizations.errorUploadingUnsyncedRecords(e.toString()),
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
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.currentUserProfile == null ||
        widget.currentUserProfile!.status != 'approved') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: colorScheme.error),
              const SizedBox(height: 20),
              Text(
                localizations.accountNotApproved,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                localizations.accountApprovalMessage,
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

    if (widget.currentUserProfile!.role == null ||
        (widget.currentUserProfile!.role != 'Worker' &&
            widget.currentUserProfile!.role != 'Manager' &&
            widget.currentUserProfile!.role != 'Admin')) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_ind_outlined,
                  size: 80, color: colorScheme.error),
              const SizedBox(height: 20),
              Text(
                localizations.unassignedRoleTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                localizations.unassignedRoleMessage,
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
            localizations.welcomeUser(
                widget.currentUserProfile!.displayName ??
                    widget.currentUserProfile!.email,
                widget.currentUserProfile!.role!),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: colorScheme.primary),
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.currentUserProfile!.role == 'Manager' ||
            widget.currentUserProfile!.role == 'Admin')
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _assignNewTask,
              icon: const Icon(Icons.add_task),
              label: Text(localizations.assignNewTask),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        if (widget.currentUserProfile!.role == 'Worker')
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _uploadUnsyncedRecords,
              icon: const Icon(Icons.cloud_upload),
              label: Text(localizations.uploadUnsyncedDetails),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          widget.currentUserProfile!.role == 'Worker'
              ? localizations.yourAssignedTasks
              : localizations.allTasks,
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
                    widget.currentUserProfile!.role == 'Worker'
                        ? localizations.noTasksAssigned
                        : localizations.noTasksAvailable,
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

                    IconData statusIconData;
                    Color iconColor;

                    if (task.derivedStatus == 'Patrolled') {
                      statusIconData = Icons.check_circle;
                      iconColor = Colors.green;
                    } else if (task.derivedStatus == 'In Progress (Uploaded)' ||
                        task.derivedStatus == 'In Progress (Local)') {
                      statusIconData = Icons.hourglass_empty;
                      iconColor = colorScheme.tertiary;
                    } else if (task.derivedStatus == 'Pending') {
                      statusIconData = Icons.error;
                      iconColor = colorScheme.error;
                    } else {
                      statusIconData = Icons.help_outline;
                      iconColor = Colors.grey;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 3,
                      child: ExpansionTile(
                        title: Text(
                            '${localizations.task}: ${task.lineName} - ${localizations.towers}: ${task.targetTowerRange} (${task.numberOfTowersToPatrol} ${localizations.toPatrol})'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${localizations.due}: ${task.dueDate.toLocal().toString().split(' ')[0]}'),
                            Text(
                                '${localizations.status}: ${task.derivedStatus}'),
                            if (widget.currentUserProfile!.role == 'Manager' ||
                                widget.currentUserProfile!.role == 'Admin')
                              Text(
                                  '${localizations.assignedToUser}: ${task.assignedToUserName ?? 'N/A'}'),
                          ],
                        ),
                        trailing: (widget.currentUserProfile!.role ==
                                    'Manager' ||
                                widget.currentUserProfile!.role == 'Admin')
                            ? IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showManagerTaskOptions(task),
                                tooltip: localizations.taskOptions,
                              )
                            : (widget.currentUserProfile!.role == 'Worker'
                                ? Icon(statusIconData, color: iconColor)
                                : null),
                        children: [
                          if (widget.currentUserProfile!.role == 'Worker')
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${localizations.patrolledCount}: ${task.localCompletedCount} / ${task.numberOfTowersToPatrol}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '${localizations.uploadedCount}: ${task.uploadedCompletedCount} / ${task.numberOfTowersToPatrol}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(localizations.yourSurveyLogForThisTask,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  recordsForTask.isEmpty
                                      ? Text(
                                          localizations
                                              .noSurveysRecordedForThisTask,
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
                                                      ' • ${localizations.tower} ${record.towerNumber} ${localizations.at} ${record.timestamp.toLocal().toString().split('.')[0]} (${localizations.status}: ${record.status})',
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
                                    label: Text(localizations.continueSurvey),
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
