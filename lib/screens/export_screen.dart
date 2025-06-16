// lib/screens/export_screen.dart
// Allows users to view, export to CSV, and share locally stored survey records and photos.
// Updated for consistent UI theming, individual record deletion, and separated export/share functionalities
// via a multi-action Floating Action Button, with an improved, scrollable, searchable image share modal.

import 'dart:io'; // For File operations
import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:line_survey_pro/models/survey_record.dart'; // SurveyRecord data model
import 'package:line_survey_pro/services/local_database_service.dart'; // Local database service (for deleting local records)
import 'package:line_survey_pro/services/file_service.dart'; // File service for CSV/sharing
import 'package:line_survey_pro/services/survey_firestore_service.dart'; // For fetching records from Firestore
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Snackbar utility
import 'package:share_plus/share_plus.dart'; // Share_plus for file sharing
import 'package:line_survey_pro/screens/view_photo_screen.dart'; // Screen to view a single photo
import 'package:line_survey_pro/models/transmission_line.dart'; // Needed for dropdown in modal
import 'dart:async'; // For StreamSubscription
import 'package:path/path.dart' as p; // For path.basename
import 'package:line_survey_pro/services/firestore_service.dart'; // NEW: Import FirestoreService to get real TransmissionLine objects

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen>
    with SingleTickerProviderStateMixin {
  List<SurveyRecord> _allRecords = []; // Combined records (local + Firestore)
  bool _isLoading = true; // State for loading records
  Map<String, List<SurveyRecord>> _groupedRecords =
      {}; // Records grouped by line name
  List<TransmissionLine> _transmissionLines =
      []; // List of transmission lines for dropdown

  // State for multi-action FAB
  bool _isFabOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  // Local state for image sharing modal
  TransmissionLine? _selectedLineForShare;
  final Set<String> _selectedImageRecordIds =
      {}; // For multi-selection in image share modal
  final TextEditingController _searchController =
      TextEditingController(); // For tower search
  String _searchQuery = '';

  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService();
  final LocalDatabaseService _localDatabaseService =
      LocalDatabaseService(); // For local file check and deletion
  final FirestoreService _firestoreService =
      FirestoreService(); // NEW: Instance for TransmissionLine fetching
  StreamSubscription?
      _firestoreRecordsSubscription; // Stream for Firestore records
  StreamSubscription?
      _transmissionLinesSubscription; // NEW: Stream for transmission lines

  @override
  void initState() {
    super.initState();
    _fetchAndCombineRecords(); // Call combine method

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutBack,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _firestoreRecordsSubscription?.cancel();
    _transmissionLinesSubscription?.cancel(); // NEW: Cancel subscription
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // Fetches records from Firestore and Local DB, then combines them.
  Future<void> _fetchAndCombineRecords() async {
    setState(() {
      _isLoading = true;
      _selectedImageRecordIds.clear();
    });

    _firestoreRecordsSubscription?.cancel();
    _transmissionLinesSubscription?.cancel(); // Cancel existing subscription

    // NEW: Listen to transmission lines
    _transmissionLinesSubscription =
        _firestoreService.getTransmissionLinesStream().listen((lines) {
      if (mounted) {
        setState(() {
          _transmissionLines = lines;
          // Set default selected line if it's the first load
          if (_selectedLineForShare == null && _transmissionLines.isNotEmpty) {
            _selectedLineForShare = _transmissionLines.first;
          }
        });
      }
    }, onError: (error) {
      if (mounted)
        SnackBarUtils.showSnackBar(
            context, 'Error streaming transmission lines: ${error.toString()}',
            isError: true);
    });

    _firestoreRecordsSubscription =
        _surveyFirestoreService.streamAllSurveyRecords().listen(
      (firestoreRecords) async {
        if (!mounted) return;

        // Fetch all local records to get photoPaths and 'saved' statuses
        final allLocalRecords =
            await _localDatabaseService.getAllSurveyRecords();

        // Combine logic: Create a map to hold the final combined records.
        // Prioritize local records for photoPath, and Firestore for 'uploaded' status.
        Map<String, SurveyRecord> combinedMap = {};

        // 1. Add all local records to the map. These will have photoPaths.
        for (var record in allLocalRecords) {
          combinedMap[record.id] = record;
        }

        // 2. Iterate through Firestore records.
        for (var fRecord in firestoreRecords) {
          final localRecord = combinedMap[fRecord.id];
          if (localRecord != null) {
            // Record exists both locally and in Firestore.
            // Take Firestore's status, but preserve local photoPath.
            combinedMap[fRecord.id] = localRecord.copyWith(
              status: fRecord.status, // Always take status from Firestore
            );
          } else {
            // If the record is in Firestore but NOT locally, add it.
            // Its photoPath will be empty, indicating no local image.
            combinedMap[fRecord.id] = fRecord;
          }
        }

        List<SurveyRecord> finalCombinedList = combinedMap.values.toList();
        // Sort by timestamp for consistent display (most recent first)
        finalCombinedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        setState(() {
          _allRecords = finalCombinedList; // Display the combined list
          _groupedRecords = _groupRecordsByLineName(finalCombinedList);
          _isLoading = false;
        });

        // Update the SnackBar message based on actual data
        if (finalCombinedList.isEmpty && mounted) {
          SnackBarUtils.showSnackBar(context,
              'No survey records found. Conduct a survey first and save/upload it!',
              isError: false);
        } else if (allLocalRecords.isNotEmpty &&
            firestoreRecords.isEmpty &&
            mounted) {
          SnackBarUtils.showSnackBar(context,
              'You have local records. Upload them to the cloud for full sync!',
              isError: false);
        }
      },
      onError: (error) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Error fetching records: ${error.toString()}',
              isError: true);
          setState(() {
            _isLoading = false;
          });
        }
        print('ExportScreen error fetching records: $error');
      },
      cancelOnError:
          false, // Keep listening even on errors (e.g., permission issues for some queries)
    );
  }

  // Helper function to check if any local images are available for sharing
  Future<bool> _hasLocalImagesAvailable() async {
    if (_allRecords.isEmpty) return false;
    for (var record in _allRecords) {
      if (record.photoPath != null &&
          record.photoPath!.isNotEmpty &&
          await File(record.photoPath!).exists()) {
        return true;
      }
    }
    return false;
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
    grouped.forEach((key, value) {
      value.sort((a, b) => a.towerNumber.compareTo(b.towerNumber));
    });
    return grouped;
  }

  // Exports ALL records to a CSV file.
  Future<void> _exportAllRecordsToCsv() async {
    _toggleFab();

    if (_allRecords.isEmpty) {
      SnackBarUtils.showSnackBar(context, 'No records to export to CSV.');
      return;
    }

    try {
      final csvFile = await FileService().generateCsvFile(_allRecords);
      if (csvFile != null) {
        await Share.shareXFiles([XFile(csvFile.path)],
            text: 'Line Survey Data Export');
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'All records exported to CSV and share dialog shown.');
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
            context, 'Error exporting CSV: ${e.toString()}',
            isError: true);
      }
    }
  }

  // Shares SELECTED images via a modal.
  Future<void> _shareSelectedImagesFromModal(BuildContext context) async {
    _toggleFab();

    // Filter only records that have a valid local photoPath
    final List<SurveyRecord> recordsWithLocalImages = [];
    for (var record in _allRecords) {
      if (record.photoPath != null &&
          record.photoPath!.isNotEmpty &&
          await File(record.photoPath!).exists()) {
        recordsWithLocalImages.add(record);
      }
    }

    if (recordsWithLocalImages.isEmpty) {
      SnackBarUtils.showSnackBar(
          context, 'No images available locally to share.',
          isError: false);
      return;
    }

    _selectedImageRecordIds.clear();
    _searchController.clear();
    setState(() {
      // Keep existing _selectedLineForShare if it's still in _transmissionLines
      _selectedLineForShare = _transmissionLines.contains(_selectedLineForShare)
          ? _selectedLineForShare
          : (_transmissionLines.isNotEmpty ? _transmissionLines.first : null);
      _searchQuery = '';
    });

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      useRootNavigator: true,
      builder: (BuildContext sheetContext) {
        final TextEditingController localSearchController =
            TextEditingController();
        localSearchController.text = _searchQuery;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            final List<SurveyRecord> recordsForSelectedLine =
                _selectedLineForShare != null
                    ? recordsWithLocalImages
                        .where((r) => r.lineName == _selectedLineForShare!.name)
                        .toList()
                    : [];

            final List<SurveyRecord> filteredRecords =
                recordsForSelectedLine.where((record) {
              return _searchQuery.isEmpty ||
                  record.towerNumber.toString().contains(_searchQuery);
            }).toList();

            return AnimatedSize(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Select Images to Share',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: colorScheme.primary),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<TransmissionLine>(
                      value: _selectedLineForShare,
                      decoration: InputDecoration(
                        labelText: 'Select Line',
                        prefixIcon:
                            Icon(Icons.line_axis, color: colorScheme.primary),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      items: _transmissionLines.map((line) {
                        return DropdownMenuItem(
                          value: line,
                          child: Text(
                            line.name, // Display consolidated name
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (line) {
                        modalSetState(() {
                          _selectedLineForShare = line;
                          _selectedImageRecordIds.clear();
                          localSearchController.clear();
                          _searchQuery = '';
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a line';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: localSearchController,
                      decoration: InputDecoration(
                        labelText: 'Search Tower Number',
                        prefixIcon:
                            Icon(Icons.search, color: colorScheme.primary),
                        suffixIcon: localSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  modalSetState(() {
                                    localSearchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        modalSetState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: filteredRecords.isEmpty
                          ? Center(
                              child: Text(
                                _selectedLineForShare == null
                                    ? 'Please select a transmission line.'
                                    : (_searchQuery.isNotEmpty
                                        ? 'No towers found matching search.'
                                        : 'No images for this line available locally.'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontStyle: FontStyle.italic),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredRecords.length,
                              itemBuilder: (context, index) {
                                final record = filteredRecords[index];
                                final isSelected =
                                    _selectedImageRecordIds.contains(record.id);
                                return CheckboxListTile(
                                  title: Text('Tower: ${record.towerNumber}'),
                                  subtitle: Text(
                                    'Lat: ${record.latitude.toStringAsFixed(6)}, Lon: ${record.longitude.toStringAsFixed(6)}',
                                  ),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    modalSetState(() {
                                      if (value == true) {
                                        _selectedImageRecordIds.add(record.id);
                                      } else {
                                        _selectedImageRecordIds
                                            .remove(record.id);
                                      }
                                    });
                                  },
                                  activeColor: colorScheme.secondary,
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _selectedImageRecordIds.isEmpty
                          ? null
                          : () async {
                              final List<XFile> imageFilesToShare = [];
                              final StringBuffer shareMessage = StringBuffer();

                              String commonLineName = '';
                              if (_selectedImageRecordIds.isNotEmpty) {
                                // Find the actual TransmissionLine object
                                final selectedRecord =
                                    IterableExtension<SurveyRecord>(_allRecords)
                                        .firstWhereOrNull((r) =>
                                            r.id ==
                                            _selectedImageRecordIds.first);
                                if (selectedRecord != null) {
                                  final line = IterableExtension<
                                          TransmissionLine>(_transmissionLines)
                                      .firstWhereOrNull((l) =>
                                          l.name == selectedRecord.lineName);
                                  commonLineName =
                                      line?.name ?? selectedRecord.lineName;
                                }
                              }

                              // Add a main heading for the shared data
                              shareMessage.writeln(
                                  '*--- Line Survey Photos for $commonLineName ---*');
                              shareMessage.writeln('');

                              int photoCount = 0;
                              for (String recordId in _selectedImageRecordIds) {
                                final record = recordsWithLocalImages
                                    .firstWhere((r) => r.id == recordId);
                                if (record.photoPath != null &&
                                    record.photoPath!.isNotEmpty) {
                                  final File file = File(record.photoPath!);
                                  final File? overlaidFile = await FileService()
                                      .addTextOverlayToImage(record);

                                  if (overlaidFile != null &&
                                      await overlaidFile.exists()) {
                                    photoCount++;
                                    imageFilesToShare
                                        .add(XFile(overlaidFile.path));

                                    shareMessage.writeln(
                                        '*Photo ${photoCount}:* ${p.basename(record.photoPath!)}');
                                    shareMessage.writeln(
                                        '  *Line:* ${record.lineName}, *Tower:* ${record.towerNumber}');
                                    shareMessage.writeln(
                                        '  *Lat/Lon:* ${record.latitude.toStringAsFixed(6)}, ${record.longitude.toStringAsFixed(6)}');
                                    shareMessage.writeln(
                                        '  *Time:* ${record.timestamp.toLocal().toString().split('.')[0]}');
                                    shareMessage.writeln(
                                        '  *Status:* ${record.status.toUpperCase()}');
                                    shareMessage.writeln(
                                        '-----------------------------------');
                                    shareMessage.writeln('');
                                  } else {
                                    print(
                                        'Warning: Could not create overlay for image file for record ID: $recordId at ${record.photoPath}. Skipping this image from share.');
                                  }
                                } else {
                                  print(
                                      'Warning: photoPath is null or empty for record ID: $recordId. Skipping this image from share.');
                                }
                              }

                              if (imageFilesToShare.isEmpty) {
                                SnackBarUtils.showSnackBar(context,
                                    'No valid images with overlays found for selected records to share.',
                                    isError: true);
                                return;
                              }

                              try {
                                await Share.shareXFiles(imageFilesToShare,
                                    text: shareMessage.toString().trim());
                                if (mounted) {
                                  SnackBarUtils.showSnackBar(context,
                                      'Selected images and details shared.');
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (mounted) {
                                  SnackBarUtils.showSnackBar(context,
                                      'Error sharing images: ${e.toString()}',
                                      isError: true);
                                }
                              } finally {
                                localSearchController.dispose();
                              }
                            },
                      icon: const Icon(Icons.share),
                      label: Text(
                          'Share Selected (${_selectedImageRecordIds.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Deletes a single record. Deletes local file, then details from local DB and Firestore.
  Future<void> _deleteSingleRecord(SurveyRecord recordToDelete) async {
    final bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text(
                  'Are you sure you want to delete record for Tower ${recordToDelete.towerNumber} on ${recordToDelete.lineName}? This action cannot be undone.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmDelete) {
      return;
    }

    try {
      // 1. Delete photo file from local storage
      final photoFile = File(recordToDelete.photoPath);
      if (await photoFile.exists()) {
        await photoFile.delete();
      } else {
        print(
            'Warning: Local photo file not found for record ID: ${recordToDelete.id}');
      }

      // 2. Delete record from local database
      await _localDatabaseService.deleteSurveyRecord(recordToDelete.id);

      // 3. Delete record details from Firestore
      await _surveyFirestoreService
          .deleteSurveyRecordDetails(recordToDelete.id);

      if (mounted) {
        SnackBarUtils.showSnackBar(context,
            'Record for Tower ${recordToDelete.towerNumber} deleted successfully.');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error deleting record: ${e.toString()}',
            isError: true);
      }
      print('Export screen delete record error: $e');
    } finally {
      // Data is streamed, so UI will automatically update.
    }
  }

  Widget _buildFabChild(IconData icon, String tooltip, VoidCallback onPressed,
      {Color? backgroundColor, Color? foregroundColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: FloatingActionButton.small(
        heroTag: tooltip,
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor:
            foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
        child: Icon(icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _allRecords.isEmpty
                      ? Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 40),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(
                              child: Text(
                                'No survey records found. Conduct a survey first and save/upload it!',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6)),
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchAndCombineRecords,
                          color: colorScheme.primary,
                          child: ListView.builder(
                            itemCount: _groupedRecords.keys.length,
                            itemBuilder: (context, index) {
                              final lineName =
                                  _groupedRecords.keys.elementAt(index);
                              final recordsInLine = _groupedRecords[lineName]!;
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                elevation: 4,
                                child: ExpansionTile(
                                  initiallyExpanded: true,
                                  title: Text(
                                    'Line: $lineName (${recordsInLine.length} records)',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  children: recordsInLine.map((record) {
                                    return ListTile(
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
                                              'Lat: ${record.latitude.toStringAsFixed(6)}, Lon: ${record.longitude.toStringAsFixed(6)}',
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
                                              Text(
                                                  'Status: ${record.status.toUpperCase()}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                          color: record
                                                                      .status ==
                                                                  'uploaded'
                                                              ? Colors.green
                                                              : colorScheme
                                                                  .tertiary)),
                                              const SizedBox(width: 8),
                                              FutureBuilder<bool>(
                                                future: record.photoPath !=
                                                            null &&
                                                        record.photoPath!
                                                            .isNotEmpty
                                                    ? File(record.photoPath!)
                                                        .exists()
                                                    : Future.value(false),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState ==
                                                          ConnectionState
                                                              .done &&
                                                      snapshot.data == true) {
                                                    return Icon(
                                                      Icons.image,
                                                      color:
                                                          colorScheme.secondary,
                                                      size: 16,
                                                    );
                                                  }
                                                  return const SizedBox
                                                      .shrink();
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete_forever,
                                            color: colorScheme.error),
                                        onPressed: () =>
                                            _deleteSingleRecord(record),
                                        tooltip: 'Delete this record',
                                      ),
                                      onTap: () async {
                                        if (record.photoPath != null &&
                                            record.photoPath!.isNotEmpty &&
                                            await File(record.photoPath!)
                                                .exists()) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ViewPhotoScreen(
                                                      imagePath:
                                                          record.photoPath),
                                            ),
                                          );
                                        } else {
                                          SnackBarUtils.showSnackBar(context,
                                              'Image not available locally for this record. Only details are synced.',
                                              isError: false);
                                        }
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FutureBuilder<bool>(
            future: _hasLocalImagesAvailable(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.data == true) {
                return ScaleTransition(
                  scale: _expandAnimation,
                  alignment: Alignment.bottomRight,
                  child: _buildFabChild(
                    Icons.image,
                    'Share Images',
                    () => _shareSelectedImagesFromModal(context),
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          ScaleTransition(
            scale: _expandAnimation,
            alignment: Alignment.bottomRight,
            child: _buildFabChild(
              Icons.description,
              'Export All CSV',
              _exportAllRecordsToCsv,
              backgroundColor: colorScheme.tertiary,
              foregroundColor: colorScheme.onTertiary,
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: _toggleFab,
            label:
                _isFabOpen ? const Text('Close Menu') : const Text('Actions'),
            icon: Icon(_isFabOpen ? Icons.close : Icons.menu_open),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
