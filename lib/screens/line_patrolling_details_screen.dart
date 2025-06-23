// lib/screens/line_patrolling_details_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/survey_record.dart';
import 'package:line_survey_pro/models/transmission_line.dart';
import 'package:line_survey_pro/services/survey_firestore_service.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'dart:async';
import 'dart:io';
import 'package:line_survey_pro/screens/view_photo_screen.dart';
import 'package:line_survey_pro/l10n/app_localizations.dart'; // Import AppLocalizations

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
  List<SurveyRecord> _allLineRecords = [];
  List<SurveyRecord> _filteredRecords = [];
  bool _isLoading = true;

  final Map<String, Set<String>> _selectedFilters = {
    'overallIssueStatus': {'Issue'}
  };

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService();
  StreamSubscription? _surveyRecordsSubscription;

  // Define all possible options for filters (consistent with ManagerWorkerDetailScreen)
  // These should ideally be localized as well if displayed directly. For now, using English strings.
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
    // 'roadCrossing': [], // Removed old dropdown field
    'riverCrossing': ['OK', 'NOT OKAY'], // OK=false, NOT OKAY=true
    // 'electricalLine': [], // Removed old dropdown field
    'railwayCrossing': ['OK', 'NOT OKAY'], // OK=false, NOT OKAY=true
    // General Notes is text, not suitable for direct filter dropdown

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
    _searchController.addListener(_onSearchChanged);
    _loadLineRecords(); // This is the main data loading method
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _surveyRecordsSubscription?.cancel(); // Cancel subscription on dispose
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  Future<void> _loadLineRecords() async {
    setState(() {
      _isLoading = true;
    });
    _surveyRecordsSubscription?.cancel(); // Cancel previous subscription

    _surveyRecordsSubscription =
        _surveyFirestoreService.streamAllSurveyRecords().listen(
      (records) {
        if (mounted) {
          setState(() {
            _allLineRecords = records
                .where((record) => record.lineName == widget.line.name)
                .toList();
            _applyFilters(); // Apply filters whenever new data comes in
            _isLoading = false; // Loading finished here
          });
        }
      },
      onError: (error) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context,
              AppLocalizations.of(context)!
                  .errorLoadingLineRecords(// Access AppLocalizations here
                      error.toString()),
              isError: true);
          setState(() {
            _isLoading = false; // Loading finished on error
          });
        }
        print('LinePatrollingDetailsScreen error streaming records: $error');
      },
    );
  }

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
        // checkStringField(record.roadCrossing) || // Removed old dropdown
        checkBooleanField(record.riverCrossing) ||
        // checkStringField(record.electricalLine) || // Removed old dropdown
        checkBooleanField(record.railwayCrossing) ||
        // NEW: Check hasRoadCrossing and hasElectricalLineCrossing booleans
        checkBooleanField(record.hasRoadCrossing) ||
        checkBooleanField(record.hasElectricalLineCrossing) ||
        // NEW: Check condition of conductors for span details
        checkStringField(record.bottomConductor) ||
        checkStringField(record.topConductor)) {
      return true; // At least one 'NOT OKAY' condition found
    }

    // NEW: Check if roadCrossingTypes or electricalLineTypes are non-empty when corresponding has* field is true
    if ((record.hasRoadCrossing == true &&
            (record.roadCrossingTypes == null ||
                record.roadCrossingTypes!.isEmpty)) ||
        (record.hasElectricalLineCrossing == true &&
            (record.electricalLineTypes == null ||
                record.electricalLineTypes!.isEmpty))) {
      return true; // Consider it an issue if has* is true but types are empty
    }

    return false; // No 'NOT OKAY' conditions found
  }

  void _applyFilters() {
    List<SurveyRecord> tempRecords = List.from(_allLineRecords);

    if (_searchQuery.isNotEmpty) {
      final String lowerCaseQuery = _searchQuery.toLowerCase();
      tempRecords = tempRecords.where((record) {
        return record.towerNumber.toString().contains(lowerCaseQuery) ||
            record.lineName.toLowerCase().contains(lowerCaseQuery) ||
            (record.missingTowerParts?.toLowerCase().contains(lowerCaseQuery) ??
                false) ||
            (record.soilCondition?.toLowerCase().contains(lowerCaseQuery) ??
                false) ||
            (record.earthing?.toLowerCase().contains(lowerCaseQuery) ??
                false) ||
            (record.hotSpots?.toLowerCase().contains(lowerCaseQuery) ??
                false) ||
            (record.generalNotes?.toLowerCase().contains(lowerCaseQuery) ??
                false) || // NEW: search in general notes
            (record.roadCrossingName?.toLowerCase().contains(lowerCaseQuery) ??
                false) || // NEW: search in road crossing name
            (record.electricalLineNames?.any(
                    (name) => name.toLowerCase().contains(lowerCaseQuery)) ??
                false) || // NEW: search in electrical line names
            (record.spanLength?.toLowerCase().contains(lowerCaseQuery) ??
                false); // NEW: search in span length
      }).toList();
    }

    _selectedFilters.forEach((fieldName, selectedOptions) {
      if (selectedOptions.isEmpty) {
        return; // Skip if no options selected for this filter
      }

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
        // If both or neither selected, no specific filtering based on healthy status.
      } else {
        // For other filter categories
        tempRecords = tempRecords.where((record) {
          dynamic fieldValue = record.toMap()[fieldName];

          // Handle boolean fields which map 'true' to 'NOT OKAY' and 'false' to 'OK' in filter
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
            fieldValue = record
                .toMap()[fieldName]
                ?.toString(); // Get string value for other fields
          }

          if (fieldValue == null) {
            return false; // If record has no value for this field, it doesn't match a selection
          }

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
      _selectedFilters['overallIssueStatus'] = {
        'Issue'
      }; // Reset to default 'Issue' selected
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
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(localizations.filterRecords,
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            Expanded(
              child: ListView(
                children: _filterOptions.entries.map((entry) {
                  final fieldName = entry.key;
                  final options = entry.value;
                  // Only show filter if there are options defined and it's not a direct text field
                  if (options.isNotEmpty) {
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
                  }
                  return const SizedBox.shrink(); // Hide if no options
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _clearFilters,
                child: Text(localizations.clearFilters),
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
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
            title: Text(localizations
                .linePatrollingDetailsScreenTitle(widget.line.name))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            localizations.linePatrollingDetailsScreenTitle(widget.line.name)),
        actions: [
          if (widget.line.name !=
              null) // Check if the line name exists before showing filter
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
      endDrawer: widget.line.name != null ? _buildFilterPanel() : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: localizations.searchTowerNumberOrDetails,
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
            child: _filteredRecords.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty && _selectedFilters.isEmpty
                          ? localizations.noSurveyRecordsFoundForLine
                          : localizations.noRecordsFoundMatchingFiltersLine,
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
                              '${localizations.tower}: ${record.towerNumber} | ${record.status.toUpperCase()}'),
                          subtitle: Text(
                              '${localizations.time}: ${record.timestamp.toLocal().toString().split('.')[0]}'),
                          children: [
                            _buildDetailRow(localizations.recordId, record.id),
                            _buildDetailRow(
                                localizations.lineNameDisplay, record.lineName),
                            _buildDetailRow(
                                localizations.taskId, record.taskId),
                            _buildDetailRow(
                                localizations.userId, record.userId),
                            _buildDetailRow(localizations.latitude,
                                record.latitude.toStringAsFixed(6)),
                            _buildDetailRow(localizations.longitude,
                                record.longitude.toStringAsFixed(6)),
                            _buildDetailRow(localizations.spanLength,
                                record.spanLength), // NEW: Span Length
                            _buildDetailRow(
                                localizations.bottomConductor,
                                record
                                    .bottomConductor), // NEW: Bottom Conductor
                            _buildDetailRow(localizations.topConductor,
                                record.topConductor), // NEW: Top Conductor
                            _buildDetailRow(localizations.missingTowerParts,
                                record.missingTowerParts),
                            _buildDetailRow(localizations.soilCondition,
                                record.soilCondition),
                            _buildDetailRow(localizations.stubCopingLeg,
                                record.stubCopingLeg),
                            _buildDetailRow(
                                localizations.earthing, record.earthing),
                            _buildDetailRow(localizations.conditionOfTowerParts,
                                record.conditionOfTowerParts),
                            _buildDetailRow(localizations.statusOfInsulator,
                                record.statusOfInsulator),
                            _buildDetailRow(localizations.jumperStatus,
                                record.jumperStatus),
                            _buildDetailRow(
                                localizations.hotSpots, record.hotSpots),
                            _buildDetailRow(
                                localizations.numberPlate, record.numberPlate),
                            _buildDetailRow(
                                localizations.dangerBoard, record.dangerBoard),
                            _buildDetailRow(
                                localizations.phasePlate, record.phasePlate),
                            _buildDetailRow(localizations.nutAndBoltCondition,
                                record.nutAndBoltCondition),
                            _buildDetailRow(localizations.antiClimbingDevice,
                                record.antiClimbingDevice),
                            _buildDetailRow(
                                localizations.wildGrowth, record.wildGrowth),
                            _buildDetailRow(
                                localizations.birdGuard, record.birdGuard),
                            _buildDetailRow(
                                localizations.birdNest, record.birdNest),
                            _buildDetailRow(
                                localizations.archingHorn, record.archingHorn),
                            _buildDetailRow(
                                localizations.coronaRing, record.coronaRing),
                            _buildDetailRow(localizations.insulatorType,
                                record.insulatorType),
                            _buildDetailRow(localizations.opgwJointBox,
                                record.opgwJointBox),
                            // NEW Line Survey Details for display
                            _buildDetailRow(
                                localizations.building,
                                record.building == true
                                    ? localizations.yes
                                    : localizations
                                        .no), // Assuming yes/no strings
                            _buildDetailRow(
                                localizations.tree,
                                record.tree == true
                                    ? localizations.yes
                                    : localizations.no),
                            if (record.tree == true)
                              _buildDetailRow(localizations.numberOfTrees,
                                  record.numberOfTrees?.toString()),
                            _buildDetailRow(localizations.conditionOfOpgw,
                                record.conditionOfOpgw),
                            _buildDetailRow(localizations.conditionOfEarthWire,
                                record.conditionOfEarthWire),
                            _buildDetailRow(localizations.conditionOfConductor,
                                record.conditionOfConductor),
                            _buildDetailRow(localizations.midSpanJoint,
                                record.midSpanJoint),
                            _buildDetailRow(
                                localizations.newConstruction,
                                record.newConstruction == true
                                    ? localizations.yes
                                    : localizations.no),
                            _buildDetailRow(
                                localizations.objectOnConductor,
                                record.objectOnConductor == true
                                    ? localizations.yes
                                    : localizations.no),
                            _buildDetailRow(
                                localizations.objectOnEarthwire,
                                record.objectOnEarthwire == true
                                    ? localizations.yes
                                    : localizations.no),
                            _buildDetailRow(
                                localizations.spacers, record.spacers),
                            _buildDetailRow(localizations.vibrationDamper,
                                record.vibrationDamper),
                            // NEW: Road Crossing Details
                            _buildDetailRow(
                                localizations.hasRoadCrossing,
                                record.hasRoadCrossing == true
                                    ? localizations.yes
                                    : localizations.no),
                            if (record.hasRoadCrossing == true &&
                                record.roadCrossingTypes != null &&
                                record.roadCrossingTypes!.isNotEmpty)
                              _buildDetailRow(
                                  localizations.selectRoadCrossingTypes,
                                  record.roadCrossingTypes!.join(', ')),
                            if (record.hasRoadCrossing == true &&
                                record.roadCrossingName != null &&
                                record.roadCrossingName!.isNotEmpty)
                              _buildDetailRow(localizations.roadCrossingName,
                                  record.roadCrossingName),

                            _buildDetailRow(
                                localizations.riverCrossing,
                                record.riverCrossing == true
                                    ? localizations.yes
                                    : localizations.no),
                            // NEW: Electrical Line Crossing Details
                            _buildDetailRow(
                                localizations.hasElectricalLineCrossing,
                                record.hasElectricalLineCrossing == true
                                    ? localizations.yes
                                    : localizations.no),
                            if (record.hasElectricalLineCrossing == true &&
                                record.electricalLineTypes != null &&
                                record.electricalLineTypes!.isNotEmpty)
                              _buildDetailRow(
                                  localizations.selectElectricalLineTypes,
                                  record.electricalLineTypes!.join(', ')),
                            if (record.hasElectricalLineCrossing == true &&
                                record.electricalLineNames != null &&
                                record.electricalLineNames!.isNotEmpty)
                              _buildDetailRow(localizations.electricalLineName,
                                  record.electricalLineNames!.join(', ')),

                            _buildDetailRow(
                                localizations.railwayCrossing,
                                record.railwayCrossing == true
                                    ? localizations.yes
                                    : localizations.no),
                            _buildDetailRow(localizations.generalNotes,
                                record.generalNotes),
                            if (record.photoPath.isNotEmpty &&
                                File(record.photoPath).existsSync())
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Image.file(File(record.photoPath),
                                    height: 150, fit: BoxFit.cover),
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
