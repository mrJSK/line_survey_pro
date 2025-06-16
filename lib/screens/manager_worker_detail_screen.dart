// lib/screens/manager_worker_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/survey_record.dart';
import 'package:line_survey_pro/services/survey_firestore_service.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'dart:async';
import 'dart:io';

class ManagerWorkerDetailScreen extends StatefulWidget {
  final String workerId;
  final String workerDisplayName;

  const ManagerWorkerDetailScreen({
    super.key,
    required this.workerId,
    required this.workerDisplayName,
  });

  @override
  State<ManagerWorkerDetailScreen> createState() =>
      _ManagerWorkerDetailScreenState();
}

class _ManagerWorkerDetailScreenState extends State<ManagerWorkerDetailScreen> {
  List<SurveyRecord> _allWorkerRecords =
      []; // All records by this worker from Firestore
  List<SurveyRecord> _filteredRecords = []; // Records after applying filters
  bool _isLoading = true;

  // Filter state
  final Map<String, Set<String>> _selectedFilters =
      {}; // Map of fieldName -> Set of selectedOptions
  bool _isFilterPanelOpen = false;

  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService();
  StreamSubscription? _surveyRecordsSubscription;

  // Define all possible options for filters (moved to a consistent location in the class)
  // These maps define the exact options available for filtering.
  final Map<String, List<String>> _filterOptions = {
    'status': ['saved_photo_only', 'saved_complete', 'uploaded'],
    'missingTowerParts': [
      'Yes',
      'No',
      'Description',
      'Other'
    ], // Example: user might type "Yes" or specific details
    'soilCondition': [
      'Good',
      'Backfilling Required',
      'Revetment Wall Required',
      'Excavation Of Soil Required',
      'Eroded',
      'Other'
    ],
    'stubCopingLeg': [
      'Good',
      'Damaged',
      'Missing',
      'Corroded',
      'Cracked',
      'Other'
    ],
    'earthing': [
      'Good',
      'Loose',
      'Corroded',
      'Disconnected',
      'Missing',
      'Damaged',
      'Other'
    ],
    'conditionOfTowerParts': [
      'Good',
      'Rusted',
      'Bent',
      'Hanging',
      'Damaged',
      'Cracked',
      'Broken',
      'Other'
    ],
    'statusOfInsulator': [
      'Good',
      'Broken',
      'Flashover',
      'Damaged',
      'Dirty',
      'Cracked',
      'Other'
    ],
    'jumperStatus': [
      'Good',
      'Damaged',
      'Bolt Missing',
      'Loose Bolt',
      'Spacers Missing',
      'Corroded',
      'Other'
    ],
    'hotSpots': ['None', 'Minor', 'Moderate', 'Severe', 'Other'],
    'numberPlate': [
      'Present (Good)',
      'Missing',
      'Loose',
      'Faded',
      'Damaged',
      'Other'
    ],
    'dangerBoard': [
      'Present (Good)',
      'Missing',
      'Loose',
      'Faded',
      'Damaged',
      'Other'
    ],
    'phasePlate': [
      'Present (Good)',
      'Missing',
      'Loose',
      'Faded',
      'Damaged',
      'Other'
    ],
    'nutAndBoltCondition': [
      'Good (Tight)',
      'Loose',
      'Missing',
      'Rusted',
      'Damaged',
      'Other'
    ],
    'antiClimbingDevice': ['Intact', 'Damaged', 'Missing', 'Other'],
    'wildGrowth': [
      'None',
      'Minor (Trim Required)',
      'Moderate (Clearing Required)',
      'Heavy (Urgent Clearing Required)',
      'Other'
    ],
    'birdGuard': ['Present (Good)', 'Damaged', 'Missing', 'Other'],
    'birdNest': [
      'None',
      'Present (Active)',
      'Present (Inactive)',
      'Obstructing',
      'Other'
    ],
    'archingHorn': ['Good', 'Bent', 'Broken', 'Missing', 'Corroded', 'Other'],
    'coronaRing': ['Good', 'Bent', 'Broken', 'Missing', 'Corroded', 'Other'],
    'insulatorType': [
      'Disc',
      'Long Rod',
      'Polymer',
      'Ceramic',
      'Glass',
      'Other'
    ],
    'opgwJointBox': ['Good', 'Damaged', 'Open', 'Leaking', 'Corroded', 'Other'],
  };

  @override
  void initState() {
    super.initState();
    _loadWorkerRecords();
  }

  @override
  void dispose() {
    _surveyRecordsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadWorkerRecords() async {
    setState(() {
      _isLoading = true;
    });
    _surveyRecordsSubscription?.cancel();

    _surveyRecordsSubscription = _surveyFirestoreService
        .streamSurveyRecordsForUser(widget.workerId)
        .listen(
      (records) {
        if (mounted) {
          setState(() {
            _allWorkerRecords = records;
            _applyFilters(); // Apply filters whenever new data comes in
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Error loading worker records: ${error.toString()}',
              isError: true);
          setState(() {
            _isLoading = false;
          });
        }
        print('ManagerWorkerDetailScreen error streaming records: $error');
      },
    );
  }

  void _applyFilters() {
    List<SurveyRecord> tempRecords = List.from(_allWorkerRecords);

    // Filter by each selected filter option
    _selectedFilters.forEach((fieldName, selectedOptions) {
      if (selectedOptions.isNotEmpty) {
        tempRecords = tempRecords.where((record) {
          String? fieldValue;
          // Use record.toMap() to get field value dynamically by fieldName string
          // This is safer than a long switch for every field
          fieldValue = record.toMap()[fieldName] as String?;

          return fieldValue != null && selectedOptions.contains(fieldValue);
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
                    title: Text(_toHumanReadable(
                        fieldName)), // Use helper for human-readable title
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

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.workerDisplayName}\'s Survey Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _isFilterPanelOpen = !_isFilterPanelOpen;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredRecords.isEmpty
                  ? Center(
                      child: Text(
                        _selectedFilters.isEmpty
                            ? 'No survey records found for ${widget.workerDisplayName}.'
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
                                'Tower: ${record.towerNumber} on ${record.lineName}'),
                            subtitle: Text(
                                'Status: ${record.status.toUpperCase()} | Time: ${record.timestamp.toLocal().toString().split('.')[0]}'),
                            children: [
                              _buildDetailRow('Record ID', record.id),
                              _buildDetailRow('Task ID', record.taskId),
                              _buildDetailRow('User ID', record.userId),
                              _buildDetailRow('Latitude',
                                  record.latitude.toStringAsFixed(6)),
                              _buildDetailRow('Longitude',
                                  record.longitude.toStringAsFixed(6)),
                              _buildDetailRow(
                                  'Timestamp',
                                  record.timestamp
                                      .toLocal()
                                      .toString()
                                      .split('.')[0]),
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
                              _buildDetailRow('Phase Plate', record.phasePlate),
                              _buildDetailRow('Nut and Bolt Condition',
                                  record.nutAndBoltCondition),
                              _buildDetailRow('Anti Climbing Device',
                                  record.antiClimbingDevice),
                              _buildDetailRow('Wild Growth', record.wildGrowth),
                              _buildDetailRow('Bird Guard', record.birdGuard),
                              _buildDetailRow('Bird Nest', record.birdNest),
                              _buildDetailRow(
                                  'Arching Horn', record.archingHorn),
                              _buildDetailRow('Corona Ring', record.coronaRing),
                              _buildDetailRow(
                                  'Insulator Type', record.insulatorType),
                              _buildDetailRow(
                                  'OPGW Joint Box', record.opgwJointBox),
                              // Display photo if available locally
                              if (record.photoPath != null &&
                                  record.photoPath!.isNotEmpty &&
                                  File(record.photoPath!).existsSync())
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Image.file(File(record.photoPath!),
                                      height: 150, fit: BoxFit.cover),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
          // Filter Panel (Drawer or Overlay)
          if (_isFilterPanelOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isFilterPanelOpen = false;
                  });
                }, // Close on outside tap
                child: Container(
                    color: Colors.black.withOpacity(0.5)), // Dim background
              ),
            ),
          if (_isFilterPanelOpen)
            Align(
              alignment: Alignment.centerRight, // Align to right
              child: SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.7, // 70% of screen width
                child: _buildFilterPanel(),
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
