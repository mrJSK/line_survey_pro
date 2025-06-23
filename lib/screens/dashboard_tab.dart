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
import 'package:collection/collection.dart'
    as collection; // Import the collection package for its extension
import 'package:line_survey_pro/screens/line_patrolling_details_screen.dart'; // Import LinePatrollingDetailsScreen
import 'package:line_survey_pro/l10n/app_localizations.dart'; // Import AppLocalizations

class DashboardTab extends StatefulWidget {
  final UserProfile? currentUserProfile; // NEW: Receive UserProfile

  const DashboardTab({super.key, required this.currentUserProfile});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Removed _currentUser state variable, use widget.currentUserProfile directly
  List<TransmissionLine> _transmissionLines = []; // Filtered based on role
  List<Task> _tasksWithProgress = []; // Filtered based on role
  List<SurveyRecord> _allFirebaseSurveyRecords =
      []; // All records from Firestore
  List<SurveyRecord> _allLocalSurveyRecords = []; // All records from local DB

  // Helper method to build a stat row for the admin dashboard summary
  Widget _buildStatRow(
      String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: iconColor),
          ),
        ],
      ),
    );
  }

  // Data for Manager's per-worker progress view (used by Admin/Manager)
  List<UserProfile> _allUsersInSystem =
      []; // All users fetched regardless of role
  List<UserProfile> _allWorkers = []; // All users with 'Worker' role
  Map<String, WorkerProgressSummary> _workerProgressSummaries = {};

  bool _isLoadingData = true;

  final FirestoreService _firestoreService = FirestoreService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();
  final AuthService _authService =
      AuthService(); // Keep AuthService for other streams/methods
  final TaskService _taskService = TaskService();
  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService();

  // For generating IDs for ad-hoc tasks (Manager/Admin direct survey)
  final Uuid _uuid = const Uuid();

  // Stream Subscriptions to manage real-time data
  StreamSubscription? _linesSubscription;
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _allSurveyRecordsSubscription;
  StreamSubscription? _localSurveyRecordsSubscription;
  StreamSubscription? _allUserProfilesStreamSubscription;

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
    _localSurveyRecordsSubscription?.cancel();
    _allUserProfilesStreamSubscription?.cancel();
    super.dispose();
  }

  // Use didUpdateWidget to react to currentUserProfile changes
  @override
  void didUpdateWidget(covariant DashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUserProfile != oldWidget.currentUserProfile) {
      // Reload data if the user profile changes (e.g., role update)
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted || widget.currentUserProfile == null) return;
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Listen to ALL local records
      _localSurveyRecordsSubscription?.cancel();
      _localSurveyRecordsSubscription =
          _localDatabaseService.getAllSurveyRecordsStream().listen((records) {
        if (mounted) {
          setState(() {
            _allLocalSurveyRecords = records;
            _updateDashboardContentBasedOnRole();
          });
        }
      }, onError: (error) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context,
              AppLocalizations.of(context)!
                  .errorStreamingLocalSurveyRecords(error.toString()),
              isError: true);
        }
      });

      // Stream all lines
      _linesSubscription?.cancel();
      _linesSubscription =
          _firestoreService.getTransmissionLinesStream().listen((lines) {
        if (mounted) {
          _transmissionLines = lines;
          _updateDashboardContentBasedOnRole();
        }
      }, onError: (error) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context,
              AppLocalizations.of(context)!
                  .errorStreamingManagerLines(error.toString()),
              isError: true);
        }
      });

      // Stream all tasks
      _tasksSubscription?.cancel();
      _tasksSubscription = _taskService.streamAllTasks().listen((tasks) {
        if (mounted) {
          _tasksWithProgress = tasks;
          _updateDashboardContentBasedOnRole();
        }
      }, onError: (error) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context,
              AppLocalizations.of(context)!
                  .errorStreamingAllTasks(error.toString()),
              isError: true);
        }
      });

      // Stream all survey records
      _allSurveyRecordsSubscription?.cancel();
      _allSurveyRecordsSubscription =
          _surveyFirestoreService.streamAllSurveyRecords().listen((records) {
        if (mounted) {
          _allFirebaseSurveyRecords = records;
          _updateDashboardContentBasedOnRole();
        }
      }, onError: (error) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context,
              AppLocalizations.of(context)!
                  .errorStreamingAllSurveyRecords(error.toString()),
              isError: true);
        }
      });

      // Stream all user profiles
      _allUserProfilesStreamSubscription?.cancel();
      _allUserProfilesStreamSubscription =
          _authService.streamAllUserProfiles().listen((users) {
        if (mounted) {
          setState(() {
            _allUsersInSystem = users;
            _allWorkers = users.where((user) => user.role == 'Worker').toList();
          });
          _updateDashboardContentBasedOnRole();
        }
      }, onError: (error) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context,
              AppLocalizations.of(context)!
                  .errorStreamingAllUsers(error.toString()),
              isError: true);
        }
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context,
            AppLocalizations.of(context)!
                .errorLoadingDashboardData(e.toString()),
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

  // Renamed from _updateDashboardBasedOnRole for clarity
  void _updateDashboardContentBasedOnRole() {
    if (!mounted ||
        widget.currentUserProfile == null ||
        widget.currentUserProfile!.status != 'approved') {
      setState(() {
        _transmissionLines = [];
        _tasksWithProgress = [];
        _allUsersInSystem = [];
        _allWorkers = [];
        _workerProgressSummaries = {};
      });
      return;
    }

    List<TransmissionLine> displayedLines = [];
    List<Task> displayedTasks = [];

    final UserProfile user = widget.currentUserProfile!;

    if (user.role == 'Admin') {
      displayedTasks = List.from(_tasksWithProgress);
      displayedLines = List.from(_transmissionLines);
    } else if (user.role == 'Manager') {
      displayedLines = _transmissionLines
          .where((line) => user.assignedLineIds.contains(line.id))
          .toList();
      displayedTasks = _tasksWithProgress.where((task) {
        // MODIFIED: Use line.id for manager task filtering
        final TransmissionLine? taskLine =
            _transmissionLines.firstWhereOrNull((l) => l.id == task.lineId);
        return taskLine != null && user.assignedLineIds.contains(taskLine.id);
      }).toList();
    } else if (user.role == 'Worker') {
      displayedTasks = _tasksWithProgress
          .where((task) => task.assignedToUserId == user.id)
          .toList();

      // Sort worker tasks by daysLeft (least days first)
      displayedTasks.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

      final List<Task> enrichedWorkerTasks = [];
      for (var task in displayedTasks) {
        Set<int> uniqueLocalTowers = {};
        Set<int> uniqueUploadedTowers = {};

        for (var record in _allLocalSurveyRecords
            .where((r) => r.taskId == task.id && r.userId == user.id)) {
          if (record.status == 'saved_complete' ||
              record.status == 'uploaded') {
            uniqueLocalTowers.add(record.towerNumber);
          }
        }
        for (var record in _allFirebaseSurveyRecords.where((r) =>
            r.taskId == task.id &&
            r.userId == user.id &&
            r.status == 'uploaded')) {
          uniqueUploadedTowers.add(record.towerNumber);
        }

        enrichedWorkerTasks.add(task.copyWith(
          localCompletedCount: uniqueLocalTowers.length,
          uploadedCompletedCount: uniqueUploadedTowers.length,
        ));
      }
      displayedTasks = enrichedWorkerTasks;

      // MODIFIED: Use lineId for worker assigned lines
      final Set<String> workerAssignedLineIds =
          displayedTasks.map((task) => task.lineId).toSet();
      displayedLines =
          _transmissionLines // This is the _allTransmissionLines before filtering
              .where((line) => workerAssignedLineIds.contains(line.id))
              .toList();
    }

    if (user.role == 'Manager' || user.role == 'Admin') {
      _updateManagerWorkerSummaries(displayedTasks);
    }

    setState(() {
      _transmissionLines =
          displayedLines; // Now _transmissionLines only contains lines for worker's tasks
      _tasksWithProgress = displayedTasks;
    });
  }

  void _updateManagerWorkerSummaries(List<Task> tasksForDisplay) {
    final Map<String, WorkerProgressSummary> summaries = {};
    final allApprovedWorkers = _allUsersInSystem
        .where((user) => user.role == 'Worker' && user.status == 'approved')
        .toList();

    for (var worker in allApprovedWorkers) {
      int linesAssigned = 0;
      int linesCompleted = 0;
      int linesWorkingPending = 0;
      Set<String> completedLines = {};
      Set<String> workingLines = {};

      final workerTasks = tasksForDisplay
          .where((task) => task.assignedToUserId == worker.id)
          .toList();

      // MODIFIED: Use lineId for assigned lines count
      linesAssigned = workerTasks.map((t) => t.lineId).toSet().length;

      for (var task in workerTasks) {
        final completedTowersForTask = _allFirebaseSurveyRecords
            .where((record) =>
                record.lineName == task.lineName &&
                record.taskId == task.id &&
                record.status == 'uploaded')
            .length;

        final Task tempTask =
            task.copyWith(uploadedCompletedCount: completedTowersForTask);

        if (tempTask.derivedStatus == 'Patrolled') {
          // MODIFIED: Use lineId for completed/working lines
          completedLines.add(task.lineId);
        } else if (tempTask.derivedStatus != 'Pending' ||
            completedTowersForTask > 0) {
          // MODIFIED: Use lineId for completed/working lines
          workingLines.add(task.lineId);
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

  void _navigateToLineDetailForTask(
      Task task, TransmissionLine transmissionLine) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            LineDetailScreen(task: task, transmissionLine: transmissionLine),
      ),
    );
  }

  void _navigateToLinePatrollingDetails(TransmissionLine line) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LinePatrollingDetailsScreen(line: line),
      ),
    );
  }

  void _navigateToWorkerDetails(UserProfile userProfile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManagerWorkerDetailScreen(
          userProfile: userProfile,
        ),
      ),
    );
  }

  int get _totalManagersCount => _allUsersInSystem
      .where((user) => user.role == 'Manager' && user.status == 'approved')
      .length;
  int get _totalWorkersCount => _allUsersInSystem
      .where((user) => user.role == 'Worker' && user.status == 'approved')
      .length;
  int get _totalLinesCount => _transmissionLines.length;
  int get _totalTowersInSystem => _transmissionLines
      .map((line) => line.computedTotalTowers)
      .fold(0, (sum, count) => sum + count);
  List<UserProfile> get _latestPendingRequests =>
      _allUsersInSystem.where((user) => user.status == 'pending').toList()
        ..sort((a, b) => (b.email).compareTo(a.email));

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations localizations =
        AppLocalizations.of(context)!; // Access here

    if (_isLoadingData || widget.currentUserProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final UserProfile currentUser = widget.currentUserProfile!;

    if (currentUser.status != 'approved') {
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

    if (currentUser.role == null ||
        (currentUser.role != 'Worker' &&
            currentUser.role != 'Manager' &&
            currentUser.role != 'Admin')) {
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

    int totalCompletedTowers = 0;
    int totalOverallTowers = 0;

    if (currentUser.role == 'Worker') {
      for (var task in _tasksWithProgress) {
        totalCompletedTowers += task.uploadedCompletedCount;
        totalOverallTowers += task.numberOfTowersToPatrol;
      }
    } else {
      final Map<String, int> surveyCountsByLineName = {};
      for (var record in _allFirebaseSurveyRecords) {
        if (record.status == 'uploaded') {
          surveyCountsByLineName[record.lineName] =
              (surveyCountsByLineName[record.lineName] ?? 0) + 1;
        }
      }
      for (var line in _transmissionLines) {
        totalCompletedTowers += surveyCountsByLineName[line.name] ?? 0;
        totalOverallTowers += line.computedTotalTowers;
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
            localizations.surveyProgressOverview,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 15),
          if (currentUser.role == 'Admin')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizations.adminDashboardSummary,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatRow(
                            localizations.totalManagersCount,
                            _totalManagersCount.toString(),
                            Icons.person_outline,
                            colorScheme.primary),
                        _buildStatRow(
                            localizations.totalWorkersCount,
                            _totalWorkersCount.toString(),
                            Icons.engineering,
                            colorScheme.secondary),
                        _buildStatRow(
                            localizations.totalLinesCount,
                            _totalLinesCount.toString(),
                            Icons.speed,
                            colorScheme.tertiary),
                        _buildStatRow(
                            localizations.totalTowersInSystemCount,
                            _totalTowersInSystem.toString(),
                            Icons.location_on,
                            colorScheme.onSurface),
                        _buildStatRow(
                            localizations.pendingApprovalsCount,
                            _latestPendingRequests.length.toString(),
                            Icons.hourglass_empty,
                            colorScheme.error),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(localizations.latestPendingRequestsTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _latestPendingRequests.isEmpty
                    ? Text(localizations.noPendingRequestsTitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontStyle: FontStyle.italic))
                    : Column(
                        children: _latestPendingRequests
                            .map((user) => Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    title: Text(user.email),
                                    subtitle: Text(
                                        '${localizations.status}: ${user.status}'),
                                  ),
                                ))
                            .toList(),
                      ),
                const SizedBox(height: 30),
                Text(localizations.managersAssignmentsTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _allUsersInSystem
                        .where((user) => user.role == 'Manager')
                        .isEmpty
                    ? Text(localizations.noManagersFoundTitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontStyle: FontStyle.italic))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _allUsersInSystem
                            .where((user) => user.role == 'Manager')
                            .length,
                        itemBuilder: (context, index) {
                          final manager = _allUsersInSystem
                              .where((user) => user.role == 'Manager')
                              .elementAt(index);
                          final assignedLinesToManager = _transmissionLines
                              .where((line) =>
                                  manager.assignedLineIds.contains(line.id))
                              .toList();
                          final totalTowersAssignedToManager =
                              assignedLinesToManager
                                  .map((line) => line.computedTotalTowers)
                                  .fold(0, (sum, count) => sum + count);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 0),
                            elevation: 4,
                            child: ListTile(
                              title: Text(manager.displayName ?? manager.email,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(localizations.linesAssignedManagerCount(
                                      assignedLinesToManager.length)),
                                  Text(localizations
                                      .totalTowersAssignedManagerCount(
                                          totalTowersAssignedToManager)),
                                  Text(localizations.tasksAssignedByThemCount(
                                      _tasksWithProgress
                                          .where((task) =>
                                              task.assignedByUserId ==
                                              manager.id)
                                          .length)),
                                ],
                              ),
                              trailing: TextButton(
                                onPressed: () =>
                                    _navigateToWorkerDetails(manager),
                                child: Text(localizations.viewButton,
                                    style:
                                        TextStyle(color: colorScheme.primary)),
                              ),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 30),
              ],
            ),
          if (currentUser.role == 'Manager' || currentUser.role == 'Admin')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(localizations.progressByWorkerTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _allWorkers.isEmpty
                    ? Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              localizations.noWorkerProfilesFoundTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7)),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _allWorkers.length,
                        itemBuilder: (context, index) {
                          final worker = _allWorkers[index];
                          final summary = _workerProgressSummaries[worker.id];

                          if (summary == null) {
                            return const SizedBox.shrink();
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 0),
                            elevation: 4,
                            child: ListTile(
                              title: Text(worker.displayName ?? worker.email,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${localizations.linesAssigned}: ${summary.linesAssigned}'),
                                  Text(
                                      '${localizations.linesPatrolled}: ${summary.linesCompleted}'),
                                  Text(
                                      '${localizations.linesWorkingPending}: ${summary.linesWorkingPending}'),
                                ],
                              ),
                              trailing: TextButton(
                                onPressed: () =>
                                    _navigateToWorkerDetails(worker),
                                child: Text(localizations.viewButton,
                                    style:
                                        TextStyle(color: colorScheme.primary)),
                              ),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 30),
              ],
            ),
          Text(
            currentUser.role == 'Worker'
                ? localizations.yourAssignedTasks
                : localizations.linesUnderSupervision,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 10),
          _tasksWithProgress.isEmpty && _transmissionLines.isEmpty
              ? Center(
                  child: Text(
                    currentUser.role == 'Worker'
                        ? localizations.noTasksAssigned
                        : localizations.noLinesOrTasksAvailable,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentUser.role == 'Worker'
                      ? _tasksWithProgress.length
                      : _transmissionLines.length,
                  itemBuilder: (context, index) {
                    if (currentUser.role == 'Worker') {
                      final task = _tasksWithProgress[index];
                      // DEBUG PRINTS ADDED HERE:
                      print(
                          'DEBUG Dashboard: Current Task on card tap: LineId="${task.lineId}", LineName="${task.lineName}", TargetTowerRange="${task.targetTowerRange}"'); //
                      // MODIFIED: Use line.id for matching
                      final TransmissionLine? taskLine =
                          _transmissionLines.firstWhereOrNull(
                              (line) => line.id == task.lineId); //
                      print(
                          'DEBUG Dashboard: Lookup Result for Task LineId "${task.lineId}": Found=${taskLine != null}'); //

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        child: InkWell(
                          onTap: () {
                            if (taskLine != null) {
                              _navigateToLineDetailForTask(task, taskLine);
                            } else {
                              SnackBarUtils.showSnackBar(context,
                                  'Line data not found for this task (ID: ${task.lineId}). Please ensure the line is correctly configured.', // Updated message
                                  isError: true);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${localizations.task}: ${task.lineName} - ${localizations.towers}: ${task.targetTowerRange} (${task.numberOfTowersToPatrol} ${localizations.toPatrol})',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${localizations.patrolledCount}: ${task.localCompletedCount} / ${task.numberOfTowersToPatrol}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  '${localizations.uploadedCount}: ${task.uploadedCompletedCount} / ${task.numberOfTowersToPatrol}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                // Display days left for worker
                                Text(
                                    task.isOverdue
                                        ? localizations.overdue
                                        : localizations.daysLeft(
                                            task.daysLeft), // Days left
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            color: task.isOverdue
                                                ? Colors.red
                                                : Colors.green)),
                                Text(
                                    '${localizations.due}: ${task.dueDate.toLocal().toString().split(' ')[0]} | ${localizations.status}: ${task.derivedStatus}',
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
                                          : 1),
                                  backgroundColor:
                                      colorScheme.secondary.withOpacity(0.2),
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
                      final line = _transmissionLines[index];
                      final completedTowers = _allFirebaseSurveyRecords
                          .where((record) =>
                              record.lineName == line.name &&
                              record.status == 'uploaded')
                          .length;
                      final totalTowers = line.computedTotalTowers;
                      final progress =
                          totalTowers > 0 ? completedTowers / totalTowers : 0.0;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        child: InkWell(
                          onTap: () => _navigateToLinePatrollingDetails(line),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(line.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 8),
                                Text(
                                    '${localizations.voltageLevel}: ${line.voltageLevel ?? 'N/A'}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                Text(
                                    '${localizations.towers}: $completedTowers / $totalTowers',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor:
                                        colorScheme.secondary.withOpacity(0.2),
                                    color: colorScheme.secondary,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4)),
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
                                                color: colorScheme.secondary))),
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
            localizations
                .surveyProgressOverview, // Or use a suitable existing getter
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

                      return SizedBox(
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
                              '${totalCompletedTowers} / ${totalOverallTowers} ${localizations.towers}', // Localized "Towers"
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
