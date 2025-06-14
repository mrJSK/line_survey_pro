// lib/screens/export_screen.dart
// Allows users to view, export to CSV, and share locally stored survey records and photos.
// Updated for consistent UI theming, individual record deletion, and separated export/share functionalities
// via a multi-action Floating Action Button, with an improved, scrollable, searchable image share modal.

import 'dart:io'; // For File operations
import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:line_survey_pro/models/survey_record.dart'; // SurveyRecord data model
import 'package:line_survey_pro/services/local_database_service.dart'; // Local database service
import 'package:line_survey_pro/services/file_service.dart'; // File service for CSV/sharing
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Snackbar utility
import 'package:share_plus/share_plus.dart'; // Share_plus for file sharing
import 'package:line_survey_pro/screens/view_photo_screen.dart'; // Screen to view a single photo
import 'package:line_survey_pro/models/transmission_line.dart'; // Needed for dropdown in modal

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen>
    with SingleTickerProviderStateMixin {
  List<SurveyRecord> _allRecords = []; // All survey records (local)
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

  @override
  void initState() {
    super.initState();
    _fetchRecords(); // Fetch records when the screen initializes

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

  // Fetches all survey records from the local database and transmission lines.
  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true; // Show loading indicator
      _selectedImageRecordIds
          .clear(); // Clear selections from previous modal sessions
    });
    try {
      final records = await LocalDatabaseService().getAllSurveyRecords();
      // Fetch distinct line names from existing records to populate the dropdown
      final uniqueLineNames = records.map((r) => r.lineName).toSet();
      _transmissionLines = uniqueLineNames
          .map((name) => TransmissionLine(id: name, name: name, totalTowers: 0))
          .toList();
      _transmissionLines.sort(
          (a, b) => a.name.compareTo(b.name)); // Sort for consistent order

      if (mounted) {
        setState(() {
          _allRecords = records; // Update the list of all records
          _groupedRecords = _groupRecordsByLineName(records); // Group records
          _isLoading = false; // Hide loading indicator
          _selectedLineForShare =
              _transmissionLines.isNotEmpty ? _transmissionLines.first : null;
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
    grouped.forEach((key, value) {
      value.sort((a, b) => a.towerNumber.compareTo(b.towerNumber));
    });
    return grouped;
  }

  // Exports ALL records to a CSV file.
  Future<void> _exportAllRecordsToCsv() async {
    _toggleFab(); // Close the FAB menu

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
    _toggleFab(); // Close the FAB menu

    if (_allRecords.isEmpty) {
      SnackBarUtils.showSnackBar(context, 'No records to share images from.');
      return;
    }

    // Reset selection state for the modal each time it's opened
    _selectedImageRecordIds.clear();
    _searchController.clear(); // Clear search query
    setState(() {
      _selectedLineForShare =
          _transmissionLines.isNotEmpty ? _transmissionLines.first : null;
      _searchQuery = ''; // Reset search query state
    });

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow modal to take more height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // --- START: MODIFICATIONS FOR SMOOTHER ANIMATION ---
      useRootNavigator: true, // Ensures the modal appears above all content
      // --- END: MODIFICATIONS FOR SMOOTHER ANIMATION ---
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          // Use StatefulBuilder for state management within the modal
          builder: (BuildContext context, StateSetter modalSetState) {
            final List<SurveyRecord> recordsForSelectedLine =
                _selectedLineForShare != null
                    ? _groupedRecords[_selectedLineForShare!.name] ?? []
                    : [];

            // Filter records based on search query
            final List<SurveyRecord> filteredRecords =
                recordsForSelectedLine.where((record) {
              return _searchQuery.isEmpty ||
                  record.towerNumber.toString().contains(_searchQuery);
            }).toList();

            return AnimatedSize(
              // Keep AnimatedSize for smooth transitions of content changes within the modal
              duration: const Duration(
                  milliseconds:
                      600), // This controls internal content animation, not sheet slide
              curve: Curves.easeInOut,
              child: Container(
                // Use Container to define height for scrollability
                height: MediaQuery.of(context).size.height *
                    0.8, // Take 80% of screen height
                padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom +
                      20, // Adjust for keyboard
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
                      isExpanded:
                          true, // Important: Allows the dropdown to take available width
                      items: _transmissionLines.map((line) {
                        return DropdownMenuItem(
                          value: line,
                          child: Text(
                            line.name,
                            overflow: TextOverflow
                                .ellipsis, // Truncate long text with ellipsis
                            maxLines: 1, // Ensure text stays on a single line
                          ),
                        );
                      }).toList(),
                      onChanged: (line) {
                        modalSetState(() {
                          _selectedLineForShare = line;
                          _selectedImageRecordIds
                              .clear(); // Clear selection when line changes
                          _searchController
                              .clear(); // Clear search on line change
                          _searchQuery = ''; // Reset search query
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
                    // Tower Number Search Field
                    TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Tower Number',
                        prefixIcon:
                            Icon(Icons.search, color: colorScheme.primary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  modalSetState(() {
                                    _searchController.clear();
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
                      // Use Expanded for the ListView to occupy available space
                      child: filteredRecords.isEmpty
                          ? Center(
                              child: Text(
                                _selectedLineForShare == null
                                    ? 'Please select a transmission line.'
                                    : (_searchQuery.isNotEmpty
                                        ? 'No towers found matching search.'
                                        : 'No records for this line.'),
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
                                    'Lat: ${record.latitude.toStringAsFixed(6)}, Lon: ${record.longitude.toStringAsFixed(6)}', // Fixed to 6 decimal places
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
                              for (String recordId in _selectedImageRecordIds) {
                                final record = _allRecords
                                    .firstWhere((r) => r.id == recordId);
                                final file = File(record.photoPath);
                                if (await file.exists()) {
                                  imageFilesToShare.add(XFile(file.path));
                                } else {
                                  print(
                                      'Warning: Image file not found for record ID: $recordId at ${record.photoPath}');
                                }
                              }

                              if (imageFilesToShare.isEmpty) {
                                SnackBarUtils.showSnackBar(context,
                                    'No valid image files found for selected records.',
                                    isError: true);
                                return;
                              }

                              try {
                                await Share.shareXFiles(imageFilesToShare,
                                    text: 'Selected Line Survey Photos');
                                if (mounted) {
                                  SnackBarUtils.showSnackBar(
                                      context, 'Selected images shared.');
                                  Navigator.pop(context); // Close the modal
                                }
                              } catch (e) {
                                if (mounted) {
                                  SnackBarUtils.showSnackBar(context,
                                      'Error sharing images: ${e.toString()}',
                                      isError: true);
                                }
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

  // Deletes a single record from the local database.
  Future<void> _deleteSingleRecord(SurveyRecord recordToDelete) async {
    final bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text(
                  'Are you sure you want to delete record for Tower ${recordToDelete.towerNumber} on ${recordToDelete.lineName}? This action cannot be undone and will also delete the photo.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.error, // Red for delete
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed

    if (!confirmDelete) {
      return;
    }

    try {
      // Delete photo file from storage
      final photoFile = File(recordToDelete.photoPath);
      if (await photoFile.exists()) {
        await photoFile.delete();
      }
      // Delete record from database
      await LocalDatabaseService().deleteSurveyRecord(recordToDelete.id);
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
    } finally {
      await _fetchRecords(); // Refresh list after deletion attempt
    }
  }

  // Custom FAB buttons for the speed dial
  Widget _buildFabChild(IconData icon, String tooltip, VoidCallback onPressed,
      {Color? backgroundColor, Color? foregroundColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: FloatingActionButton.small(
        heroTag: tooltip, // Unique tag for each FAB in a SpeedDial-like setup
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
      // Removed AppBar from here. The AppBar should be managed by the parent Scaffold (e.g., HomeScreen).
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
                                'No survey records found. Conduct a survey first!',
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
                          onRefresh: _fetchRecords,
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
                                              'Lat: ${record.latitude.toStringAsFixed(6)}, Lon: ${record.longitude.toStringAsFixed(6)}', // Fixed to 6 decimal places
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
                                              Icon(
                                                Icons.check_circle,
                                                color: colorScheme.secondary,
                                                size: 16,
                                              ),
                                              Text(record.status.toUpperCase(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                          color: colorScheme
                                                              .secondary)),
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
                                      onTap: () {
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
      // Multi-action Floating Action Button (FAB)
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.end, // Align to end for right placement
        children: [
          // Share Images FAB (sub-FAB)
          ScaleTransition(
            scale: _expandAnimation,
            alignment: Alignment.bottomRight,
            child: _buildFabChild(
              Icons.image,
              'Share Images',
              () => _shareSelectedImagesFromModal(context),
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
            ),
          ),
          // Export CSV FAB (sub-FAB)
          ScaleTransition(
            scale: _expandAnimation,
            alignment: Alignment.bottomRight,
            child: _buildFabChild(
              Icons.description, // Changed icon to description for CSV
              'Export All CSV',
              _exportAllRecordsToCsv,
              backgroundColor: colorScheme.tertiary,
              foregroundColor: colorScheme.onTertiary,
            ),
          ),
          const SizedBox(height: 16), // Spacing between sub-FABs and main FAB
          // Main FAB to toggle the menu
          FloatingActionButton.extended(
            onPressed: _toggleFab,
            label:
                _isFabOpen ? const Text('Close Menu') : const Text('Actions'),
            icon: Icon(_isFabOpen
                ? Icons.close
                : Icons.menu_open), // Icon changes based on state
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
          ),
        ],
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Place FAB at bottom end
    );
  }
}
