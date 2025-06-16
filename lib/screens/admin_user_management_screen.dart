// lib/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/transmission_line.dart';
import 'package:line_survey_pro/models/user_profile.dart';
import 'package:line_survey_pro/models/task.dart';
import 'package:line_survey_pro/models/survey_record.dart';
import 'package:uuid/uuid.dart'; // For ad-hoc task creation
import 'package:line_survey_pro/screens/line_detail_screen.dart'; // For ad-hoc survey navigation
import 'package:line_survey_pro/screens/manager_worker_detail_screen.dart'; // To navigate to worker details
import 'package:line_survey_pro/screens/line_patrolling_details_screen.dart'; // To navigate to line details

class AdminDashboardScreen extends StatefulWidget {
  // Data passed from HomeScreenState
  final List<UserProfile> allUsersInSystem;
  final List<TransmissionLine> allTransmissionLines;
  final List<Task> allTasks;
  final List<SurveyRecord> allFirebaseSurveyRecords;

  const AdminDashboardScreen({
    super.key,
    required this.allUsersInSystem,
    required this.allTransmissionLines,
    required this.allTasks,
    required this.allFirebaseSurveyRecords,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Getters for Admin Dashboard Overview
  int get _totalManagersCount => widget.allUsersInSystem
      .where((user) => user.role == 'Manager' && user.status == 'approved')
      .length;
  int get _totalWorkersCount => widget.allUsersInSystem
      .where((user) => user.role == 'Worker' && user.status == 'approved')
      .length;
  int get _totalLinesCount => widget.allTransmissionLines.length;
  int get _totalTowersInSystem => widget.allTransmissionLines
      .map((line) => line.computedTotalTowers)
      .fold(0, (sum, count) => sum + count);
  List<UserProfile> get _latestPendingRequests =>
      widget.allUsersInSystem.where((user) => user.status == 'pending').toList()
        ..sort((a, b) => (a.email).compareTo(b.email));

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

  // Helper method for worker summaries (replicated from DashboardTab)
  Map<String, WorkerProgressSummary> _getWorkerProgressSummaries() {
    final Map<String, WorkerProgressSummary> summaries = {};
    // allWorkers is already filtered for 'Worker' role and 'approved' status in HomeScreenState
    final List<UserProfile> approvedWorkers = widget.allUsersInSystem
        .where((user) => user.role == 'Worker' && user.status == 'approved')
        .toList();

    for (var worker in approvedWorkers) {
      int linesAssigned = 0;
      int linesCompleted = 0;
      int linesWorkingPending = 0;
      Set<String> completedLines = {};
      Set<String> workingLines = {};

      final workerTasks = widget.allTasks
          .where((task) => task.assignedToUserId == worker.id)
          .toList();

      linesAssigned = workerTasks.map((t) => t.lineName).toSet().length;

      for (var task in workerTasks) {
        final completedTowersForTask = widget.allFirebaseSurveyRecords
            .where((record) =>
                record.lineName == task.lineName &&
                record.taskId == task.id &&
                record.status == 'uploaded')
            .length;

        final Task tempTask =
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
    return summaries;
  }

  // Navigate to Worker details screen (replicated)
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

  // Navigate to Line Patrolling Details screen (replicated)
  void _navigateToLinePatrollingDetails(TransmissionLine line) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LinePatrollingDetailsScreen(line: line),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final workerProgressSummaries = _getWorkerProgressSummaries();

    // Calculate overall progress for all lines in the system (Admin view)
    int totalCompletedTowersOverall = 0;
    for (var record in widget.allFirebaseSurveyRecords) {
      if (record.status == 'uploaded') {
        totalCompletedTowersOverall++;
      }
    }
    double overallProgressPercentage = _totalTowersInSystem > 0
        ? totalCompletedTowersOverall / _totalTowersInSystem
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin Dashboard Summary Section
          Text('Admin Dashboard Summary',
              style: Theme.of(context).textTheme.headlineSmall),
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
                  _buildStatRow('Total Workers:', _totalWorkersCount.toString(),
                      Icons.engineering, colorScheme.secondary),
                  _buildStatRow('Total Lines:', _totalLinesCount.toString(),
                      Icons.speed, colorScheme.tertiary),
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

          // Latest Pending Requests Section
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
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(user.email),
                              subtitle: Text('Status: ${user.status}'),
                              // Add actions like approve/reject here if desired
                            ),
                          ))
                      .toList(),
                ),
          const SizedBox(height: 30),

          // Managers & Their Assignments
          Text('Managers & Their Assignments',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          widget.allUsersInSystem
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
                  itemCount: widget.allUsersInSystem
                      .where((user) => user.role == 'Manager')
                      .length,
                  itemBuilder: (context, index) {
                    final manager = widget.allUsersInSystem
                        .where((user) => user.role == 'Manager')
                        .elementAt(index);
                    final assignedLinesToManager = widget.allTransmissionLines
                        .where(
                            (line) => manager.assignedLineIds.contains(line.id))
                        .toList();
                    final totalTowersAssignedToManager = assignedLinesToManager
                        .map((line) => line.computedTotalTowers)
                        .fold(0, (sum, count) => sum + count);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 0),
                      elevation: 4,
                      child: ListTile(
                        title: Text(manager.displayName ?? manager.email,
                            style: Theme.of(context).textTheme.titleMedium),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Lines Assigned: ${assignedLinesToManager.length}'),
                            Text(
                                'Total Towers Assigned: $totalTowersAssignedToManager'),
                            Text(
                                'Tasks Assigned by Them: ${widget.allTasks.where((task) => task.assignedByUserId == manager.id).length}'),
                          ],
                        ),
                        trailing: TextButton(
                          onPressed: () => _navigateToWorkerDetails(manager),
                          child: Text('View >',
                              style: TextStyle(color: colorScheme.primary)),
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 30),

          // Progress by Worker
          Text('Progress by Worker:',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          widget.allUsersInSystem
                  .where((user) =>
                      user.role == 'Worker' && user.status == 'approved')
                  .isEmpty
              ? Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No worker profiles found or assigned tasks to track.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurface.withOpacity(0.7)),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.allUsersInSystem
                      .where((user) =>
                          user.role == 'Worker' && user.status == 'approved')
                      .length,
                  itemBuilder: (context, index) {
                    final worker = widget.allUsersInSystem
                        .where((user) =>
                            user.role == 'Worker' && user.status == 'approved')
                        .elementAt(index);
                    final summary = workerProgressSummaries[worker.id];

                    if (summary == null) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 0),
                      elevation: 4,
                      child: ListTile(
                        title: Text(worker.displayName ?? worker.email,
                            style: Theme.of(context).textTheme.titleMedium),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lines Assigned: ${summary.linesAssigned}'),
                            Text('Lines Completed: ${summary.linesCompleted}'),
                            Text(
                                'Lines Working/Pending: ${summary.linesWorkingPending}'),
                          ],
                        ),
                        trailing: TextButton(
                          onPressed: () => _navigateToWorkerDetails(worker),
                          child: Text('View >',
                              style: TextStyle(color: colorScheme.primary)),
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 30),

          // Lines under your supervision (All lines for Admin)
          Text('Lines under your supervision:',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          widget.allTransmissionLines.isEmpty
              ? Center(
                  child: Text(
                    'No lines available in the system.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.allTransmissionLines.length,
                  itemBuilder: (context, index) {
                    final line = widget.allTransmissionLines[index];
                    final completedTowers = widget.allFirebaseSurveyRecords
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
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text(
                                  'Towers: ${completedTowers} / ${totalTowers}',
                                  style: Theme.of(context).textTheme.bodyLarge),
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
                  },
                ),
          const SizedBox(height: 30),

          // Overall Survey Progress Graph
          Text('Overall Survey Progress',
              style: Theme.of(context).textTheme.headlineSmall),
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
                              '$totalCompletedTowersOverall / $_totalTowersInSystem Towers',
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
