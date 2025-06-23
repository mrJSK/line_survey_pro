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
import 'package:collection/collection.dart'
    as collection; // Corrected import for collection
import 'package:line_survey_pro/models/user_profile.dart'; // NEW: Import UserProfile

class ExportScreen extends StatefulWidget {
  final UserProfile? currentUserProfile; // NEW: Receive UserProfile

  const ExportScreen({super.key, required this.currentUserProfile});

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

  // Stores selected filter options for each filter field
  final Map<String, List<String>> _selectedFilters = {};

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

  // Filter options for export screen - UPDATED TO REFLECT NEW MODEL FIELDS
  final Map<String, List<String>> _filterOptions = {
    'overallIssueStatus': ['Issue', 'OK'],
    'missingTowerParts': ['Damaged', 'Missing', 'OK'],
    'soilCondition': [
      'Backfilling Required',
      'Revetment Wall Required',
      'Excavation Of Soil Required',
      'Eroded',
      'OK'
    ],
    'stubCopingLeg': ['Damaged', 'Missing', 'Corroded', 'Cracked', 'OK'],
    'earthing': [
      'Loose',
      'Corroded',
      'Disconnected',
      'Missing',
      'Damaged',
      'OK'
    ],
    'conditionOfTowerParts': [
      'Rusted',
      'Bent',
      'Hanging',
      'Damaged',
      'Cracked',
      'Broken',
      'OK'
    ],
    'statusOfInsulator': [
      'Broken',
      'Flashover',
      'Damaged',
      'Dirty',
      'Cracked',
      'OK'
    ],
    'jumperStatus': [
      'Damaged',
      'Bolt Missing',
      'Loose Bolt',
      'Spacers Missing',
      'Corroded',
      'OK'
    ],
    'hotSpots': ['OK', 'Minor', 'Moderate', 'Severe'],
    'numberPlate': ['Missing', 'Loose', 'Faded', 'Damaged', 'OK'],
    'dangerBoard': ['Missing', 'Loose', 'Faded', 'Damaged', 'OK'],
    'phasePlate': ['Missing', 'Loose', 'Faded', 'Damaged', 'OK'],
    'nutAndBoltCondition': ['Loose', 'Missing', 'Rusted', 'Damaged', 'OK'],
    'antiClimbingDevice': ['Intact', 'Damaged', 'Missing', 'OK'],
    'wildGrowth': [
      'OK',
      'Trimming Required',
      'Lopping Required',
      'Cutting Required'
    ],
    'birdGuard': ['Damaged', 'Missing', 'OK'],
    'birdNest': ['OK', 'Present'],
    'archingHorn': ['Bent', 'Broken', 'Missing', 'Corroded', 'OK'],
    'coronaRing': ['Bent', 'Broken', 'Missing', 'Corroded', 'OK'],
    'insulatorType': [
      'Broken',
      'Flashover',
      'Damaged',
      'Dirty',
      'Cracked',
      'OK'
    ],
    'opgwJointBox': ['Damaged', 'Open', 'Leaking', 'Corroded', 'OK'],
    // New fields from Line Survey Screen
    'building': ['OK', 'NOT OKAY'], // Boolean represented as OK/NOT OKAY
    'tree': ['OK', 'NOT OKAY'], // Boolean represented as OK/NOT OKAY
    'conditionOfOpgw': ['OK', 'Damaged'],
    'conditionOfEarthWire': ['OK', 'Damaged'],
    'conditionOfConductor': ['OK', 'Damaged'],
    'midSpanJoint': ['OK', 'Damaged'],
    'newConstruction': ['OK', 'NOT OKAY'], // Boolean
    'objectOnConductor': ['OK', 'NOT OKAY'], // Boolean
    'objectOnEarthwire': ['OK', 'NOT OKAY'], // Boolean
    'spacers': ['OK', 'Damaged'],
    'vibrationDamper': ['OK', 'Damaged'],
    // 'roadCrossing': [], // Removed old dropdown field
    'riverCrossing': ['OK', 'NOT OKAY'], // Boolean
    // 'electricalLine': [], // Removed old dropdown field
    'railwayCrossing': ['OK', 'NOT OKAY'], // Boolean
    'generalNotes': [], // Text field, no direct filter options

    // NEW: Road Crossing Fields
    'hasRoadCrossing': ['OK', 'NOT OKAY'], // Boolean
    'roadCrossingTypes': [
      'NH',
      'SH',
      'Chakk road',
      'Over Bridge',
      'Underpass'
    ], // List of strings
    'roadCrossingName': [], // Text field

    // NEW: Electrical Line Crossing Fields
    'hasElectricalLineCrossing': ['OK', 'NOT OKAY'], // Boolean
    'electricalLineTypes': [
      '400kV',
      '220kV',
      '132kV',
      '33kV',
      '11kV',
      'PTW'
    ], // List of strings
    'electricalLineNames': [], // Text field

    // NEW: Span Details Fields
    'spanLength': [], // Text field
    'bottomConductor': ['OK', 'Damaged'],
    'topConductor': ['OK', 'Damaged'],
  };

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

  // Use didUpdateWidget to react to currentUserProfile changes
  @override
  void didUpdateWidget(covariant ExportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if the user profile changes (e.g., needed for manager's assigned lines filter)
    if (widget.currentUserProfile != oldWidget.currentUserProfile) {
      _fetchAndCombineRecords();
    }
  }

  // Fetches records from Firestore and Local DB, then combines them.
  Future<void> _fetchAndCombineRecords() async {
    if (!mounted) return; // Prevent async operation if widget is disposed
    setState(() {
      _isLoading = true;
      _selectedImageRecordIds.clear();
    });

    _firestoreRecordsSubscription?.cancel();
    _transmissionLinesSubscription?.cancel();

    _transmissionLinesSubscription =
        _firestoreService.getTransmissionLinesStream().listen((lines) {
      if (mounted) {
        setState(() {
          _transmissionLines = lines;
          if (_selectedLineForShare == null && _transmissionLines.isNotEmpty) {
            _selectedLineForShare = _transmissionLines.first;
          }
        });
        _applyFiltersToRecords(); // Re-apply filter if lines data updates
      }
    }, onError: (error) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error streaming transmission lines: ${error.toString()}',
            isError: true);
      }
    });

    _firestoreRecordsSubscription =
        _surveyFirestoreService.streamAllSurveyRecords().listen(
      (firestoreRecords) async {
        if (!mounted) return;

        final allLocalRecords =
            await _localDatabaseService.getAllSurveyRecords();

        Map<String, SurveyRecord> combinedMap = {};
        for (var record in allLocalRecords) {
          combinedMap[record.id] = record;
        }
        for (var fRecord in firestoreRecords) {
          final localRecord = combinedMap[fRecord.id];
          if (localRecord != null) {
            combinedMap[fRecord.id] =
                localRecord.copyWith(status: fRecord.status);
          } else {
            combinedMap[fRecord.id] = fRecord;
          }
        }

        List<SurveyRecord> finalCombinedList = combinedMap.values.toList();
        finalCombinedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Filter based on manager's assigned lines if current user is a manager
        List<SurveyRecord> recordsToDisplay = [];
        if (widget.currentUserProfile?.role == 'Manager') {
          final Set<String> assignedLineNames = _transmissionLines
              .where((line) =>
                  widget.currentUserProfile!.assignedLineIds.contains(line.id))
              .map((line) => line.name)
              .toSet();
          recordsToDisplay = finalCombinedList
              .where((record) => assignedLineNames.contains(record.lineName))
              .toList();
        } else {
          recordsToDisplay =
              finalCombinedList; // Admins and Workers see all/their own
        }

        setState(() {
          _allRecords = recordsToDisplay; // Display the filtered list
          _groupedRecords = _groupRecordsByLineName(recordsToDisplay);
          _isLoading = false;
        });

        if (_allRecords.isEmpty && mounted) {
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
      cancelOnError: false,
    );
  }

  // Refactor applyFilters to be called when relevant data changes
  void _applyFiltersToRecords() {
    // This is called internally when _allRecords or _transmissionLines update.
    // It filters _allRecords based on role if needed (already done in _fetchAndCombineRecords)
    // and then applies the UI filters.
    if (!mounted) return;
    List<SurveyRecord> tempRecords = List.from(_allRecords);

    // Apply main text search filter (if any)
    if (_searchQuery.isNotEmpty) {
      final String lowerCaseQuery = _searchQuery.toLowerCase();
      tempRecords = tempRecords.where((record) {
        return record.towerNumber.toString().contains(lowerCaseQuery) ||
            record.lineName.toLowerCase().contains(lowerCaseQuery) ||
            (record.generalNotes?.toLowerCase().contains(lowerCaseQuery) ??
                false) ||
            (record.missingTowerParts?.toLowerCase().contains(lowerCaseQuery) ??
                false) ||
            (record.roadCrossingName?.toLowerCase().contains(lowerCaseQuery) ??
                false) || // NEW: Search in road crossing name
            (record.electricalLineNames?.any(
                    (name) => name.toLowerCase().contains(lowerCaseQuery)) ??
                false) || // NEW: Search in electrical line names
            (record.spanLength?.toLowerCase().contains(lowerCaseQuery) ??
                false); // NEW: Search in span length
      }).toList();
    }

    // Apply filter options from the drawer
    _selectedFilters.forEach((fieldName, selectedOptions) {
      if (selectedOptions.isEmpty) return;

      tempRecords = tempRecords.where((record) {
        if (fieldName == 'overallIssueStatus') {
          final bool isNotOkay = _isNotOkay(record);
          if (selectedOptions.contains('Issue') &&
              !selectedOptions.contains('OK')) {
            return isNotOkay;
          } else if (selectedOptions.contains('OK') &&
              !selectedOptions.contains('Issue')) {
            return !isNotOkay;
          }
          return true; // If both or neither 'OK'/'Issue' selected, don't filter by issue status
        } else {
          dynamic fieldValue = record.toMap()[fieldName];

          // Handle boolean fields which map 'true' to 'NOT OKAY' and 'false' to 'OK' in filter
          // Now using the actual boolean fields and mapping them to 'OK'/'NOT OKAY' for filtering
          if (fieldName == 'building') {
            fieldValue = (record.building == true ? 'NOT OKAY' : 'OK');
          } else if (fieldName == 'tree') {
            fieldValue = (record.tree == true ? 'NOT OKAY' : 'OK');
          } else if (fieldName == 'newConstruction') {
            fieldValue = (record.newConstruction == true ? 'NOT OKAY' : 'OK');
          } else if (fieldName == 'objectOnConductor') {
            fieldValue = (record.objectOnConductor == true ? 'NOT OKAY' : 'OK');
          } else if (fieldName == 'objectOnEarthwire') {
            fieldValue = (record.objectOnEarthwire == true ? 'NOT OKAY' : 'OK');
          } else if (fieldName == 'riverCrossing') {
            fieldValue = (record.riverCrossing == true ? 'NOT OKAY' : 'OK');
          } else if (fieldName == 'railwayCrossing') {
            fieldValue = (record.railwayCrossing == true ? 'NOT OKAY' : 'OK');
          } else if (fieldName == 'hasRoadCrossing') {
            // NEW: Handle hasRoadCrossing
            fieldValue = (record.hasRoadCrossing == true ? 'NOT OKAY' : 'OK');
          } else if (fieldName == 'hasElectricalLineCrossing') {
            // NEW: Handle hasElectricalLineCrossing
            fieldValue =
                (record.hasElectricalLineCrossing == true ? 'NOT OKAY' : 'OK');
          } else if (fieldName == 'roadCrossingTypes') {
            // NEW: Handle list of strings for roadCrossingTypes
            return record.roadCrossingTypes != null &&
                record.roadCrossingTypes!
                    .any((type) => selectedOptions.contains(type));
          } else if (fieldName == 'electricalLineTypes') {
            // NEW: Handle list of strings for electricalLineTypes
            return record.electricalLineTypes != null &&
                record.electricalLineTypes!
                    .any((type) => selectedOptions.contains(type));
          } else {
            // For other fields (String, int, etc.)
            fieldValue = record.toMap()[fieldName]?.toString();
          }

          return fieldValue != null && selectedOptions.contains(fieldValue);
        }
      }).toList();
    });

    setState(() {
      _allRecords = tempRecords; // Update displayed records
      _groupedRecords =
          _groupRecordsByLineName(tempRecords); // Re-group filtered records
    });
  }

  // Returns true if any of the main issue fields are not 'OK' or indicate a problem.
  bool _isNotOkay(SurveyRecord record) {
    // List of fields that indicate an issue if not 'OK'
    final List<String?> issueFields = [
      record.missingTowerParts,
      record.soilCondition,
      record.stubCopingLeg,
      record.earthing,
      record.conditionOfTowerParts,
      record.statusOfInsulator,
      record.jumperStatus,
      record.hotSpots,
      record.numberPlate,
      record.dangerBoard,
      record.phasePlate,
      record.nutAndBoltCondition,
      record.antiClimbingDevice,
      record.wildGrowth,
      record.birdGuard,
      record.birdNest,
      record.archingHorn,
      record.coronaRing,
      record.insulatorType,
      record.opgwJointBox,
      record.conditionOfOpgw,
      record.conditionOfEarthWire,
      record.conditionOfConductor,
      record.midSpanJoint,
      record.spacers,
      record.vibrationDamper,
      record.bottomConductor, // NEW: Check bottom conductor
      record.topConductor, // NEW: Check top conductor
      // 'roadCrossing' and 'electricalLine' old dropdowns are removed/replaced
    ];

    // Check for boolean fields that indicate NOT OKAY if true
    final bool hasNotOkayBool = (record.building == true) ||
        (record.tree == true) ||
        (record.newConstruction == true) ||
        (record.objectOnConductor == true) ||
        (record.objectOnEarthwire == true) ||
        (record.riverCrossing == true) ||
        (record.railwayCrossing == true) ||
        (record.hasRoadCrossing == true) || // NEW: Check hasRoadCrossing
        (record.hasElectricalLineCrossing ==
            true); // NEW: Check hasElectricalLineCrossing

    // If any issue field is not 'OK', 'Intact', or null/empty, consider it NOT OKAY
    for (final field in issueFields) {
      if (field != null &&
          field.isNotEmpty &&
          field != 'OK' &&
          field != 'Intact') {
        return true;
      }
    }

    return hasNotOkayBool;
  }

  // Helper function to check if any local images are available for sharing
  Future<bool> _hasLocalImagesAvailable() async {
    if (_allRecords.isEmpty) return false;
    for (var record in _allRecords) {
      if (record.photoPath.isNotEmpty &&
          await File(record.photoPath).exists()) {
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
      // Pass allTransmissionLines to generateCsvFile
      final csvFile = await FileService().generateCsvFile(_allRecords,
          allTransmissionLines: _transmissionLines);
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
      if (record.photoPath.isNotEmpty &&
          await File(record.photoPath).exists()) {
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
                  record.towerNumber.toString().contains(_searchQuery) ||
                  (record.roadCrossingName
                          ?.toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ??
                      false) || // NEW: search in road crossing name
                  (record.electricalLineNames?.any((name) => name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase())) ??
                      false); // NEW: search in electrical line names
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
                        labelText:
                            'Search Tower Number or Crossing Name', // NEW: Updated label
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
                      keyboardType: TextInputType
                          .text, // Changed to text to allow for names
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
                                        ? 'No records found matching search.' // NEW: Updated message
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
                                  subtitle: Column(
                                    // NEW: Display span length, bottom and top conductor
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Lat: ${record.latitude.toStringAsFixed(6)}, Lon: ${record.longitude.toStringAsFixed(6)}',
                                      ),
                                      if (record.spanLength != null &&
                                          record.spanLength!.isNotEmpty)
                                        Text(
                                            'Span Length: ${record.spanLength}'),
                                      if (record.bottomConductor != null &&
                                          record.bottomConductor!.isNotEmpty)
                                        Text(
                                            'Bottom Conductor: ${record.bottomConductor}'),
                                      if (record.topConductor != null &&
                                          record.topConductor!.isNotEmpty)
                                        Text(
                                            'Top Conductor: ${record.topConductor}'),
                                      if (record.roadCrossingName != null &&
                                          record.roadCrossingName!.isNotEmpty)
                                        Text(
                                            'Road Crossing: ${record.roadCrossingName}'),
                                      if (record.electricalLineNames != null &&
                                          record
                                              .electricalLineNames!.isNotEmpty)
                                        Text(
                                            'Electrical Lines: ${record.electricalLineNames!.join(', ')}'),
                                    ],
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
                                    collection.IterableExtension<SurveyRecord>(
                                            _allRecords)
                                        .firstWhereOrNull((r) =>
                                            r.id ==
                                            _selectedImageRecordIds.first);
                                if (selectedRecord != null) {
                                  final line = collection.IterableExtension<
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
                                if (record.photoPath.isNotEmpty) {
                                  // No need to explicitly check File(record.photoPath).exists() again
                                  // as recordsWithLocalImages already filters for this.
                                  final File? overlaidFile = await FileService()
                                      .addTextOverlayToImage(record);

                                  if (overlaidFile != null &&
                                      await overlaidFile.exists()) {
                                    photoCount++;
                                    imageFilesToShare
                                        .add(XFile(overlaidFile.path));

                                    // shareMessage.writeln(
                                    //     '*Photo $photoCount:* ${p.basename(record.photoPath)}');
                                    shareMessage.writeln(
                                        '  *Line:* ${record.lineName}, *Tower:* ${record.towerNumber}');
                                    shareMessage.writeln(
                                        '  *Latitude:* ${record.latitude.toStringAsFixed(6)}');
                                    shareMessage.writeln(
                                        'Longitude: *${record.longitude.toStringAsFixed(6)}');
                                    shareMessage.writeln(
                                        '  *Time:* ${record.timestamp.toLocal().toString().split('.')[0]}');
                                    shareMessage.writeln(
                                        '  *Status:* ${record.status.toUpperCase()}');

                                    // if (record.spanLength != null &&
                                    //     record.spanLength!.isNotEmpty) {
                                    //   // NEW: Add span length to share message
                                    //   shareMessage.writeln(
                                    //       '  *Span Length:* ${record.spanLength}');
                                    // }
                                    // if (record.bottomConductor != null &&
                                    //     record.bottomConductor!.isNotEmpty) {
                                    //   // NEW: Add bottom conductor to share message
                                    //   shareMessage.writeln(
                                    //       '  *Bottom Conductor:* ${record.bottomConductor}');
                                    // }
                                    // if (record.topConductor != null &&
                                    //     record.topConductor!.isNotEmpty) {
                                    //   // NEW: Add top conductor to share message
                                    //   shareMessage.writeln(
                                    //       '  *Top Conductor:* ${record.topConductor}');
                                    // }
                                    if (record.hasRoadCrossing == true &&
                                        record.roadCrossingName != null &&
                                        record.roadCrossingName!.isNotEmpty) {
                                      // NEW: Add road crossing details
                                      shareMessage.writeln(
                                          '  *Road Crossing:* ${record.roadCrossingName}');
                                      if (record.roadCrossingTypes != null &&
                                          record
                                              .roadCrossingTypes!.isNotEmpty) {
                                        shareMessage.writeln(
                                            '    *Types:* ${record.roadCrossingTypes!.join(', ')}');
                                      }
                                    }
                                    if (record.hasElectricalLineCrossing ==
                                            true &&
                                        record.electricalLineNames != null &&
                                        record
                                            .electricalLineNames!.isNotEmpty) {
                                      // NEW: Add electrical line details
                                      shareMessage.writeln(
                                          '  *Electrical Lines:* ${record.electricalLineNames!.join(', ')}');
                                      if (record.electricalLineTypes != null &&
                                          record.electricalLineTypes!
                                              .isNotEmpty) {
                                        shareMessage.writeln(
                                            '    *Types:* ${record.electricalLineTypes!.join(', ')}');
                                      }
                                    }

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

  // Modified _buildFabChild to use FloatingActionButton.extended and display Icon + Text
  Widget _buildFabChild(IconData iconData, String label, VoidCallback onPressed,
      {Color? backgroundColor, Color? foregroundColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      // Changed to FloatingActionButton.extended for icon + text
      child: FloatingActionButton.extended(
        heroTag: label, // Use label as heroTag
        onPressed: onPressed,
        tooltip: label, // Tooltip remains the label
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor:
            foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
        icon: Icon(iconData), // Icon part
        label: Text(label), // Text part
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
                                          if (record.spanLength != null &&
                                              record.spanLength!
                                                  .isNotEmpty) // NEW: Display span length
                                            Text(
                                                'Span Length: ${record.spanLength}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                          if (record.bottomConductor != null &&
                                              record.bottomConductor!
                                                  .isNotEmpty) // NEW: Display bottom conductor
                                            Text(
                                                'Bottom Conductor: ${record.bottomConductor}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                          if (record.topConductor != null &&
                                              record.topConductor!
                                                  .isNotEmpty) // NEW: Display top conductor
                                            Text(
                                                'Top Conductor: ${record.topConductor}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                          if (record.hasRoadCrossing == true &&
                                              record.roadCrossingName != null &&
                                              record.roadCrossingName!
                                                  .isNotEmpty) // NEW: Display road crossing name
                                            Text(
                                                'Road Crossing: ${record.roadCrossingName}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                          if (record.hasElectricalLineCrossing ==
                                                  true &&
                                              record.electricalLineNames !=
                                                  null &&
                                              record.electricalLineNames!
                                                  .isNotEmpty) // NEW: Display electrical line names
                                            Text(
                                                'Electrical Lines: ${record.electricalLineNames!.join(', ')}',
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
                                                future:
                                                    record.photoPath.isNotEmpty
                                                        ? File(record.photoPath)
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
                                        if (record.photoPath.isNotEmpty &&
                                            await File(record.photoPath)
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
      // Conditionally hide Floating Action Buttons if no records exist
      floatingActionButton: _allRecords.isEmpty
          ? null // Return null to hide the FAB when there are no records
          : Column(
              // Existing FAB column logic
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
                          'Share Images', // Text label for the button
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
                    'Export CSV', // Text label for the button
                    _exportAllRecordsToCsv,
                    backgroundColor: colorScheme.tertiary,
                    foregroundColor: colorScheme.onTertiary,
                  ),
                ),
                const SizedBox(height: 16),
                FloatingActionButton.extended(
                  onPressed: _toggleFab,
                  label: _isFabOpen
                      ? const Text('Close Menu')
                      : const Text('Actions'),
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
