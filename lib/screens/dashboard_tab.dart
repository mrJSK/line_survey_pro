// lib/screens/dashboard_tab.dart
// Displays survey progress and provides a form for new survey entries.
// Fetches transmission lines from Firestore, gets current GPS, and navigates to camera.
// Redesigned for a more modern and professional UI.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:geolocator/geolocator.dart'; // For GPS coordinates and distance calculation
import 'package:line_survey_pro/models/transmission_line.dart'; // TransmissionLine model
import 'package:line_survey_pro/models/user_profile.dart'; // UserProfile model
import 'package:line_survey_pro/models/task.dart'; // Task model
import 'package:line_survey_pro/services/local_database_service.dart'; // Local database interaction (still for validation/cache)
import 'package:line_survey_pro/services/firestore_service.dart'; // Firestore service
import 'package:line_survey_pro/services/location_service.dart'; // Location service
import 'package:line_survey_pro/screens/camera_screen.dart'; // Camera screen navigation
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Snackbar utility
import 'package:line_survey_pro/services/permission_service.dart'; // Permission service for location
import 'dart:async'; // For StreamSubscription
import 'package:line_survey_pro/models/survey_record.dart'; // Import SurveyRecord for validation
import 'package:line_survey_pro/screens/line_detail_screen.dart'; // Import LineDetailScreen
import 'package:line_survey_pro/services/auth_service.dart'; // AuthService
import 'package:line_survey_pro/services/task_service.dart'; // TaskService
import 'package:line_survey_pro/services/survey_firestore_service.dart'; // SurveyFirestoreService
import 'package:uuid/uuid.dart'; // For generating unique IDs for dummy tasks
import 'package:line_survey_pro/screens/home_screen.dart'; // Import HomeScreen and its key

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  UserProfile? _currentUser;
  List<TransmissionLine> _transmissionLines = [];
  List<Task> _tasksWithProgress =
      []; // Consolidated list of tasks with calculated progress (worker's assigned tasks or all tasks for manager)
  List<SurveyRecord> _allFirebaseSurveyRecords =
      []; // All survey records from Firebase (relevant subset for worker, all for manager)
  List<SurveyRecord> _allLocalSurveyRecords =
      []; // All survey records from local database (for validation/cache)

  bool _isLoadingData = true;

  final FirestoreService _firestoreService = FirestoreService();
  final LocalDatabaseService _localDatabaseService =
      LocalDatabaseService(); // Still used for local record operations (e.g., photoPath)
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService();
  final Uuid _uuid = const Uuid();

  StreamSubscription? _linesSubscription;
  StreamSubscription? _tasksSubscription;
  StreamSubscription?
      _allSurveyRecordsSubscription; // For managers to listen to all records
  StreamSubscription?
      _userSurveyRecordsSubscription; // For workers to listen to their own records

  @override
  void initState() {
    super.initState();
    _loadDashboardData(); // Load all necessary data
  }

  @override
  void dispose() {
    // Cancel all active subscriptions to prevent memory leaks
    _linesSubscription?.cancel();
    _tasksSubscription?.cancel();
    _allSurveyRecordsSubscription?.cancel();
    _userSurveyRecordsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return; // Ensure widget is mounted before async operations
    setState(() {
      _isLoadingData = true;
    });

    try {
      _currentUser = await _authService.getCurrentUserProfile();

      if (_currentUser == null) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'User profile not found. Please log in again.',
              isError: true);
        }
        return;
      }

      // Cancel all existing subscriptions before setting up new ones
      _linesSubscription?.cancel();
      _tasksSubscription?.cancel();
      _allSurveyRecordsSubscription?.cancel();
      _userSurveyRecordsSubscription?.cancel();

      // Fetch all local records once (needed for photoPath in ExportScreen and local count in Task model)
      _allLocalSurveyRecords =
          await _localDatabaseService.getAllSurveyRecords();

      if (_currentUser!.role == 'Manager') {
        _linesSubscription =
            _firestoreService.getTransmissionLinesStream().listen(
          (lines) {
            if (mounted) {
              setState(() {
                _transmissionLines = lines;
              });
              _updateManagerDashboardData(); // Re-calculate when lines change
            }
          },
          onError: (error) {
            if (mounted)
              SnackBarUtils.showSnackBar(context,
                  'Error streaming transmission lines: ${error.toString()}',
                  isError: true);
          },
        );

        _tasksSubscription = _taskService.streamAllTasks().listen(
          // Manager sees all tasks
          (tasks) {
            if (mounted) {
              _tasksWithProgress =
                  tasks; // Managers tasks are just all tasks here
              _updateManagerDashboardData(); // Re-calculate when tasks change
            }
          },
          onError: (error) {
            if (mounted)
              SnackBarUtils.showSnackBar(
                  context, 'Error streaming all tasks: ${error.toString()}',
                  isError: true);
          },
        );

        _allSurveyRecordsSubscription =
            _surveyFirestoreService.streamAllSurveyRecords().listen(
          (records) {
            if (mounted) {
              _allFirebaseSurveyRecords = records;
              _updateManagerDashboardData(); // Re-calculate when records change
            }
          },
          onError: (error) {
            if (mounted)
              SnackBarUtils.showSnackBar(context,
                  'Error streaming all survey records: ${error.toString()}',
                  isError: true);
          },
        );
      } else if (_currentUser!.role == 'Worker') {
        _tasksSubscription =
            _taskService.streamTasksForUser(_currentUser!.id).listen(
          (tasks) async {
            if (mounted) {
              _tasksWithProgress = tasks; // Worker sees their assigned tasks
              final Set<String> assignedLineNames =
                  _tasksWithProgress.map((task) => task.lineName).toSet();
              _transmissionLines = (await _firestoreService
                      .getTransmissionLinesOnce()) // Fetch once for names
                  .where((line) => assignedLineNames.contains(line.name))
                  .toList();
              _updateWorkerDashboardData(); // Re-calculate when tasks change
            }
          },
          onError: (error) {
            if (mounted)
              SnackBarUtils.showSnackBar(
                  context, 'Error streaming your tasks: ${error.toString()}',
                  isError: true);
          },
        );

        _userSurveyRecordsSubscription = _surveyFirestoreService
            .streamSurveyRecordsForUser(_currentUser!.id)
            .listen(
          (records) {
            if (mounted) {
              _allFirebaseSurveyRecords =
                  records; // All records by this user from Firebase
              _updateWorkerDashboardData(); // Re-calculate when worker's records change
            }
          },
          onError: (error) {
            if (mounted)
              SnackBarUtils.showSnackBar(context,
                  'Error streaming your survey records: ${error.toString()}',
                  isError: true);
          },
        );
      } else {
        _transmissionLines = [];
        _tasksWithProgress = [];
        _allFirebaseSurveyRecords = [];
        _allLocalSurveyRecords = [];
        // No SnackBar for unassigned roles as RealTimeTasksScreen handles this
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error loading dashboard data: ${e.toString()}',
            isError: true);
      }
      print('Dashboard data loading error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // Centralized progress calculation for Manager
  void _updateManagerDashboardData() {
    if (!mounted) return;
    // For managers, we are now just linking the _tasksWithProgress to all tasks.
    // Progress calculation for overall completed/total occurs in the build method.
    setState(() {
      // Trigger rebuild to update progress display
    });
  }

  // Worker Dashboard Data Aggregation and Task Object Enrichment
  void _updateWorkerDashboardData() {
    if (!mounted) return;
    final List<Task> enrichedTasks = [];

    for (var task in _tasksWithProgress) {
      // Iterate through the worker's assigned tasks
      int localCount = 0;
      int uploadedCount = 0;

      // Count local and uploaded surveys specifically for *this task*
      for (var record in _allLocalSurveyRecords
          .where((r) => r.taskId == task.id && r.userId == _currentUser!.id)) {
        localCount++; // Count all local records for this task
      }
      for (var record in _allFirebaseSurveyRecords.where((r) =>
          r.taskId == task.id &&
          r.userId == _currentUser!.id &&
          r.status == 'uploaded')) {
        uploadedCount++; // Count all uploaded records for this task
      }

      // Create a new Task object with the updated counts
      enrichedTasks.add(task.copyWith(
        localCompletedCount: localCount,
        uploadedCompletedCount: uploadedCount,
      ));
    }

    setState(() {
      _tasksWithProgress =
          enrichedTasks; // Update the tasks list with enriched data
    });
  }

  void _navigateToLineDetailForTask(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LineDetailScreen(task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    int totalCompletedTowers = 0; // Total uploaded towers across relevant scope
    int totalOverallTowers = 0; // Total assigned towers across relevant scope

    if (_currentUser?.role == 'Worker') {
      for (var task in _tasksWithProgress) {
        totalCompletedTowers += task
            .uploadedCompletedCount; // Use uploaded count for overall progress
        totalOverallTowers += task.numberOfTowersToPatrol;
      }
    } else {
      // Manager or unassigned
      // For manager, calculate overall from all lines and all uploaded survey records
      final Map<String, int> managerOverallProgress = {};
      for (var record in _allFirebaseSurveyRecords) {
        if (record.status == 'uploaded') {
          // Only count uploaded records for manager's progress
          managerOverallProgress[record.lineName] =
              (managerOverallProgress[record.lineName] ?? 0) + 1;
        }
      }
      for (var line in _transmissionLines) {
        totalCompletedTowers += managerOverallProgress[line.name] ?? 0;
        totalOverallTowers += line.totalTowers;
      }
    }

    double overallProgressPercentage = totalOverallTowers > 0
        ? totalCompletedTowers / totalOverallTowers
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Survey Progress Overview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 15),
          _isLoadingData
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : (_transmissionLines.isEmpty &&
                      _tasksWithProgress.isEmpty &&
                      _allFirebaseSurveyRecords.isEmpty)
                  ? Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            (_currentUser?.role == 'Worker' &&
                                    _tasksWithProgress.isEmpty)
                                ? 'No tasks assigned to you. Contact your manager.'
                                : 'No transmission lines or survey records found. Add data to get started!',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: colorScheme.onSurface),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _currentUser?.role == 'Worker'
                          ? _tasksWithProgress.length
                          : _transmissionLines.length,
                      itemBuilder: (context, index) {
                        if (_currentUser?.role == 'Worker') {
                          final task = _tasksWithProgress[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 4,
                            child: InkWell(
                              onTap: () {
                                _navigateToLineDetailForTask(task);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Task: ${task.lineName} - Towers: ${task.targetTowerRange}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Completed: ${task.localCompletedCount} / ${task.numberOfTowersToPatrol}', // Show total completed (local)
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    Text(
                                      'Uploaded: ${task.uploadedCompletedCount} / ${task.numberOfTowersToPatrol}', // Show uploaded count
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    Text(
                                        'Due: ${task.dueDate.toLocal().toString().split(' ')[0]} | Status: ${task.derivedStatus}', // Use DERIVED status
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontStyle: FontStyle.italic)),
                                    const SizedBox(height: 12),
                                    LinearProgressIndicator(
                                      value: task.uploadedCompletedCount /
                                          (task.numberOfTowersToPatrol > 0
                                              ? task.numberOfTowersToPatrol
                                              : 1), // Progress based on uploaded
                                      backgroundColor: colorScheme.secondary
                                          .withOpacity(0.2),
                                      color: colorScheme.secondary,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        '${(task.uploadedCompletedCount / (task.numberOfTowersToPatrol > 0 ? task.numberOfTowersToPatrol : 1) * 100).toStringAsFixed(1)}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.secondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else {
                          // Manager view: Show all lines
                          final line = _transmissionLines[index];
                          // Progress calculation for managers
                          final int completedTowers = _allFirebaseSurveyRecords
                              .where((record) =>
                                  record.lineName == line.name &&
                                  record.status == 'uploaded')
                              .length;
                          final totalTowers = line.totalTowers;
                          final progress = totalTowers > 0
                              ? completedTowers / totalTowers
                              : 0.0;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 4,
                            child: InkWell(
                              onTap: () => _navigateToLineDetailForTask(
                                Task(
                                  id: _uuid.v4(),
                                  assignedToUserId: _currentUser!.id,
                                  assignedByUserId: _currentUser!.id,
                                  lineName: line.name,
                                  targetTowerRange: 'All',
                                  numberOfTowersToPatrol: line.totalTowers,
                                  dueDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                  createdAt: DateTime.now(),
                                  status: 'Manager_AdHoc_Survey',
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Towers Completed: $completedTowers / $totalTowers',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 12),
                                    LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: colorScheme.secondary
                                          .withOpacity(0.2),
                                      color: colorScheme.secondary,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        '${(progress * 100).toStringAsFixed(1)}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.secondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
          const SizedBox(height: 30),
          Text(
            'Overall Survey Progress',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 15),
          Card(
            margin: EdgeInsets.zero,
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double indicatorSize = constraints.maxWidth * 0.45;
                      if (indicatorSize > 120) indicatorSize = 120;
                      if (indicatorSize < 80) indicatorSize = 80;

                      return Container(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: indicatorSize,
                                  height: indicatorSize,
                                  child: CircularProgressIndicator(
                                    value: overallProgressPercentage,
                                    strokeWidth: indicatorSize / 10,
                                    backgroundColor:
                                        colorScheme.primary.withOpacity(0.2),
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  '${(overallProgressPercentage * 100).toStringAsFixed(1)}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: colorScheme.primary,
                                        fontSize: indicatorSize * 0.25,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$totalCompletedTowers / $totalOverallTowers Towers',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: 16,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
