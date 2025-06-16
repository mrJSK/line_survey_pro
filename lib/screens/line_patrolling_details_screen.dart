// lib/screens/line_patrolling_details_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/survey_record.dart';
import 'package:line_survey_pro/models/transmission_line.dart'; // To receive the line object
import 'package:line_survey_pro/services/survey_firestore_service.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'dart:async';
import 'dart:io'; // For checking local photo existence
import 'package:line_survey_pro/screens/view_photo_screen.dart'; // To view full photo

class LinePatrollingDetailsScreen extends StatefulWidget {
  final TransmissionLine line;

  const LinePatrollingDetailsScreen({
    super.key,
    required this.line,
  });

  @override
  State<LinePatrollingDetailsScreen> createState() =>
      _LinePatrollingDetailsScreenState();
}

class _LinePatrollingDetailsScreenState
    extends State<LinePatrollingDetailsScreen> {
  List<SurveyRecord> _allLineRecords =
      []; // All records for this line from Firestore
  List<SurveyRecord> _filteredRecords = []; // Records after applying filters
  bool _isLoading = true;

  // Filter state
  final Map<String, Set<String>> _selectedFilters = {
    'overallIssueStatus': {'Issue'}
  }; // Default to 'Issue' selected

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // For tower number search or other text search

  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService();
  StreamSubscription? _surveyRecordsSubscription;

  // Define all possible options for filters (consistent with ManagerWorkerDetailScreen)
  final Map<String, List<String>> _filterOptions = {
    'overallIssueStatus': ['Issue', 'OK'], // Primary filter
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
    // New fields from Line Survey Screen (consistent with manager_worker_detail_screen)
    'building': ['OK', 'NOT OKAY'],
    'tree': ['OK', 'NOT OKAY'],
    'conditionOfOpgw': ['OK', 'Damaged'],
    'conditionOfEarthWire': ['OK', 'Damaged'],
    'conditionOfConductor': ['OK', 'Damaged'],
    'midSpanJoint': ['OK', 'Damaged'],
    'newConstruction': ['OK', 'NOT OKAY'],
    'objectOnConductor': ['OK', 'NOT OKAY'],
    'objectOnEarthwire': ['OK', 'NOT OKAY'],
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
    ], // Added OK/NOT OK for general status
    'riverCrossing': ['OK', 'NOT OKAY'],
    'electricalLine': [
      '400kV',
      '220kV',
      '132kV',
      '33kV',
      '11kV',
      'PTW',
      'OK',
      'NOT OKAY'
    ], // Added OK/NOT OK for general status
    'railwayCrossing': ['OK', 'NOT OKAY'],
    'generalNotes':
        [], // General notes is text, not suitable for direct filter dropdown
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadLineRecords();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _surveyRecordsSubscription?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters(); // Re-apply filters when search query changes
    });
  }

  Future<void> _loadLineRecords() async {
    setState(() {
      _isLoading = true;
    });
    _surveyRecordsSubscription?.cancel(); // Cancel any previous subscription

    // Stream records for this specific lineName
    _surveyRecordsSubscription = _surveyFirestoreService
        .streamAllSurveyRecords() // Stream all records, then filter by lineName client-side
        .listen(
      (records) {
        if (mounted) {
          setState(() {
            _allLineRecords = records
                .where((record) => record.lineName == widget.line.name)
                .toList();
            _applyFilters(); // Apply filters whenever new data comes in
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Error loading line records: ${error.toString()}',
              isError: true);
          setState(() {
            _isLoading = false;
          });
        }
        print('LinePatrollingDetailsScreen error streaming records: $error');
      },
    );
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
      // Check for specific problematic keywords
      for (final keyword in problemKeywords) {
        if (lowerCaseValue.contains(keyword)) {
          return true;
        }
      }
      // Specific checks for values that are issues but might not be caught by generic keywords
      // based on the provided lists for filtering
      if (lowerCaseValue == 'yes' &&
          (record.building == true ||
              record.tree == true ||
              record.newConstruction == true ||
              record.objectOnConductor == true ||
              record.objectOnEarthwire == true ||
              record.riverCrossing == true ||
              record.railwayCrossing == true)) {
        return true;
      }
      if (lowerCaseValue == 'no' &&
          (record.building == false ||
              record.tree == false ||
              record.newConstruction == false ||
              record.objectOnConductor == false ||
              record.objectOnEarthwire == false ||
              record.riverCrossing == false ||
              record.railwayCrossing == false)) {
        return false;
      }

      // Special case for 'insulatorType' when it implies a problem
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
    List<SurveyRecord> tempRecords = List.from(_allLineRecords);

    // Filter by search query (tower number or general text search)
    if (_searchQuery.isNotEmpty) {
      final String lowerCaseQuery = _searchQuery.toLowerCase();
      tempRecords = tempRecords.where((record) {
        return record.towerNumber.toString().contains(lowerCaseQuery) ||
            record.lineName
                .toLowerCase()
                .contains(lowerCaseQuery) || // Search in line name too
            (record.missingTowerParts?.toLowerCase().contains(lowerCaseQuery) ??
                false) ||
            (record.soilCondition?.toLowerCase().contains(lowerCaseQuery) ??
                false) ||
            (record.earthing?.toLowerCase().contains(lowerCaseQuery) ??
                false) ||
            (record.hotSpots?.toLowerCase().contains(lowerCaseQuery) ?? false);
        // Add other fields you want to be searchable in the main search bar
      }).toList();
    }

    // Filter by each selected filter option (dropdown filters)
    _selectedFilters.forEach((fieldName, selectedOptions) {
      if (selectedOptions.isEmpty)
        return; // Skip if no options selected for this filter

      if (fieldName == 'overallIssueStatus') {
        if (selectedOptions.contains('Issue') &&
            !selectedOptions.contains('OK')) {
          tempRecords =
              tempRecords.where((record) => _isNotOkay(record)).toList();
        } else if (selectedOptions.contains('OK') &&
            !selectedOptions.contains('Issue')) {
          tempRecords =
              tempRecords.where((record) => !_isNotOkay(record)).toList();
        }
        // If both or neither selected, no specific filtering based on issue status.
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
            fieldValue = record.toMap()[fieldName]
                as String?; // For string/dropdown fields

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
      _applyFilters(); // Re-apply filters immediately
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedFilters.clear();
      _selectedFilters['overallIssueStatus'] = {
        'Issue'
      }; // Reset to default 'Issue' selected
      _searchController.clear();
      _searchQuery = '';
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
                      final bool isSelected =
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.line.name} Details'),
        actions: [
          Builder(// Use a Builder to get a context that can open the EndDrawer
              builder: (context) {
            return IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                Scaffold.of(context).openEndDrawer(); // Open the filter drawer
              },
            );
          }),
        ],
      ),
      endDrawer: _buildFilterPanel(), // Add the filter panel as an end drawer
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Tower Number or Details',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty && _selectedFilters.isEmpty
                              ? 'No survey records found for this line.'
                              : 'No records found matching current filters.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = _filteredRecords[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 3,
                            child: ExpansionTile(
                              title: Text(
                                  'Tower: ${record.towerNumber} | ${record.status.toUpperCase()}'),
                              subtitle: Text(
                                  'Time: ${record.timestamp.toLocal().toString().split('.')[0]}'),
                              children: [
                                _buildDetailRow('Record ID', record.id),
                                _buildDetailRow('Line Name', record.lineName),
                                _buildDetailRow('Task ID', record.taskId),
                                _buildDetailRow('User ID', record.userId),
                                _buildDetailRow('Latitude',
                                    record.latitude.toStringAsFixed(6)),
                                _buildDetailRow('Longitude',
                                    record.longitude.toStringAsFixed(6)),
                                // Detailed patrolling points
                                _buildDetailRow('Missing Tower Parts',
                                    record.missingTowerParts),
                                _buildDetailRow(
                                    'Soil Condition', record.soilCondition),
                                _buildDetailRow(
                                    'Stub / Coping Leg', record.stubCopingLeg),
                                _buildDetailRow('Earthing', record.earthing),
                                _buildDetailRow('Condition of Tower Parts',
                                    record.conditionOfTowerParts),
                                _buildDetailRow('Status of Insulator',
                                    record.statusOfInsulator),
                                _buildDetailRow(
                                    'Jumper Status', record.jumperStatus),
                                _buildDetailRow('Hot Spots', record.hotSpots),
                                _buildDetailRow(
                                    'Number Plate', record.numberPlate),
                                _buildDetailRow(
                                    'Danger Board', record.dangerBoard),
                                _buildDetailRow(
                                    'Phase Plate', record.phasePlate),
                                _buildDetailRow('Nut and Bolt Condition',
                                    record.nutAndBoltCondition),
                                _buildDetailRow('Anti Climbing Device',
                                    record.antiClimbingDevice),
                                _buildDetailRow(
                                    'Wild Growth', record.wildGrowth),
                                _buildDetailRow('Bird Guard', record.birdGuard),
                                _buildDetailRow('Bird Nest', record.birdNest),
                                _buildDetailRow(
                                    'Arching Horn', record.archingHorn),
                                _buildDetailRow(
                                    'Corona Ring', record.coronaRing),
                                _buildDetailRow(
                                    'Insulator Type', record.insulatorType),
                                _buildDetailRow(
                                    'OPGW Joint Box', record.opgwJointBox),
                                // NEW Line Survey Details for display
                                _buildDetailRow('Building',
                                    record.building == true ? 'Yes' : 'No'),
                                _buildDetailRow(
                                    'Tree', record.tree == true ? 'Yes' : 'No'),
                                if (record.tree == true)
                                  _buildDetailRow('Number of Trees',
                                      record.numberOfTrees?.toString()),
                                _buildDetailRow('Condition of OPGW',
                                    record.conditionOfOpgw),
                                _buildDetailRow('Condition of Earth Wire',
                                    record.conditionOfEarthWire),
                                _buildDetailRow('Condition of Conductor',
                                    record.conditionOfConductor),
                                _buildDetailRow(
                                    'Mid Span Joint', record.midSpanJoint),
                                _buildDetailRow(
                                    'New Construction',
                                    record.newConstruction == true
                                        ? 'Yes'
                                        : 'No'),
                                _buildDetailRow(
                                    'Object on Conductor',
                                    record.objectOnConductor == true
                                        ? 'Yes'
                                        : 'No'),
                                _buildDetailRow(
                                    'Object on Earthwire',
                                    record.objectOnEarthwire == true
                                        ? 'Yes'
                                        : 'No'),
                                _buildDetailRow('Spacers', record.spacers),
                                _buildDetailRow(
                                    'Vibration Damper', record.vibrationDamper),
                                _buildDetailRow(
                                    'Road Crossing', record.roadCrossing),
                                _buildDetailRow(
                                    'River Crossing',
                                    record.riverCrossing == true
                                        ? 'Yes'
                                        : 'No'),
                                _buildDetailRow(
                                    'Electrical Line', record.electricalLine),
                                _buildDetailRow(
                                    'Railway Crossing',
                                    record.railwayCrossing == true
                                        ? 'Yes'
                                        : 'No'),
                                _buildDetailRow(
                                    'General Notes',
                                    record
                                        .generalNotes), // General Notes for display
                                // Photo display if available
                                if (record.photoPath.isNotEmpty &&
                                    File(record.photoPath).existsSync())
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.of(context)
                                              .push(MaterialPageRoute(
                                            builder: (context) =>
                                                ViewPhotoScreen(
                                                    imagePath:
                                                        record.photoPath),
                                          ));
                                        },
                                        child: Hero(
                                          tag: record
                                              .photoPath, // Unique tag for Hero animation
                                          child: Image.file(
                                            File(record.photoPath),
                                            height: 100,
                                            width:
                                                100, // Fixed width for thumbnail
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink(); // Hide if no value
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
