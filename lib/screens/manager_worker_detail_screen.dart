// lib/screens/manager_worker_detail_screen.dart
// This screen now displays details for both Workers and Managers,
// depending on the UserProfile passed to it.

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/user_profile.dart'; // Import UserProfile
import 'package:line_survey_pro/models/survey_record.dart';
import 'package:line_survey_pro/models/transmission_line.dart'; // NEW: For manager's assigned lines
import 'package:line_survey_pro/models/task.dart'; // NEW: For manager's assigned tasks

import 'package:line_survey_pro/services/survey_firestore_service.dart';
import 'package:line_survey_pro/services/firestore_service.dart'; // NEW: For fetching transmission lines
import 'package:line_survey_pro/services/task_service.dart'; // NEW: For fetching tasks assigned by manager
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'dart:async';
import 'dart:io';

class ManagerWorkerDetailScreen extends StatefulWidget {
  final UserProfile userProfile; // Now accepts a full UserProfile

  const ManagerWorkerDetailScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<ManagerWorkerDetailScreen> createState() =>
      _ManagerWorkerDetailScreenState();
}

class _ManagerWorkerDetailScreenState extends State<ManagerWorkerDetailScreen> {
  // Common state variables
  bool _isLoading = true;
  // NEW: Flags to track loading status of manager-specific data streams
  bool _linesLoaded = false;
  bool _tasksLoaded = false;

  // Data specific to Worker view
  List<SurveyRecord> _allWorkerRecords =
      []; // All records by this worker from Firestore
  List<SurveyRecord> _filteredRecords = []; // Records after applying filters
  // Initialize 'healthyStatus' filter to 'NOT OKAY' by default
  final Map<String, Set<String>> _selectedFilters = {
    'healthyStatus': {'NOT OKAY'}
  };

  // Data specific to Manager view
  List<TransmissionLine> _managedLines = []; // Lines this manager is assigned
  List<Task> _assignedTasksByManager = []; // Tasks assigned by this manager

  // Services
  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService();
  final FirestoreService _firestoreService = FirestoreService(); // NEW
  final TaskService _taskService = TaskService(); // NEW

  // Stream Subscriptions
  StreamSubscription? _surveyRecordsSubscription;
  StreamSubscription? _linesSubscription; // NEW
  StreamSubscription? _tasksSubscription; // NEW

  // Define all possible options for filters
  final Map<String, List<String>> _filterOptions = {
    'healthyStatus': ['OK', 'NOT OKAY'], // NEW: Primary filter, reordered
    'missingTowerParts': ['Damaged', 'Missing', 'OK'], // Updated options
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
    'building': ['OK', 'NOT OKAY'], // OK=false, NOT OKAY=true
    'tree': ['OK', 'NOT OKAY'], // OK=false, NOT OKAY=true
    'conditionOfOpgw': ['OK', 'Damaged'],
    'conditionOfEarthWire': ['OK', 'Damaged'],
    'conditionOfConductor': ['OK', 'Damaged'],
    'midSpanJoint': ['OK', 'Damaged'],
    'newConstruction': ['OK', 'NOT OKAY'], // OK=false, NOT OKAY=true
    'objectOnConductor': ['OK', 'NOT OKAY'], // OK=false, NOT OKAY=true
    'objectOnEarthwire': ['OK', 'NOT OKAY'], // OK=false, NOT OKAY=true
    'spacers': ['OK', 'Damaged'],
    'vibrationDamper': ['OK', 'Damaged'],
    'roadCrossing': [
      'NH',
      'SH',
      'Chakk road',
      'Over Bridge',
      'Underpass',
      'OK',
      'NOT OKAY'
    ], // Adding OK/NOT OK for general status
    'riverCrossing': ['OK', 'NOT OKAY'], // OK=false, NOT OKAY=true
    'electricalLine': [
      '400kV',
      '220kV',
      '132kV',
      '33kV',
      '11kV',
      'PTW',
      'OK',
      'NOT OKAY'
    ], // Adding OK/NOT OK for general status
    'railwayCrossing': ['OK', 'NOT OKAY'], // OK=false, NOT OKAY=true
    // General Notes is text, not suitable for direct filter dropdown
  };

  @override
  void initState() {
    super.initState();
    _loadDataBasedOnRole();
  }

  @override
  void dispose() {
    _surveyRecordsSubscription?.cancel();
    _linesSubscription?.cancel(); // NEW
    _tasksSubscription?.cancel(); // NEW
    super.dispose();
  }

  Future<void> _loadDataBasedOnRole() async {
    setState(() {
      _isLoading = true;
      _linesLoaded = false; // Reset flags
      _tasksLoaded = false;
    });

    try {
      if (widget.userProfile.role == 'Worker') {
        _surveyRecordsSubscription?.cancel();
        _surveyRecordsSubscription = _surveyFirestoreService
            .streamSurveyRecordsForUser(widget.userProfile.id)
            .listen(
          (records) {
            if (mounted) {
              setState(() {
                _allWorkerRecords = records;
                _applyFilters(); // Apply filters whenever new data comes in
                _isLoading = false; // Worker loading finished here
              });
            }
          },
          onError: (error) {
            if (mounted) {
              SnackBarUtils.showSnackBar(
                  context, 'Error loading worker records: ${error.toString()}',
                  isError: true);
              setState(() {
                _isLoading = false; // Worker loading finished on error
              });
            }
            print('ManagerWorkerDetailScreen error streaming records: $error');
          },
        );
      } else if (widget.userProfile.role == 'Manager') {
        _linesSubscription?.cancel();
        _linesSubscription =
            _firestoreService.getTransmissionLinesStream().listen((allLines) {
          if (mounted) {
            setState(() {
              _managedLines = allLines
                  .where((line) =>
                      widget.userProfile.assignedLineIds.contains(line.id))
                  .toList();
              _linesLoaded = true; // Lines data delivered
              _checkAllManagerDataLoaded();
            });
          }
        }, onError: (error) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
                context, 'Error loading manager lines: ${error.toString()}',
                isError: true);
            _linesLoaded = true; // Treat error as delivered
            _checkAllManagerDataLoaded();
          }
          print('ManagerWorkerDetailScreen error streaming lines: $error');
        });

        _tasksSubscription?.cancel();
        _tasksSubscription = _taskService.streamAllTasks().listen((allTasks) {
          if (mounted) {
            setState(() {
              _assignedTasksByManager = allTasks
                  .where(
                      (task) => task.assignedByUserId == widget.userProfile.id)
                  .toList();
              _tasksLoaded = true; // Tasks data delivered
              _checkAllManagerDataLoaded();
            });
          }
        }, onError: (error) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
                context, 'Error loading manager tasks: ${error.toString()}',
                isError: true);
            _tasksLoaded = true; // Treat error as delivered
            _checkAllManagerDataLoaded();
          }
          print('ManagerWorkerDetailScreen error streaming tasks: $error');
        });
      } else {
        // Handle other roles gracefully (e.g., Admin clicking on another Admin)
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'No specific details to display for this role.',
              isError: false);
          setState(() {
            _isLoading = false; // Loading finished for other roles immediately
          });
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error loading user details: ${e.toString()}',
            isError: true);
        setState(() {
          _isLoading = false; // General error also finishes loading
        });
      }
      print('ManagerWorkerDetailScreen general data load error: $e');
    }
  }

  // NEW: Helper to check if all manager-specific data streams have completed
  void _checkAllManagerDataLoaded() {
    if (mounted && _linesLoaded && _tasksLoaded) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // NEW: Helper to determine if a SurveyRecord is 'NOT OKAY' (has any issues)
  bool _isNotOkay(SurveyRecord record) {
    // Terms that explicitly indicate NO issue
    const Set<String> nonIssueTerms = {
      'ok',
      'good',
      'intact',
      'not applicable'
    };

    // Keywords/phrases that explicitly indicate a PROBLEM.
    const Set<String> problemKeywords = {
      'missing', 'damaged', 'rusted', 'bent', 'hanging', 'cracked', 'broken',
      'flashover', 'dirty', 'loose', 'bolt missing', 'spacers missing',
      'corroded',
      'faded', 'disconnected', 'open', 'leaking',
      'present', // For birdNestOptions (if value is 'Present' it's an issue according to new list)
      'trimming required', 'lopping required',
      'cutting required', // For wildGrowth
      'minor', 'moderate', 'severe', // For hotSpots
      'backfilling required', 'revetment wall required',
      'excavation of soil required', 'eroded', // For soil condition
      'not okay', // Explicit 'NOT OKAY' for boolean fields
    };

    // Helper to check string fields
    bool checkStringField(String? value) {
      if (value == null ||
          value.isEmpty ||
          nonIssueTerms.contains(value.toLowerCase())) {
        return false; // Null, empty, or explicit non-issue
      }
      final lowerCaseValue = value.toLowerCase();

      if (nonIssueTerms.contains(lowerCaseValue)) {
        return false; // Explicitly a non-issue
      }

      // Check if the field value contains any specific problem keyword
      for (final keyword in problemKeywords) {
        if (lowerCaseValue.contains(keyword)) {
          return true;
        }
      }

      // Specific checks for values that are issues but might not be caught by generic keywords
      // e.g., for Insulator Type, certain types might be 'Broken' which is covered by problemKeywords
      // but 'OK' is also in the list. So, if it's not 'OK' and it's one of the problematic types, it's an issue.
      if (record.insulatorType != null &&
          ['broken', 'flashover', 'damaged', 'dirty', 'cracked']
              .contains(record.insulatorType!.toLowerCase())) {
        return true;
      }

      return false; // No issue found in this field
    }

    // Helper to check boolean fields (true means 'NOT OKAY' for these contexts)
    bool checkBooleanField(bool? value) {
      return value == true;
    }

    // --- Check all fields for 'NOT OKAY' conditions ---

    // Patrolling Details
    if (checkStringField(record.missingTowerParts) ||
        checkStringField(record.soilCondition) ||
        checkStringField(record.stubCopingLeg) ||
        checkStringField(record.earthing) ||
        checkStringField(record.conditionOfTowerParts) ||
        checkStringField(record.statusOfInsulator) ||
        checkStringField(record.jumperStatus) ||
        checkStringField(record.hotSpots) ||
        checkStringField(record.numberPlate) ||
        checkStringField(record.dangerBoard) ||
        checkStringField(record.phasePlate) ||
        checkStringField(record.nutAndBoltCondition) ||
        checkStringField(record.antiClimbingDevice) ||
        checkStringField(record.wildGrowth) ||
        checkStringField(record.birdGuard) ||
        checkStringField(record.birdNest) ||
        checkStringField(record.archingHorn) ||
        checkStringField(record.coronaRing) ||
        checkStringField(record.insulatorType) || // This is now also checked
        checkStringField(record.opgwJointBox) ||
        // Line Survey Details (boolean fields explicitly checked for 'true')
        checkBooleanField(record.building) ||
        checkBooleanField(record.tree) ||
        (record.tree == true &&
            (record.numberOfTrees == null ||
                record.numberOfTrees! <=
                    0)) || // Issue if tree is selected but no number
        checkStringField(record.conditionOfOpgw) ||
        checkStringField(record.conditionOfEarthWire) ||
        checkStringField(record.conditionOfConductor) ||
        checkStringField(record.midSpanJoint) ||
        checkBooleanField(record.newConstruction) ||
        checkBooleanField(record.objectOnConductor) ||
        checkBooleanField(record.objectOnEarthwire) ||
        checkStringField(record.spacers) ||
        checkStringField(record.vibrationDamper) ||
        checkStringField(record
            .roadCrossing) || // If contains specific issues, e.g., 'Damaged road'
        checkBooleanField(record.riverCrossing) ||
        checkStringField(
            record.electricalLine) || // If it contains 'Damaged' etc.
        checkBooleanField(record.railwayCrossing)) {
      return true; // At least one 'NOT OKAY' condition found
    }

    return false; // No 'NOT OKAY' conditions found
  }

  void _applyFilters() {
    List<SurveyRecord> tempRecords = List.from(_allWorkerRecords);

    // Apply filters based on selected options
    _selectedFilters.forEach((fieldName, selectedOptions) {
      if (selectedOptions.isEmpty)
        return; // Skip if no options selected for this filter

      if (fieldName == 'healthyStatus') {
        if (selectedOptions.contains('NOT OKAY') &&
            !selectedOptions.contains('OK')) {
          tempRecords =
              tempRecords.where((record) => _isNotOkay(record)).toList();
        } else if (selectedOptions.contains('OK') &&
            !selectedOptions.contains('NOT OKAY')) {
          tempRecords =
              tempRecords.where((record) => !_isNotOkay(record)).toList();
        }
        // If both or neither selected, no specific filtering based on healthy status.
      } else {
        // For other filter categories
        tempRecords = tempRecords.where((record) {
          String? fieldValue;
          // Handle boolean fields which map 'true' to 'NOT OKAY' and 'false' to 'OK' in filter
          if (fieldName == 'building')
            fieldValue = (record.building == true ? 'NOT OKAY' : 'OK');
          else if (fieldName == 'tree')
            fieldValue = (record.tree == true ? 'NOT OKAY' : 'OK');
          else if (fieldName == 'newConstruction')
            fieldValue = (record.newConstruction == true ? 'NOT OKAY' : 'OK');
          else if (fieldName == 'objectOnConductor')
            fieldValue = (record.objectOnConductor == true ? 'NOT OKAY' : 'OK');
          else if (fieldName == 'objectOnEarthwire')
            fieldValue = (record.objectOnEarthwire == true ? 'NOT OKAY' : 'OK');
          else if (fieldName == 'riverCrossing')
            fieldValue = (record.riverCrossing == true ? 'NOT OKAY' : 'OK');
          else if (fieldName == 'railwayCrossing')
            fieldValue = (record.railwayCrossing == true ? 'NOT OKAY' : 'OK');
          else
            fieldValue = record
                .toMap()[fieldName]
                ?.toString(); // Get string value for other fields

          if (fieldValue == null)
            return false; // If record has no value for this field, it doesn't match a selection

          // For filter categories where specific values are selected (e.g., 'Damaged' for Condition of OPGW)
          return selectedOptions.contains(fieldValue);
        }).toList();
      }
    });

    setState(() {
      _filteredRecords = tempRecords;
    });
  }

  void _toggleFilterOption(String fieldName, String option) {
    setState(() {
      _selectedFilters.putIfAbsent(fieldName, () => {});
      if (_selectedFilters[fieldName]!.contains(option)) {
        _selectedFilters[fieldName]!.remove(option);
      } else {
        _selectedFilters[fieldName]!.add(option);
      }
      _applyFilters();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedFilters.clear();
      _selectedFilters['healthyStatus'] = {
        'NOT OKAY'
      }; // Reset to default 'NOT OKAY' selected
      _applyFilters();
    });
  }

  // Helper to convert camelCase to Human Readable Title Case
  String _toHumanReadable(String camelCase) {
    return camelCase
        .replaceAllMapped(
            RegExp(r'(^[a-z])|[A-Z]'),
            (m) =>
                m[1] == null ? ' ${m[0] ?? ''}' : (m[0]?.toUpperCase() ?? ''))
        .trim();
  }

  // Build the filter panel UI (as a Drawer or Overlay)
  Widget _buildFilterPanel() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Filter Records',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            Expanded(
              child: ListView(
                children: _filterOptions.entries.map((entry) {
                  final fieldName = entry.key;
                  final options = entry.value;
                  return ExpansionTile(
                    title: Text(_toHumanReadable(fieldName)),
                    children: options.map((option) {
                      final isSelected =
                          _selectedFilters[fieldName]?.contains(option) ??
                              false;
                      return CheckboxListTile(
                        title: Text(option),
                        value: isSelected,
                        onChanged: (bool? value) {
                          _toggleFilterOption(fieldName, option);
                        },
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _clearFilters,
                child: const Text('Clear Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
            title: Text(
                '${widget.userProfile.displayName ?? widget.userProfile.email}\'s Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.userProfile.displayName ?? widget.userProfile.email}\'s Details'),
        actions: [
          if (widget.userProfile.role ==
              'Worker') // Only show filter for workers
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                );
              },
            ),
        ],
      ),
      endDrawer: widget.userProfile.role == 'Worker'
          ? _buildFilterPanel()
          : null, // Only show filter drawer for workers
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Summary (Card remains for main profile info)
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userProfile.displayName ?? 'N/A',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.userProfile.email,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Role: ${widget.userProfile.role ?? 'Unassigned'}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      'Status: ${widget.userProfile.status}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),

            if (widget.userProfile.role == 'Worker')
              _buildWorkerDetails(colorScheme)
            else if (widget.userProfile.role == 'Manager')
              _buildManagerDetails(colorScheme)
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No specific details to display for this role or user.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget to build Worker-specific details (reduced boxiness)
  Widget _buildWorkerDetails(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text(
            'Survey Records by this Worker:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 10),
        _filteredRecords.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _selectedFilters.isEmpty
                        ? 'No survey records found for this worker.'
                        : 'No records found matching current filters.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredRecords.length,
                itemBuilder: (context, index) {
                  final record = _filteredRecords[index];
                  return Container(
                    // Replaced Card with Container for subtle separation
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 0.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      title: Text(
                        'Tower: ${record.towerNumber} on ${record.lineName}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium, // Maintain strong title
                      ),
                      subtitle: Text(
                        'Status: ${record.status.toUpperCase()} | Time: ${record.timestamp.toLocal().toString().split('.')[0]}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall, // Smaller for subtitle
                      ),
                      childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      children: [
                        _buildDetailRow('Record ID', record.id),
                        _buildDetailRow('Task ID', record.taskId),
                        _buildDetailRow('User ID', record.userId),
                        _buildDetailRow(
                            'Latitude', record.latitude.toStringAsFixed(6)),
                        _buildDetailRow(
                            'Longitude', record.longitude.toStringAsFixed(6)),
                        _buildDetailRow(
                            'Timestamp',
                            record.timestamp
                                .toLocal()
                                .toString()
                                .split('.')[0]),
                        _buildDetailRow(
                            'Missing Tower Parts', record.missingTowerParts),
                        _buildDetailRow('Soil Condition', record.soilCondition),
                        _buildDetailRow(
                            'Stub / Coping Leg', record.stubCopingLeg),
                        _buildDetailRow('Earthing', record.earthing),
                        _buildDetailRow('Condition of Tower Parts',
                            record.conditionOfTowerParts),
                        _buildDetailRow(
                            'Status of Insulator', record.statusOfInsulator),
                        _buildDetailRow('Jumper Status', record.jumperStatus),
                        _buildDetailRow('Hot Spots', record.hotSpots),
                        _buildDetailRow('Number Plate', record.numberPlate),
                        _buildDetailRow('Danger Board', record.dangerBoard),
                        _buildDetailRow('Phase Plate', record.phasePlate),
                        _buildDetailRow('Nut and Bolt Condition',
                            record.nutAndBoltCondition),
                        _buildDetailRow(
                            'Anti Climbing Device', record.antiClimbingDevice),
                        _buildDetailRow('Wild Growth', record.wildGrowth),
                        _buildDetailRow('Bird Guard', record.birdGuard),
                        _buildDetailRow('Bird Nest', record.birdNest),
                        _buildDetailRow('Arching Horn', record.archingHorn),
                        _buildDetailRow('Corona Ring', record.coronaRing),
                        _buildDetailRow('Insulator Type', record.insulatorType),
                        _buildDetailRow('OPGW Joint Box', record.opgwJointBox),
                        // NEW Line Survey Details for display
                        _buildDetailRow(
                            'Building', record.building == true ? 'Yes' : 'No'),
                        _buildDetailRow(
                            'Tree', record.tree == true ? 'Yes' : 'No'),
                        if (record.tree == true)
                          _buildDetailRow('Number of Trees',
                              record.numberOfTrees?.toString()),
                        _buildDetailRow(
                            'Condition of OPGW', record.conditionOfOpgw),
                        _buildDetailRow('Condition of Earth Wire',
                            record.conditionOfEarthWire),
                        _buildDetailRow('Condition of Conductor',
                            record.conditionOfConductor),
                        _buildDetailRow('Mid Span Joint', record.midSpanJoint),
                        _buildDetailRow('New Construction',
                            record.newConstruction == true ? 'Yes' : 'No'),
                        _buildDetailRow('Object on Conductor',
                            record.objectOnConductor == true ? 'Yes' : 'No'),
                        _buildDetailRow('Object on Earthwire',
                            record.objectOnEarthwire == true ? 'Yes' : 'No'),
                        _buildDetailRow('Spacers', record.spacers),
                        _buildDetailRow(
                            'Vibration Damper', record.vibrationDamper),
                        _buildDetailRow('Road Crossing', record.roadCrossing),
                        _buildDetailRow('River Crossing',
                            record.riverCrossing == true ? 'Yes' : 'No'),
                        _buildDetailRow(
                            'Electrical Line', record.electricalLine),
                        _buildDetailRow('Railway Crossing',
                            record.railwayCrossing == true ? 'Yes' : 'No'),
                        _buildDetailRow(
                            'General Notes',
                            record
                                .generalNotes), // NEW: General Notes for display
                        if (record.photoPath != null &&
                            record.photoPath!.isNotEmpty &&
                            File(record.photoPath!).existsSync())
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Image.file(File(record.photoPath!),
                                height: 150, fit: BoxFit.cover),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // Widget to build Manager-specific details (reduced boxiness)
  Widget _buildManagerDetails(ColorScheme colorScheme) {
    int totalTowersManaged = _managedLines
        .map((line) => line.computedTotalTowers)
        .fold(0, (sum, count) => sum + count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text(
            'Managed Lines:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 10),
        _managedLines.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'This manager is not assigned to manage any transmission lines.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _managedLines.length,
                itemBuilder: (context, index) {
                  final line = _managedLines[index];
                  return Container(
                    // Replaced Card with Container
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 0.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      title: Text(line.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text(
                        'Voltage: ${line.voltageLevel ?? 'N/A'} | Towers: ${line.computedTotalTowers} (Range: ${line.towerRangeStart ?? 'N/A'} - ${line.towerRangeEnd ?? 'N/A'})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  );
                },
              ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text(
            'Total Towers Managed: $totalTowersManaged',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text(
            'Tasks Assigned by ${widget.userProfile.displayName ?? widget.userProfile.email}:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 10),
        _assignedTasksByManager.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'This manager has not assigned any tasks yet.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _assignedTasksByManager.length,
                itemBuilder: (context, index) {
                  final task = _assignedTasksByManager[index];
                  return Container(
                    // Replaced Card with Container
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 0.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      title: Text(
                          'Line: ${task.lineName} - Towers: ${task.targetTowerRange}',
                          style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Assigned to: ${task.assignedToUserName ?? 'N/A'}',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text(
                              'Due Date: ${task.dueDate.toLocal().toString().split(' ')[0]}',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text('Status: ${task.status}',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text(
                              'Towers to Patrol: ${task.numberOfTowersToPatrol}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  // Helper widget to build a detail row for ExpansionTile children
  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink(); // Hide if no value
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 0.0, vertical: 4.0), // Reduced horizontal padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(value, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
