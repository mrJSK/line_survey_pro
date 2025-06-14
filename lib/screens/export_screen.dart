// lib/screens/export_screen.dart
// Allows users to view, export to CSV, and share locally stored survey records and photos.
// Adapted for local-only storage.

import 'dart:io'; // For File operations
import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:line_survey_pro/models/survey_record.dart'; // SurveyRecord data model
import 'package:line_survey_pro/services/local_database_service.dart'; // Local database service
// Removed: import 'package:line_survey_pro/services/firestore_service.dart';
import 'package:line_survey_pro/services/file_service.dart'; // File service for CSV/sharing
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Snackbar utility
import 'package:share_plus/share_plus.dart'; // Share_plus for file sharing
import 'package:line_survey_pro/screens/view_photo_screen.dart'; // Screen to view a single photo

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  List<SurveyRecord> _allRecords = []; // All survey records (local)
  bool _isLoading = true; // State for loading records
  final Set<String> _selectedRecordIds =
      {}; // Set of IDs of selected records for export/share
  Map<String, List<SurveyRecord>> _groupedRecords =
      {}; // Records grouped by line name

  @override
  void initState() {
    super.initState();
    _fetchRecords(); // Fetch records when the screen initializes
  }

  // Fetches all survey records from the local database.
  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true; // Show loading indicator
      _selectedRecordIds.clear(); // Clear any previous selections
    });
    try {
      final records = await LocalDatabaseService().getAllSurveyRecords();
      if (mounted) {
        setState(() {
          _allRecords = records; // Update the list of all records
          _groupedRecords = _groupRecordsByLineName(records); // Group records
          _isLoading = false; // Hide loading indicator
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error fetching records: ${e.toString()}',
            isError: true);
        setState(() {
          _isLoading = false; // Hide loading indicator even on error
        });
      }
    }
  }

  // Helper function to group survey records by their line name.
  Map<String, List<SurveyRecord>> _groupRecordsByLineName(
      List<SurveyRecord> records) {
    final Map<String, List<SurveyRecord>> grouped = {};
    for (var record in records) {
      if (!grouped.containsKey(record.lineName)) {
        grouped[record.lineName] = [];
      }
      grouped[record.lineName]!.add(record);
    }
    // Optionally sort records within each group, e.g., by tower number.
    grouped.forEach((key, value) {
      value.sort((a, b) => a.towerNumber.compareTo(b.towerNumber));
    });
    return grouped;
  }

  // Removed: _uploadPendingToCloud() function

  // Exports selected records to a CSV file and opens a share dialog.
  Future<void> _exportSelectedAsCsv() async {
    if (_selectedRecordIds.isEmpty) {
      SnackBarUtils.showSnackBar(
          context, 'No records selected for CSV export.');
      return;
    }

    final selectedRecords = _allRecords
        .where((record) => _selectedRecordIds.contains(record.id))
        .toList();

    if (selectedRecords.isEmpty) {
      SnackBarUtils.showSnackBar(
          context, 'No valid records selected for CSV export.');
      return;
    }

    try {
      final csvFile = await FileService().generateCsvFile(selectedRecords);
      if (csvFile != null) {
        // Use share_plus to share the generated CSV file.
        await Share.shareXFiles([XFile(csvFile.path)],
            text: 'Line Survey Data Export');
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'CSV exported and share dialog shown.');
        }
      } else {
        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'Failed to generate CSV file.',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error sharing CSV: ${e.toString()}',
            isError: true);
      }
    }
  }

  // Shares locally stored images of selected records.
  Future<void> _shareSelectedImages() async {
    if (_selectedRecordIds.isEmpty) {
      SnackBarUtils.showSnackBar(
          context, 'No records selected for image sharing.');
      return;
    }

    final selectedRecords = _allRecords
        .where((record) => _selectedRecordIds.contains(record.id))
        .toList();

    if (selectedRecords.isEmpty) {
      SnackBarUtils.showSnackBar(
          context, 'No valid records selected for image sharing.');
      return;
    }

    final List<XFile> imageFiles = [];
    for (var record in selectedRecords) {
      final file = File(record.photoPath);
      // Check if the image file actually exists before adding it to the list.
      if (await file.exists()) {
        imageFiles.add(XFile(file.path));
      } else {
        print(
            'Warning: Image file not found for record ID: ${record.id} at ${record.photoPath}');
      }
    }

    if (imageFiles.isEmpty) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'No image files found for selected records.',
            isError: true);
      }
      return;
    }

    try {
      await Share.shareXFiles(imageFiles, text: 'Line Survey Photos');
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Selected images shared.');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error sharing images: ${e.toString()}',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Survey Data'),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loader while fetching records
          : Column(
              children: [
                // Action buttons for CSV and image sharing.
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Removed: Upload Pending button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportSelectedAsCsv,
                          icon: const Icon(Icons.description),
                          label: const Text('Export CSV'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareSelectedImages,
                          icon: const Icon(Icons.image),
                          label: const Text('Share Images'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _allRecords.isEmpty
                      ? const Center(
                          child: Text(
                              'No survey records found. Conduct a survey first!'),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchRecords, // Pull to refresh records
                          child: ListView.builder(
                            itemCount: _groupedRecords.keys.length,
                            itemBuilder: (context, index) {
                              final lineName =
                                  _groupedRecords.keys.elementAt(index);
                              final recordsInLine = _groupedRecords[lineName]!;
                              return Card(
                                margin: const EdgeInsets.all(8),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ExpansionTile(
                                  initiallyExpanded: true, // Expand by default
                                  title: Text(
                                    'Line: $lineName (${recordsInLine.length} records)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.blueGrey[800]),
                                  ),
                                  children: recordsInLine.map((record) {
                                    final isSelected =
                                        _selectedRecordIds.contains(record.id);
                                    return ListTile(
                                      leading: Checkbox(
                                        value: isSelected,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedRecordIds.add(record.id);
                                            } else {
                                              _selectedRecordIds
                                                  .remove(record.id);
                                            }
                                          });
                                        },
                                      ),
                                      title: Text(
                                          'Tower: ${record.towerNumber}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Lat: ${record.latitude.toStringAsFixed(4)}, Lon: ${record.longitude.toStringAsFixed(4)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                          Text(
                                              'Time: ${record.timestamp.toLocal().toString().split('.')[0]}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                          Row(
                                            children: [
                                              Text('Status: ',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall),
                                              const Icon(
                                                Icons
                                                    .check_circle, // Always 'saved' locally
                                                color: Colors.green,
                                                size: 16,
                                              ),
                                              Text(record.status.toUpperCase(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                          color: Colors.green)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        // On tap, navigate to ViewPhotoScreen to display the image.
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ViewPhotoScreen(
                                                    imagePath:
                                                        record.photoPath),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
