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
    ],
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
    ],
    'railwayCrossing': ['OK', 'NOT OKAY'],
    'generalNotes': [],
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
      _applyFilters();
    });
  }

  Future<void> _loadLineRecords() async {
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });
    _surveyRecordsSubscription?.cancel();

    _surveyRecordsSubscription =
        _surveyFirestoreService.streamAllSurveyRecords().listen(
      (records) {
        if (mounted) {
          setState(() {
            _allLineRecords = records
                .where((record) => record.lineName == widget.line.name)
                .toList();
            _applyFilters();
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context,
              localizations.errorLoadingLineRecords(
                  error.toString()), // Assuming new string
              isError: true);
          setState(() {
            _isLoading = false;
          });
        }
        print('LinePatrollingDetailsScreen error streaming records: $error');
      },
    );
  }

  bool _isNotOkay(SurveyRecord record) {
    const Set<String> nonIssueTerms = {
      'ok',
      'good',
      'intact',
      'not applicable'
    };

    const Set<String> problemKeywords = {
      'missing',
      'damaged',
      'rusted',
      'bent',
      'hanging',
      'cracked',
      'broken',
      'flashover',
      'dirty',
      'loose',
      'bolt missing',
      'spacers missing',
      'corroded',
      'faded',
      'disconnected',
      'open',
      'leaking',
      'present',
      'trimming required',
      'lopping required',
      'cutting required',
      'minor',
      'moderate',
      'severe',
      'backfilling required',
      'revetment wall required',
      'excavation of soil required',
      'eroded',
      'not okay',
    };

    bool checkStringField(String? value) {
      if (value == null ||
          value.isEmpty ||
          nonIssueTerms.contains(value.toLowerCase())) {
        return false;
      }
      final lowerCaseValue = value.toLowerCase();

      if (nonIssueTerms.contains(lowerCaseValue)) {
        return false;
      }

      for (final keyword in problemKeywords) {
        if (lowerCaseValue.contains(keyword)) {
          return true;
        }
      }

      if (record.insulatorType != null &&
          ['broken', 'flashover', 'damaged', 'dirty', 'cracked']
              .contains(record.insulatorType!.toLowerCase())) {
        return true;
      }

      return false;
    }

    bool checkBooleanField(bool? value) {
      return value == true;
    }

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
        checkStringField(record.insulatorType) ||
        checkStringField(record.opgwJointBox) ||
        checkBooleanField(record.building) ||
        checkBooleanField(record.tree) ||
        (record.tree == true &&
            (record.numberOfTrees == null || record.numberOfTrees! <= 0)) ||
        checkStringField(record.conditionOfOpgw) ||
        checkStringField(record.conditionOfEarthWire) ||
        checkStringField(record.conditionOfConductor) ||
        checkStringField(record.midSpanJoint) ||
        checkBooleanField(record.newConstruction) ||
        checkBooleanField(record.objectOnConductor) ||
        checkBooleanField(record.objectOnEarthwire) ||
        checkStringField(record.spacers) ||
        checkStringField(record.vibrationDamper) ||
        checkStringField(record.roadCrossing) ||
        checkBooleanField(record.riverCrossing) ||
        checkStringField(record.electricalLine) ||
        checkBooleanField(record.railwayCrossing)) {
      return true;
    }

    return false;
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
            (record.hotSpots?.toLowerCase().contains(lowerCaseQuery) ?? false);
      }).toList();
    }

    _selectedFilters.forEach((fieldName, selectedOptions) {
      if (selectedOptions.isEmpty) {
        return;
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
      } else {
        tempRecords = tempRecords.where((record) {
          String? fieldValue;
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
          } else {
            fieldValue = record.toMap()[fieldName] as String?;
          }

          if (fieldValue == null) {
            return false;
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
      _selectedFilters['overallIssueStatus'] = {'Issue'};
      _searchController.clear();
      _searchQuery = '';
      _applyFilters();
    });
  }

  String _toHumanReadable(String camelCase) {
    return camelCase
        .replaceAllMapped(
            RegExp(r'(^[a-z])|[A-Z]'),
            (m) =>
                m[1] == null ? ' ${m[0] ?? ''}' : (m[0]?.toUpperCase() ?? ''))
        .trim();
  }

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
            localizations.linePatrollingDetailsScreenTitle(widget.line.name)),
        actions: [
          Builder(builder: (context) {
            return IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            );
          }),
        ],
      ),
      endDrawer: _buildFilterPanel(),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
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
                                _buildDetailRow(
                                    localizations.recordId, record.id),
                                _buildDetailRow(localizations.lineNameDisplay,
                                    record.lineName),
                                _buildDetailRow(
                                    localizations.taskId, record.taskId),
                                _buildDetailRow(
                                    localizations.userId, record.userId),
                                _buildDetailRow(localizations.latitude,
                                    record.latitude.toStringAsFixed(6)),
                                _buildDetailRow(localizations.longitude,
                                    record.longitude.toStringAsFixed(6)),
                                _buildDetailRow(localizations.missingTowerParts,
                                    record.missingTowerParts),
                                _buildDetailRow(localizations.soilCondition,
                                    record.soilCondition),
                                _buildDetailRow(localizations.stubCopingLeg,
                                    record.stubCopingLeg),
                                _buildDetailRow(
                                    localizations.earthing, record.earthing),
                                _buildDetailRow(
                                    localizations.conditionOfTowerParts,
                                    record.conditionOfTowerParts),
                                _buildDetailRow(localizations.statusOfInsulator,
                                    record.statusOfInsulator),
                                _buildDetailRow(localizations.jumperStatus,
                                    record.jumperStatus),
                                _buildDetailRow(
                                    localizations.hotSpots, record.hotSpots),
                                _buildDetailRow(localizations.numberPlate,
                                    record.numberPlate),
                                _buildDetailRow(localizations.dangerBoard,
                                    record.dangerBoard),
                                _buildDetailRow(localizations.phasePlate,
                                    record.phasePlate),
                                _buildDetailRow(
                                    localizations.nutAndBoltCondition,
                                    record.nutAndBoltCondition),
                                _buildDetailRow(
                                    localizations.antiClimbingDevice,
                                    record.antiClimbingDevice),
                                _buildDetailRow(localizations.wildGrowth,
                                    record.wildGrowth),
                                _buildDetailRow(
                                    localizations.birdGuard, record.birdGuard),
                                _buildDetailRow(
                                    localizations.birdNest, record.birdNest),
                                _buildDetailRow(localizations.archingHorn,
                                    record.archingHorn),
                                _buildDetailRow(localizations.coronaRing,
                                    record.coronaRing),
                                _buildDetailRow(localizations.insulatorType,
                                    record.insulatorType),
                                _buildDetailRow(localizations.opgwJointBox,
                                    record.opgwJointBox),
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
                                _buildDetailRow(
                                    localizations.conditionOfEarthWire,
                                    record.conditionOfEarthWire),
                                _buildDetailRow(
                                    localizations.conditionOfConductor,
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
                                _buildDetailRow(localizations.roadCrossing,
                                    record.roadCrossing),
                                _buildDetailRow(
                                    localizations.riverCrossing,
                                    record.riverCrossing == true
                                        ? localizations.yes
                                        : localizations.no),
                                _buildDetailRow(localizations.electricalLine,
                                    record.electricalLine),
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
                                          tag: record.photoPath,
                                          child: Image.file(
                                            File(record.photoPath),
                                            height: 100,
                                            width: 100,
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
      return const SizedBox.shrink();
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
