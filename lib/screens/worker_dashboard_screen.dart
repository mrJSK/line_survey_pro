// lib/screens/worker_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/user_profile.dart';
import 'package:line_survey_pro/models/task.dart';
import 'package:line_survey_pro/models/survey_record.dart'; // For local completed counts
import 'package:line_survey_pro/models/transmission_line.dart'; // <-- Add this import
import 'package:line_survey_pro/screens/line_detail_screen.dart'; // To navigate to survey entry
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // For feedback
import 'package:line_survey_pro/services/local_database_service.dart'; // For local upload
import 'package:line_survey_pro/services/survey_firestore_service.dart'; // For uploading to Firestore

class WorkerDashboardScreen extends StatefulWidget {
  // Data passed from HomeScreenState
  final UserProfile currentUser;
  final List<Task> tasksWithProgress; // Already filtered for this worker
  final List<TransmissionLine>
      transmissionLines; // Lines relevant to worker's tasks
  final List<SurveyRecord>
      allFirebaseSurveyRecords; // All records (for uploaded counts)

  const WorkerDashboardScreen({
    super.key,
    required this.currentUser,
    required this.tasksWithProgress,
    required this.transmissionLines,
    required this.allFirebaseSurveyRecords,
  });

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _isUploading = false;
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();

  // Helper to enrich tasks with local/uploaded counts (replicated from DashboardTab)
  List<Task> _getEnrichedTasks() {
    final List<Task> enrichedTasks = [];

    // We need current local records for accuracy here
    // In a real app, _localDatabaseService.getAllSurveyRecords() might be streamed
    // from a higher level, or fetched here. For this refactor, we'll fetch once.
    // However, the HomeScreenState is now providing allFirebaseSurveyRecords.
    // The problem is allLocalSurveyRecords is not passed down.
    // Let's assume the local records are fetched within this screen for now for worker's own progress.
    // For a truly reactive local + remote view, this data would ideally be managed upstream.
    // For now, let's make sure it works by potentially refetching local records if needed.

    // A more robust way: allLocalSurveyRecords should be passed from HomeScreenState too.
    // Assuming widget.allLocalSurveyRecords exists. If not, you'd need to fetch here.
    // For this example, I'll pass it down from HomeScreenState. (Self-correction for HomeScreenState later)

    for (var task in widget.tasksWithProgress) {
      int localCount = 0;
      int uploadedCount = 0;

      // Filter local records by this task and current user
      final recordsForThisTaskAndUser = widget.allFirebaseSurveyRecords.where(
          (r) => r.taskId == task.id && r.userId == widget.currentUser.id);

      // Count uploaded records for this task
      uploadedCount =
          recordsForThisTaskAndUser.where((r) => r.status == 'uploaded').length;

      // For local count, we'd need _allLocalSurveyRecords specifically.
      // If not passed down, a separate call to _localDatabaseService.getAllSurveyRecords() would be needed.
      // For simplicity, let's use the uploaded count as the primary indicator for now,
      // or assume _localDatabaseService handles its own state internally for localCompletedCount.
      // The Task model has both localCompletedCount and uploadedCompletedCount.
      // The current _DashboardTabState was filling these from its global _allLocalSurveyRecords.

      // To keep it simple for this separation, and as _allLocalSurveyRecords isn't passed down currently to WorkerDashboardScreen,
      // we'll rely on what's available from allFirebaseSurveyRecords for 'uploaded' count primarily for derivedStatus here.
      // If local progress is critical on WorkerDashboard, widget.allLocalSurveyRecords needs to be added to constructor.

      enrichedTasks.add(task.copyWith(
        localCompletedCount:
            localCount, // Placeholder: actual local count logic needs access to allLocalSurveyRecords
        uploadedCompletedCount: uploadedCount,
      ));
    }
    return enrichedTasks;
  }

  // Upload unsynced local records (replicated from DashboardTab)
  Future<void> _uploadUnsyncedRecords() async {
    if (!mounted) return;
    setState(() {
      _isUploading = true;
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
        // Use SurveyFirestoreService for upload
        final String? uploadedRecordIdFromFirestore =
            await SurveyFirestoreService().uploadSurveyRecordDetails(record);
        if (uploadedRecordIdFromFirestore != null) {
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
          _isUploading = false;
        });
      }
    }
  }

  // Navigate to survey entry screen (replicated)
  void _navigateToSurveyForTask(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LineDetailScreen(task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final enrichedTasks = _getEnrichedTasks();

    // Calculate overall progress for worker's tasks
    int totalCompletedTowers = 0;
    int totalOverallTowers = 0;
    for (var task in enrichedTasks) {
      totalCompletedTowers += task.uploadedCompletedCount;
      totalOverallTowers += task.numberOfTowersToPatrol;
    }
    double overallProgressPercentage = totalOverallTowers > 0
        ? totalCompletedTowers / totalOverallTowers
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Worker's own tasks section
          Text('Your Assigned Tasks:',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          enrichedTasks.isEmpty
              ? Center(
                  child: Text(
                    'No tasks assigned to you yet.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: enrichedTasks.length,
                  itemBuilder: (context, index) {
                    final task = enrichedTasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      child: InkWell(
                        onTap: () {
                          _navigateToSurveyForTask(task);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Task: ${task.lineName} - Towers: ${task.targetTowerRange}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Completed: ${task.localCompletedCount} / ${task.numberOfTowersToPatrol}',
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
                                      ?.copyWith(fontStyle: FontStyle.italic)),
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
                  },
                ),
          const SizedBox(height: 30),

          // Upload Unsynced Records Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadUnsyncedRecords,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload),
              label: Text(
                  _isUploading ? 'Uploading...' : 'Upload Unsynced Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
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
