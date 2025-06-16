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
import 'package:collection/collection.dart'; // Import the collection package for its extension
import 'package:line_survey_pro/screens/line_patrolling_details_screen.dart'; // Import LinePatrollingDetailsScreen

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  UserProfile? _currentUser;
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
      []; // NEW: All users fetched regardless of role
  List<UserProfile> _allWorkers = []; // All users with 'Worker' role
  Map<String, WorkerProgressSummary> _workerProgressSummaries = {};

  bool _isLoadingData = true;

  final FirestoreService _firestoreService = FirestoreService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService();

  // For generating IDs for ad-hoc tasks (Manager/Admin direct survey)
  final Uuid _uuid = const Uuid();

  // Stream Subscriptions to manage real-time data
  StreamSubscription? _linesSubscription;
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _allSurveyRecordsSubscription;
  StreamSubscription?
      _localSurveyRecordsSubscription; // NEW: Local records stream
  StreamSubscription?
      _userProfileSubscription; // To get the latest UserProfile (including assignedLineIds)
  StreamSubscription?
      _allUserProfilesStreamSubscription; // NEW: To get all users for admin dashboard counts

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
    _localSurveyRecordsSubscription?.cancel(); // NEW
    _userProfileSubscription?.cancel();
    _allUserProfilesStreamSubscription?.cancel(); // NEW
    // Local survey records stream is managed by LocalDatabaseService internally,
    // it will be closed when LocalDatabaseService.close() is called (e.g., on app shutdown).
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingData = true;
    });

    try {
      // 1. Stream current user's profile for role and assigned lines
      _userProfileSubscription =
          _authService.userChanges.listen((firebaseUser) async {
        if (firebaseUser != null) {
          _currentUser = await _authService.getCurrentUserProfile();
          if (mounted) {
            _updateDashboardBasedOnRole();
          }
        } else {
          // User logged out
          _currentUser = null;
          if (mounted) {
            setState(() {
              _isLoadingData = false;
            });
          }
        }
      });

      // 2. Stream all local records for workers' progress calculation
      _localSurveyRecordsSubscription =
          _localDatabaseService.getAllSurveyRecordsStream().listen((records) {
        if (mounted) {
          setState(() {
            _allLocalSurveyRecords = records;
            _updateDashboardBasedOnRole(); // Re-evaluate dashboard based on new local data
          });
        }
      }, onError: (error) {
        if (mounted)
          SnackBarUtils.showSnackBar(context,
              'Error streaming local survey records: ${error.toString()}',
              isError: true);
      });

      // 3. Stream all necessary data from Firestore (will be filtered later)
      _linesSubscription =
          _firestoreService.getTransmissionLinesStream().listen((lines) {
        if (mounted) {
          _transmissionLines = lines; // Initially load all, then filter
          _updateDashboardBasedOnRole();
        }
      }, onError: (error) {
        if (mounted)
          SnackBarUtils.showSnackBar(context,
              'Error streaming transmission lines: ${error.toString()}',
              isError: true);
      });

      _tasksSubscription = _taskService.streamAllTasks().listen((tasks) {
        if (mounted) {
          _tasksWithProgress = tasks; // Initially load all, then filter
          _updateDashboardBasedOnRole();
        }
      }, onError: (error) {
        if (mounted)
          SnackBarUtils.showSnackBar(
              context, 'Error streaming all tasks: ${error.toString()}',
              isError: true);
      });

      _allSurveyRecordsSubscription =
          _surveyFirestoreService.streamAllSurveyRecords().listen((records) {
        if (mounted) {
          _allFirebaseSurveyRecords =
              records; // Always get all for comprehensive calculations
          _updateDashboardBasedOnRole();
        }
      }, onError: (error) {
        if (mounted)
          SnackBarUtils.showSnackBar(context,
              'Error streaming all survey records: ${error.toString()}',
              isError: true);
      });

      // NEW: Stream all user profiles for Admin dashboard counts (managers, workers, pending)
      _allUserProfilesStreamSubscription =
          _authService.streamAllUserProfiles().listen((users) {
        if (mounted) {
          setState(() {
            _allUsersInSystem = users;
            _allWorkers = users
                .where((user) => user.role == 'Worker')
                .toList(); // Used for worker summaries
          });
          _updateDashboardBasedOnRole(); // Re-evaluate dashboard based on latest user data
        }
      }, onError: (error) {
        if (mounted)
          SnackBarUtils.showSnackBar(
              context, 'Error streaming all users: ${error.toString()}',
              isError: true);
      });
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

  // Centralized method to update dashboard data based on role and latest streams
  void _updateDashboardBasedOnRole() {
    if (!mounted || _currentUser == null || _currentUser!.status != 'approved')
      return;

    List<TransmissionLine> displayedLines = [];
    List<Task> displayedTasks = [];

    // Filter tasks based on current user's role and assigned lines
    if (_currentUser!.role == 'Admin') {
      displayedTasks = List.from(_tasksWithProgress); // Admin sees all tasks
      displayedLines = List.from(_transmissionLines); // Admin sees all lines
    } else if (_currentUser!.role == 'Manager') {
      // Manager sees tasks and lines relevant to their assigned lines
      displayedLines = _transmissionLines
          .where((line) => _currentUser!.assignedLineIds.contains(line.id))
          .toList();
      displayedTasks = _tasksWithProgress.where((task) {
        // Find the TransmissionLine object corresponding to the task's lineName
        final TransmissionLine? taskLine = _transmissionLines.firstWhereOrNull(
          (l) => l.name == task.lineName,
        );
        // Include task only if its line is among the manager's assigned lines
        return taskLine != null &&
            _currentUser!.assignedLineIds.contains(taskLine.id);
      }).toList();
    } else if (_currentUser!.role == 'Worker') {
      // Worker sees only tasks assigned to them
      displayedTasks = _tasksWithProgress
          .where((task) => task.assignedToUserId == _currentUser!.id)
          .toList();

      // Populate localCompletedCount and uploadedCompletedCount for worker tasks
      final List<Task> enrichedWorkerTasks = [];
      for (var task in displayedTasks) {
        Set<int> uniqueLocalTowers = {};
        Set<int> uniqueUploadedTowers = {};

        // Use _allLocalSurveyRecords for local count
        for (var record in _allLocalSurveyRecords.where(
            (r) => r.taskId == task.id && r.userId == _currentUser!.id)) {
          // Count a tower as locally completed if there's any record (saved_complete or uploaded) for it
          if (record.status == 'saved_complete' ||
              record.status == 'uploaded') {
            uniqueLocalTowers.add(record.towerNumber);
          }
        }

        // Use _allFirebaseSurveyRecords for uploaded count
        for (var record in _allFirebaseSurveyRecords.where((r) =>
            r.taskId == task.id &&
            r.userId == _currentUser!.id &&
            r.status == 'uploaded')) {
          uniqueUploadedTowers.add(record.towerNumber);
        }

        enrichedWorkerTasks.add(task.copyWith(
          localCompletedCount: uniqueLocalTowers.length,
          uploadedCompletedCount: uniqueUploadedTowers.length,
        ));
      }
      displayedTasks = enrichedWorkerTasks; // Use the enriched tasks

      // And lines associated with their assigned tasks
      final Set<String> workerAssignedLineNames =
          displayedTasks.map((task) => task.lineName).toSet();
      displayedLines = _transmissionLines
          .where((line) => workerAssignedLineNames.contains(line.name))
          .toList();
    }

    // Update worker summaries (only relevant for Manager/Admin views)
    if (_currentUser!.role == 'Manager' || _currentUser!.role == 'Admin') {
      _updateManagerWorkerSummaries(displayedTasks);
    }

    // Apply the filtered lists to the state
    setState(() {
      _transmissionLines = displayedLines;
      _tasksWithProgress = displayedTasks;
    });
  }

  // Updates per-worker progress summaries (for Manager/Admin view)
  void _updateManagerWorkerSummaries(List<Task> tasksForDisplay) {
    final Map<String, WorkerProgressSummary> summaries = {};
    // Use _allUsersInSystem for filtering workers for summaries
    final allApprovedWorkers = _allUsersInSystem
        .where((user) => user.role == 'Worker' && user.status == 'approved')
        .toList();

    for (var worker in allApprovedWorkers) {
      int linesAssigned = 0;
      int linesCompleted = 0;
      int linesWorkingPending = 0;
      Set<String> completedLines = {};
      Set<String> workingLines = {};

      final workerTasks =
          tasksForDisplay // Use tasks already filtered by manager's lines
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

        final Task tempTask =
            task.copyWith(uploadedCompletedCount: completedTowersForTask);

        if (tempTask.derivedStatus == 'Patrolled') {
          // Changed from 'Completed'
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

  void _navigateToLineDetailForTask(
      Task task, TransmissionLine transmissionLine) {
    // NEW: Added TransmissionLine parameter
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LineDetailScreen(
            task: task,
            transmissionLine: transmissionLine), // Pass TransmissionLine
      ),
    );
  }

  // NEW: Navigate to Line Patrolling Details screen for Managers/Admins
  void _navigateToLinePatrollingDetails(TransmissionLine line) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LinePatrollingDetailsScreen(line: line),
      ),
    );
  }

  // Navigate to Worker details screen for managers
  void _navigateToWorkerDetails(UserProfile userProfile) {
    // Changed parameter name
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManagerWorkerDetailScreen(
          userProfile: userProfile, // Pass the full UserProfile
        ),
      ),
    );
  }

  // NEW: Getters for Admin Dashboard Overview
  int get _totalManagersCount => _allUsersInSystem
      .where((user) => user.role == 'Manager' && user.status == 'approved')
      .length;
  int get _totalWorkersCount => _allUsersInSystem
      .where((user) => user.role == 'Worker' && user.status == 'approved')
      .length;
  int get _totalLinesCount => _transmissionLines
      .length; // _transmissionLines are already filtered by role if not Admin
  int get _totalTowersInSystem => _transmissionLines
      .map((line) => line.computedTotalTowers)
      .fold(0, (sum, count) => sum + count);
  List<UserProfile> get _latestPendingRequests => _allUsersInSystem
      .where((user) => user.status == 'pending')
      .toList()
    ..sort((a, b) => (b.email).compareTo(
        a.email)); // Simple sort by email as createdAt not in UserProfile model

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    // Check for user approval status first
    if (_currentUser == null || _currentUser!.status != 'approved') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: colorScheme.error),
              const SizedBox(height: 20),
              Text(
                'Your account is not approved.',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Please wait for administrator approval or contact support.',
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

    // Check for user role
    if (_currentUser!.role == null ||
        (_currentUser!.role != 'Worker' &&
            _currentUser!.role != 'Manager' &&
            _currentUser!.role != 'Admin')) {
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
                'Your account role is not assigned or recognized.',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Please ensure your role (Worker, Manager, or Admin) is correctly assigned by an administrator in the Firebase Console.',
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

    // Calculate overall progress for the displayed data
    int totalCompletedTowers = 0;
    int totalOverallTowers = 0;

    if (_currentUser?.role == 'Worker') {
      for (var task in _tasksWithProgress) {
        totalCompletedTowers +=
            task.uploadedCompletedCount; // Use uploaded for overall progress
        totalOverallTowers += task.numberOfTowersToPatrol;
      }
    } else {
      // Manager or Admin: Use the filtered _transmissionLines
      final Map<String, int> surveyCountsByLineName = {};
      for (var record in _allFirebaseSurveyRecords) {
        if (record.status == 'uploaded') {
          surveyCountsByLineName[record.lineName] =
              (surveyCountsByLineName[record.lineName] ?? 0) + 1;
        }
      }
      for (var line in _transmissionLines) {
        // _transmissionLines is already filtered based on manager's assigned lines or all for admin
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
            'Survey Progress Overview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 15),

          // NEW: Admin-specific Overview Section
          if (_currentUser!.role == 'Admin')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Dashboard Summary',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatRow(
                            'Total Managers:',
                            _totalManagersCount.toString(),
                            Icons.person_outline,
                            colorScheme.primary),
                        _buildStatRow(
                            'Total Workers:',
                            _totalWorkersCount.toString(),
                            Icons.engineering,
                            colorScheme.secondary),
                        _buildStatRow(
                            'Total Lines:',
                            _totalLinesCount.toString(),
                            Icons.speed,
                            colorScheme.tertiary),
                        _buildStatRow(
                            'Total Towers in System:',
                            _totalTowersInSystem.toString(),
                            Icons.location_on,
                            colorScheme.onSurface),
                        _buildStatRow(
                            'Pending Approvals:',
                            _latestPendingRequests.length.toString(),
                            Icons.hourglass_empty,
                            colorScheme.error),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // NEW: Latest Pending Requests Section (Admin only)
                Text('Latest Pending Requests',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _latestPendingRequests.isEmpty
                    ? Text('No pending requests.',
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
                                    subtitle: Text('Status: ${user.status}'),
                                    // Actions for Admin to approve/reject from here would be ideal
                                  ),
                                ))
                            .toList(),
                      ),
                const SizedBox(height: 30),

                // NEW: Manager-wise List (Admin only)
                Text('Managers & Their Assignments',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _allUsersInSystem
                        .where((user) => user.role == 'Manager')
                        .isEmpty
                    ? Text('No managers found.',
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
                                  Text(
                                      'Lines Assigned: ${assignedLinesToManager.length}'),
                                  Text(
                                      'Total Towers Assigned: $totalTowersAssignedToManager'),
                                  Text(
                                      'Tasks Assigned by Them: ${_tasksWithProgress.where((task) => task.assignedByUserId == manager.id).length}'),
                                ],
                              ),
                              trailing: TextButton(
                                onPressed: () => _navigateToWorkerDetails(
                                    manager), // Pass manager profile
                                child: Text('View >',
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

          // Display relevant sections based on role (Progress by Worker / Lines under supervision)
          if (_currentUser!.role == 'Manager' || _currentUser!.role == 'Admin')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text('Progress by Worker:',
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
                              'No worker profiles found or assigned tasks to track.',
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
                                      'Lines Assigned: ${summary.linesAssigned}'),
                                  Text(
                                      'Lines Patrolled: ${summary.linesCompleted}'), // Changed from Completed
                                  Text(
                                      'Lines Working/Pending: ${summary.linesWorkingPending}'),
                                ],
                              ),
                              trailing: TextButton(
                                onPressed: () => _navigateToWorkerDetails(
                                    worker), // Pass worker profile
                                child: Text('View >',
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

          // Worker's Task Progress List or Manager/Admin's Line Progress List
          Text(
            _currentUser!.role == 'Worker'
                ? 'Your Assigned Tasks:'
                : 'Lines under your supervision:', // Changed for Manager/Admin
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 10),
          _tasksWithProgress.isEmpty && _transmissionLines.isEmpty
              ? Center(
                  child: Text(
                    _currentUser!.role == 'Worker'
                        ? 'No tasks assigned to you yet.'
                        : 'No lines or tasks available for your role within your assigned areas.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _currentUser?.role == 'Worker'
                      ? _tasksWithProgress.length
                      : _transmissionLines
                          .length, // Display lines for Manager/Admin
                  itemBuilder: (context, index) {
                    if (_currentUser?.role == 'Worker') {
                      final task = _tasksWithProgress[index];
                      // Find the associated TransmissionLine for current task
                      final TransmissionLine? taskLine =
                          _transmissionLines.firstWhereOrNull(
                              (line) => line.name == task.lineName);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        child: InkWell(
                          onTap: () {
                            if (taskLine != null) {
                              // Ensure line data exists before navigating
                              _navigateToLineDetailForTask(
                                  task, taskLine); // Pass TransmissionLine
                            } else {
                              SnackBarUtils.showSnackBar(
                                  context, 'Line data not found for this task.',
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
                                  'Task: ${task.lineName} - Towers: ${task.targetTowerRange}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Patrolled: ${task.localCompletedCount} / ${task.numberOfTowersToPatrol}', // Changed from Completed
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  'Uploaded: ${task.uploadedCompletedCount} / ${task.numberOfTowersToPatrol}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                    'Due: ${task.dueDate.toLocal().toString().split(' ')[0]} | Status: ${task.derivedStatus}',
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
                      // Manager or Admin
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
                          // Updated navigation for Manager/Admin to LinePatrollingDetailsScreen
                          onTap: () => _navigateToLinePatrollingDetails(line),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${line.name}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 8),
                                Text('Voltage: ${line.voltageLevel ?? 'N/A'}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                Text(
                                    'Towers: ${completedTowers} / ${totalTowers}',
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

// Simple data class to hold worker progress summary for dashboard
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
