// lib/screens/assign_lines_to_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/user_profile.dart';
import 'package:line_survey_pro/models/transmission_line.dart';
import 'package:line_survey_pro/services/auth_service.dart';
import 'package:line_survey_pro/services/firestore_service.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'dart:async'; // For StreamSubscription
import 'package:collection/collection.dart'; // For firstWhereOrNull

class AssignLinesToManagerScreen extends StatefulWidget {
  final UserProfile manager;

  const AssignLinesToManagerScreen({super.key, required this.manager});

  @override
  State<AssignLinesToManagerScreen> createState() =>
      _AssignLinesToManagerScreenState();
}

class _AssignLinesToManagerScreenState
    extends State<AssignLinesToManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<TransmissionLine> _allLines = [];
  List<TransmissionLine> _filteredLines = [];
  bool _isLoading = true;
  Set<String> _selectedLineIds =
      {}; // Stores IDs of lines selected in this session

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  StreamSubscription? _linesSubscription;

  @override
  void initState() {
    super.initState();
    _selectedLineIds = Set.from(widget.manager
        .assignedLineIds); // Initialize with manager's current assignments
    _searchController.addListener(_onSearchChanged);
    _loadTransmissionLines();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _linesSubscription?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterLines(); // Re-filter when search query changes
    });
  }

  Future<void> _loadTransmissionLines() async {
    setState(() {
      _isLoading = true;
    });
    _linesSubscription?.cancel(); // Cancel any previous subscription

    _linesSubscription =
        _firestoreService.getTransmissionLinesStream().listen((lines) {
      if (mounted) {
        setState(() {
          _allLines = lines;
          _filterLines(); // Initial filter after loading all lines
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error loading lines: ${e.toString()}',
            isError: true);
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading transmission lines for assignment: $e');
    });
  }

  void _filterLines() {
    _filteredLines = _allLines.where((line) {
      final String lowerCaseQuery = _searchQuery.toLowerCase();
      // Filter by consolidated name, voltage, or tower range
      return line.name.toLowerCase().contains(lowerCaseQuery) ||
          (line.voltageLevel?.toLowerCase().contains(lowerCaseQuery) ??
              false) ||
          (line.towerRangeStart?.toString().contains(lowerCaseQuery) ??
              false) ||
          (line.towerRangeEnd?.toString().contains(lowerCaseQuery) ?? false);
    }).toList();

    // Sort alphabetically by line name
    _filteredLines.sort((a, b) => a.name.compareTo(b.name));
  }

  void _toggleLineSelection(String lineId, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        _selectedLineIds.add(lineId);
      } else {
        _selectedLineIds.remove(lineId);
      }
    });
  }

  Future<void> _saveAssignments() async {
    // Determine which lines to add and remove from the manager's profile
    List<String> linesToAdd = _selectedLineIds
        .difference(Set.from(widget.manager.assignedLineIds))
        .toList();
    List<String> linesToRemove = Set.from(widget.manager.assignedLineIds)
        .difference(_selectedLineIds)
        .toList()
        .cast<String>();

    if (linesToAdd.isEmpty && linesToRemove.isEmpty) {
      if (mounted)
        SnackBarUtils.showSnackBar(context, 'No changes to save.',
            isError: false);
      Navigator.of(context).pop(); // Just pop if no changes
      return;
    }

    try {
      if (linesToAdd.isNotEmpty) {
        await _authService.assignLinesToManager(widget.manager.id, linesToAdd);
      }
      if (linesToRemove.isNotEmpty) {
        await _authService.unassignLinesFromManager(
            widget.manager.id, linesToRemove);
      }
      if (mounted) {
        SnackBarUtils.showSnackBar(context,
            'Lines assigned to ${widget.manager.displayName ?? widget.manager.email} successfully!');
        Navigator.of(context).pop(); // Pop back to Admin User Management
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Failed to update assigned lines: ${e.toString()}',
            isError: true);
      }
      print('Error saving line assignments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Assign Lines to ${widget.manager.displayName ?? widget.manager.email}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Lines',
                hintText: 'e.g., Shamli, 400kV, 150',
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
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
                : _filteredLines.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No lines available to assign.'
                              : 'No lines found matching your search.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredLines.length,
                        itemBuilder: (context, index) {
                          final line = _filteredLines[index];
                          final bool isSelected =
                              _selectedLineIds.contains(line.id);
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            elevation: 2,
                            child: CheckboxListTile(
                              controlAffinity: ListTileControlAffinity
                                  .leading, // Checkbox on the left
                              title: Text(line.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              subtitle: Text(
                                  'Towers: ${line.computedTotalTowers} (Range: ${line.towerRangeStart ?? 'N/A'} - ${line.towerRangeEnd ?? 'N/A'})'),
                              value: isSelected,
                              onChanged: (bool? newValue) {
                                _toggleLineSelection(line.id, newValue);
                              },
                              activeColor: colorScheme.secondary,
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(
                          color: colorScheme.onSurface.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAssignments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
