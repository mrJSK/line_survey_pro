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
  final Map<String, Set<String>> _selectedFilters =
      {}; // Map of fieldName -> Set of selectedOptions
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // For tower number search or other text search

  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService();
  StreamSubscription? _surveyRecordsSubscription;

  // Define all possible options for filters (similar to ManagerWorkerDetailScreen)
  final Map<String, List<String>> _filterOptions = {
    'status': [
      'saved_photo_only',
      'saved_complete',
      'uploaded'
    ], // Though Firestore only has 'uploaded' generally
    'missingTowerParts': ['Yes', 'No', 'Description', 'Other'],
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
      if (selectedOptions.isNotEmpty) {
        tempRecords = tempRecords.where((record) {
          String? fieldValue;
          // Use record.toMap() to get field value dynamically by fieldName string
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
