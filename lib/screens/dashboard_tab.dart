// lib/screens/dashboard_tab.dart
// Displays survey progress and provides a form for new survey entries.
// Fetches transmission lines from Firestore, gets current GPS, and navigates to camera.
// Redesigned for a more modern and professional UI.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:geolocator/geolocator.dart'; // For GPS coordinates and distance calculation
import 'package:line_survey_pro/models/transmission_line.dart'; // TransmissionLine model
import 'package:line_survey_pro/services/local_database_service.dart'; // Local database interaction
import 'package:line_survey_pro/services/firestore_service.dart'; // Firestore service
import 'package:line_survey_pro/services/location_service.dart'; // Location service
import 'package:line_survey_pro/screens/camera_screen.dart'; // Camera screen navigation
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Snackbar utility
import 'package:line_survey_pro/services/permission_service.dart'; // Permission service for location
import 'dart:async'; // For StreamSubscription
import 'package:line_survey_pro/models/survey_record.dart'; // Import SurveyRecord for validation
import 'package:line_survey_pro/screens/line_detail_screen.dart'; // New: Import LineDetailScreen

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  List<TransmissionLine> _transmissionLines =
      []; // List of available transmission lines
  bool _isLoadingLines = true; // State for loading transmission lines
  Map<String, int> _surveyProgress = {}; // Map: Line Name -> Towers Completed

  final FirestoreService _firestoreService = FirestoreService();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();

  StreamSubscription?
      _linesSubscription; // To manage the Firestore stream subscription

  @override
  void initState() {
    super.initState();
    _listenToTransmissionLines(); // Start listening to lines from Firestore
    _loadSurveyProgress(); // Load local survey progress on init
  }

  @override
  void dispose() {
    _linesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _listenToTransmissionLines() async {
    setState(() {
      _isLoadingLines = true;
    });
    _linesSubscription?.cancel();

    _linesSubscription = _firestoreService.getTransmissionLinesStream().listen(
      (lines) {
        if (mounted) {
          setState(() {
            _transmissionLines = lines;
            _isLoadingLines = false;
          });
          if (lines.isEmpty && mounted) {
            SnackBarUtils.showSnackBar(context,
                'No transmission lines found. Add new lines from the console or an admin screen.',
                isError: false);
          }
        }
      },
      onError: (error) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Error loading transmission lines: ${error.toString()}',
              isError: true);
          setState(() {
            _isLoadingLines = false;
          });
        }
      },
      cancelOnError: true,
    );
  }

  Future<void> _loadSurveyProgress() async {
    final progress = await _localDatabaseService.getSurveyProgress();
    if (mounted) {
      setState(() {
        _surveyProgress = progress;
      });
    }
  }

  void _navigateToLineDetail(TransmissionLine line) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => LineDetailScreen(line: line),
      ),
    )
        .then((_) {
      _loadSurveyProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    int totalCompletedTowers = 0;
    int totalOverallTowers = 0;
    for (var line in _transmissionLines) {
      totalCompletedTowers += _surveyProgress[line.name] ?? 0;
      totalOverallTowers += line.totalTowers;
    }
    double overallProgress = totalOverallTowers > 0
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
          _isLoadingLines
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _transmissionLines.isEmpty
                  ? Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            'No transmission lines found.\nAdd lines from console to get started!',
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
                      itemCount: _transmissionLines.length,
                      itemBuilder: (context, index) {
                        final line = _transmissionLines[index];
                        final completedTowers = _surveyProgress[line.name] ?? 0;
                        final totalTowers = line.totalTowers;
                        final progress = totalTowers > 0
                            ? completedTowers / totalTowers
                            : 0.0;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 4,
                          child: InkWell(
                            onTap: () => _navigateToLineDetail(line),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
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
                      },
                    ),
          const SizedBox(height: 30),

          // Section 2: Overall Survey Progress Graph
          Text(
            'Overall Survey Progress',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 15),
          Card(
            margin: EdgeInsets.zero,
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(
                  20.0), // Padding for content inside the card
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double indicatorSize = constraints.maxWidth * 0.45;
                      if (indicatorSize > 120) indicatorSize = 120;
                      if (indicatorSize < 80) indicatorSize = 80;

                      return Container(
                        width: double.infinity, // Take full available width
                        // Removed decoration (color and border) to make it seamless with the Card
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
                                    value: overallProgress,
                                    strokeWidth: indicatorSize / 10,
                                    backgroundColor:
                                        colorScheme.primary.withOpacity(0.2),
                                    color: colorScheme.primary,
                                  ),
                                ),
                                // Text for percentage, perfectly centered
                                Text(
                                  '${(overallProgress * 100).toStringAsFixed(1)}%',
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
                            const SizedBox(
                                height:
                                    8), // Spacing between chart and tower count
                            // Tower count text, placed below the chart
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
