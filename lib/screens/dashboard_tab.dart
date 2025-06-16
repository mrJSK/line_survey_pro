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
import 'package:line_survey_pro/screens/manager_worker_detail_screen.dart'; // Import ManagerWorkerDetailScreen

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  UserProfile? _currentUser;
  List<TransmissionLine> _transmissionLines = [];
  List<Task> _tasksWithProgress = [];
  List<SurveyRecord> _allFirebaseSurveyRecords = [];
  List<SurveyRecord> _allLocalSurveyRecords = [];

  // Data for Manager's per-worker progress view
  List<UserProfile> _allWorkers = [];
  Map<String, WorkerProgressSummary> _workerProgressSummaries = {};

  bool _isLoadingData = true;

  final FirestoreService _firestoreService = FirestoreService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService();
  final Uuid _uuid = const Uuid();

  StreamSubscription? _linesSubscription;
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _allSurveyRecordsSubscription;
  StreamSubscription? _userSurveyRecordsSubscription;
  StreamSubscription? _allUserProfilesSubscription;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    // Cancel all active subscriptions to prevent memory leaks
    _linesSubscription?.cancel();
    _tasksSubscription?.cancel();
    _allSurveyRecordsSubscription?.cancel();
    _userSurveyRecordsSubscription?.cancel();
    _allUserProfilesSubscription?.cancel();
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
      _allUserProfilesSubscription?.cancel();

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
              _updateManagerDashboardData();
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
          (tasks) {
            if (mounted) {
              _tasksWithProgress = tasks;
              _updateManagerDashboardData();
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
              _updateManagerDashboardData();
            }
          },
          onError: (error) {
            if (mounted)
              SnackBarUtils.showSnackBar(context,
                  'Error streaming all survey records: ${error.toString()}',
                  isError: true);
          },
        );

        _allUserProfilesSubscription =
            _authService.streamAllUserProfiles().listen(
          (userProfiles) {
            if (mounted) {
              _allWorkers =
                  userProfiles.where((user) => user.role == 'Worker').toList();
              _updateManagerDashboardData();
            }
          },
          onError: (error) {
            if (mounted)
              SnackBarUtils.showSnackBar(context,
                  'Error streaming all user profiles: ${error.toString()}',
                  isError: true);
          },
        );
      } else if (_currentUser!.role == 'Worker') {
        _tasksSubscription =
            _taskService.streamTasksForUser(_currentUser!.id).listen(
          (tasks) async {
            if (mounted) {
              _tasksWithProgress = tasks;
              final Set<String> assignedLineNames =
                  _tasksWithProgress.map((task) => task.lineName).toSet();
              _transmissionLines =
                  (await _firestoreService.getTransmissionLinesOnce())
                      .where((line) => assignedLineNames.contains(line.name))
                      .toList();
              _updateWorkerDashboardData();
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
              _allFirebaseSurveyRecords = records;
              _updateWorkerDashboardData();
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

  // Manager Dashboard Data Aggregation
  void _updateManagerDashboardData() {
    if (!mounted) return;
    final Map<String, WorkerProgressSummary> summaries = {};

    for (var worker in _allWorkers) {
      int linesAssigned = 0;
      int linesCompleted = 0;
      int linesWorkingPending = 0;
      Set<String> completedLines = {};
      Set<String> workingLines = {};

      final workerTasks = _tasksWithProgress
          .where((task) => task.assignedToUserId == worker.id)
          .toList();
      linesAssigned = workerTasks.map((t) => t.lineName).toSet().length;

      for (var task in workerTasks) {
        final completedTowersForTask = _allFirebaseSurveyRecords
            .where((record) =>
                record.lineName == task.lineName &&
                record.taskId == task.id &&
                record.status == 'uploaded')
            .length;

        final tempTask =
            task.copyWith(uploadedCompletedCount: completedTowersForTask);

        if (tempTask.derivedStatus == 'Completed') {
          completedLines.add(task.lineName);
        } else if (tempTask.derivedStatus != 'Pending' ||
            completedTowersForTask > 0) {
          workingLines.add(task.lineName);
        }
      }
      linesCompleted = completedLines.length;
      linesWorkingPending = workingLines.length;

      summaries[worker.id] = WorkerProgressSummary(
        worker: worker,
        linesAssigned: linesAssigned,
        linesCompleted: linesCompleted,
        linesWorkingPending: linesWorkingPending,
      );
    }

    setState(() {
      _workerProgressSummaries = summaries;
    });
  }

  // Worker Dashboard Data Aggregation and Task Object Enrichment
  void _updateWorkerDashboardData() {
    if (!mounted) return;
    final List<Task> enrichedTasks = [];

    for (var task in _tasksWithProgress) {
      int localCount = 0;
      int uploadedCount = 0;

      Map<String, SurveyRecord> combinedRecordsMap = {};
      for (var record in _allLocalSurveyRecords
          .where((r) => r.taskId == task.id && r.userId == _currentUser!.id)) {
        combinedRecordsMap[record.id] = record;
      }
      for (var fRecord in _allFirebaseSurveyRecords.where((r) =>
          r.taskId == task.id &&
          r.userId == _currentUser!.id &&
          r.status == 'uploaded')) {
        final localMatch = combinedRecordsMap[fRecord.id];
        if (localMatch != null) {
          combinedRecordsMap[fRecord.id] =
              localMatch.copyWith(status: fRecord.status);
        } else {
          combinedRecordsMap[fRecord.id] = fRecord;
        }
      }
      Set<int> uniqueLocalTowers = {};
      Set<int> uniqueUploadedTowers = {};

      for (var record in combinedRecordsMap.values) {
        if (record.taskId == task.id) {
          uniqueLocalTowers.add(record.towerNumber);
          if (record.status == 'uploaded') {
            uniqueUploadedTowers.add(record.towerNumber);
          }
        }
      }

      enrichedTasks.add(task.copyWith(
        localCompletedCount: uniqueLocalTowers.length,
        uploadedCompletedCount: uniqueUploadedTowers.length,
      ));
    }

    setState(() {
      _tasksWithProgress = enrichedTasks;
    });
  }

  void _navigateToLineDetailForTask(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LineDetailScreen(task: task),
      ),
    );
  }

  // Navigate to Worker details screen for managers
  void _navigateToWorkerDetails(UserProfile worker) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManagerWorkerDetailScreen(
          workerId: worker.id,
          workerDisplayName: worker.displayName ?? worker.email,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    int totalCompletedTowers = 0;
    int totalOverallTowers = 0;

    if (_currentUser?.role == 'Worker') {
      for (var task in _tasksWithProgress) {
        totalCompletedTowers += task.uploadedCompletedCount;
        totalOverallTowers += task.numberOfTowersToPatrol;
      }
    } else {
      // Manager or unassigned
      final Map<String, int> managerOverallProgress = {};
      for (var record in _allFirebaseSurveyRecords) {
        if (record.status == 'uploaded') {
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
                  // Manager's Per-Worker Progress View
                  : (_currentUser?.role == 'Manager')
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                                height: 10), // Space above section heading
                            Text('Progress by Worker:',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(
                                height: 10), // Space below section heading
                            _allWorkers.isEmpty
                                ? Card(
                                    // Wrap "No workers found" in a Card for consistent spacing and visual presence
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 8),
                                    elevation: 2, // Lighter elevation
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Center(
                                        child: Text(
                                          'No worker profiles found. Assign roles in Firebase console to see progress.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  fontStyle: FontStyle.italic,
                                                  color: colorScheme.onSurface
                                                      .withOpacity(0.7)),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _allWorkers.length,
                                    itemBuilder: (context, index) {
                                      final worker = _allWorkers[index];
                                      final summary =
                                          _workerProgressSummaries[worker.id];

                                      if (summary == null) {
                                        return const SizedBox.shrink();
                                      }

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 0),
                                        elevation: 4,
                                        child: ListTile(
                                          title: Text(
                                              worker.displayName ??
                                                  worker.email,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'Lines Assigned: ${summary.linesAssigned}'),
                                              Text(
                                                  'Lines Completed: ${summary.linesCompleted}'),
                                              Text(
                                                  'Lines Working/Pending: ${summary.linesWorkingPending}'),
                                            ],
                                          ),
                                          trailing: TextButton(
                                            onPressed: () =>
                                                _navigateToWorkerDetails(
                                                    worker),
                                            child: Text('View >',
                                                style: TextStyle(
                                                    color:
                                                        colorScheme.primary)),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            const SizedBox(
                                height:
                                    30), // Consistent spacing after this section
                          ],
                        )
                      // Worker's Task Progress List (or general line list for other roles)
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Task: ${task.lineName} - Towers: ${task.targetTowerRange}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Completed: ${task.localCompletedCount} / ${task.numberOfTowersToPatrol}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
                                        Text(
                                          'Uploaded: ${task.uploadedCompletedCount} / ${task.numberOfTowersToPatrol}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
                                        Text(
                                            'Due: ${task.dueDate.toLocal().toString().split(' ')[0]} | Status: ${task.derivedStatus}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    fontStyle:
                                                        FontStyle.italic)),
                                        const SizedBox(height: 12),
                                        LinearProgressIndicator(
                                          value: task.uploadedCompletedCount /
                                              (task.numberOfTowersToPatrol > 0
                                                  ? task.numberOfTowersToPatrol
                                                  : 1),
                                          backgroundColor: colorScheme.secondary
                                              .withOpacity(0.2),
                                          color: colorScheme.secondary,
                                          minHeight: 8,
                                          borderRadius:
                                              BorderRadius.circular(4),
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
                                                    color:
                                                        colorScheme.secondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              final line = _transmissionLines[index];
                              final completedTowers = _allFirebaseSurveyRecords
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(line.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(height: 8),
                                        Text(
                                            'Towers Completed: $completedTowers / $totalTowers',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge),
                                        const SizedBox(height: 12),
                                        LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: colorScheme
                                                .secondary
                                                .withOpacity(0.2),
                                            color: colorScheme.secondary,
                                            minHeight: 8,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        const SizedBox(height: 8),
                                        Align(
                                            alignment: Alignment.bottomRight,
                                            child: Text(
                                                '${(progress * 100).toStringAsFixed(1)}%',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: colorScheme
                                                            .secondary))),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
          const SizedBox(height: 30),

          // Overall Survey Progress Graph (always at the bottom)
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
                                          fontSize: indicatorSize * 0.25),
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
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                      fontSize: 16),
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

// Helper class for worker progress summary (remains the same)
class WorkerProgressSummary {
  final UserProfile worker;
  final int linesAssigned;
  final int linesCompleted;
  final int linesWorkingPending;

  WorkerProgressSummary({
    required this.worker,
    required this.linesAssigned,
    required this.linesCompleted,
    required this.linesWorkingPending,
  });
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
