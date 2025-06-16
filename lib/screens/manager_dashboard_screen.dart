// lib/screens/manager_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/transmission_line.dart';
import 'package:line_survey_pro/models/user_profile.dart';
import 'package:line_survey_pro/models/task.dart';
import 'package:line_survey_pro/models/survey_record.dart'; // For completed tasks count
import 'package:uuid/uuid.dart'; // For ad-hoc task creation
import 'package:line_survey_pro/screens/line_detail_screen.dart'; // For ad-hoc survey navigation
import 'package:line_survey_pro/screens/manager_worker_detail_screen.dart'; // To navigate to worker details
import 'package:line_survey_pro/screens/line_patrolling_details_screen.dart'; // To navigate to line details
import 'package:line_survey_pro/screens/assign_task_screen.dart'; // To assign new tasks

class ManagerDashboardScreen extends StatefulWidget {
  // Data passed from HomeScreenState
  final UserProfile currentUser;
  final List<TransmissionLine>
      transmissionLines; // Already filtered for this manager
  final List<Task> tasksWithProgress; // Already filtered for this manager
  final List<SurveyRecord>
      allFirebaseSurveyRecords; // All records (will be filtered for display)
  final List<UserProfile> allWorkers; // All worker profiles

  const ManagerDashboardScreen({
    super.key,
    required this.currentUser,
    required this.transmissionLines,
    required this.tasksWithProgress,
    required this.allFirebaseSurveyRecords,
    required this.allWorkers,
  });

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  // Helper method for worker summaries (replicated from DashboardTab)
  Map<String, WorkerProgressSummary> _getWorkerProgressSummaries() {
    final Map<String, WorkerProgressSummary> summaries = {};
    // allWorkers is already filtered for 'Worker' role and 'approved' status in HomeScreenState
    final List<UserProfile> approvedWorkers = widget.allWorkers;

    for (var worker in approvedWorkers) {
      int linesAssigned = 0;
      int linesCompleted = 0;
      int linesWorkingPending = 0;
      Set<String> completedLines = {};
      Set<String> workingLines = {};

      final workerTasks = widget.tasksWithProgress
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

  // Navigate to Assign New Task screen
  void _assignNewTask() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AssignTaskScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final workerProgressSummaries = _getWorkerProgressSummaries();

    // Calculate overall progress for manager's assigned lines
    int totalCompletedTowers = 0;
    int totalOverallTowers = 0;
    for (var record in widget.allFirebaseSurveyRecords) {
      if (record.status == 'uploaded' &&
          widget.transmissionLines
              .any((line) => line.name == record.lineName)) {
        totalCompletedTowers++;
      }
    }
    for (var line in widget.transmissionLines) {
      totalOverallTowers += line.computedTotalTowers;
    }
    double overallProgressPercentage = totalOverallTowers > 0
        ? totalCompletedTowers / totalOverallTowers
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assign New Task Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          const SizedBox(height: 20),

          // Progress by Worker Section
          Text('Progress by Worker:',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          widget.allWorkers.isEmpty
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
                  itemCount: widget.allWorkers.length,
                  itemBuilder: (context, index) {
                    final worker = widget.allWorkers[index];
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

          // Lines under your supervision (for Managers)
          Text('Lines under your supervision:',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          widget.transmissionLines.isEmpty
              ? Center(
                  child: Text(
                    'No lines assigned to you.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.transmissionLines.length,
                  itemBuilder: (context, index) {
                    final line = widget.transmissionLines[index];
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
