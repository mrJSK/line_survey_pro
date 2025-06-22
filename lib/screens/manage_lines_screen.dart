// lib/screens/manage_lines_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/transmission_line.dart';
import 'package:line_survey_pro/services/firestore_service.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs for new lines
import 'package:collection/collection.dart'; // For firstWhereOrNull

class ManageLinesScreen extends StatefulWidget {
  const ManageLinesScreen({super.key});

  @override
  State<ManageLinesScreen> createState() => _ManageLinesScreenState();
}

class _ManageLinesScreenState extends State<ManageLinesScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _lineNameController = TextEditingController();
  final TextEditingController _towerRangeStartController =
      TextEditingController();
  final TextEditingController _towerRangeEndController =
      TextEditingController();

  String? _selectedVoltageLevel;
  final List<String> _voltageLevelOptions = [
    '765kV',
    '400kV',
    '220kV',
    '132kV',
  ];

  bool _isSaving = false;
  List<TransmissionLine> _transmissionLines = [];
  bool _isLoadingLines = true;
  TransmissionLine? _lineToEdit; // To hold the line being edited

  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadTransmissionLines();
    _lineNameController.addListener(_updateFormState);
    _towerRangeStartController.addListener(_updateFormState);
    _towerRangeEndController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    _lineNameController.removeListener(_updateFormState);
    _towerRangeStartController.removeListener(_updateFormState);
    _towerRangeEndController.removeListener(_updateFormState);

    _lineNameController.dispose();
    _towerRangeStartController.dispose();
    _towerRangeEndController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    // This empty setState is used to trigger a rebuild whenever text fields change,
    // which allows the computed properties and preview text to update.
    setState(() {});
  }

  String _generateConsolidatedLineName(String baseName, String? voltageLevel) {
    if (baseName.isEmpty || voltageLevel == null) {
      return '';
    }
    // Format: {Voltage level} BaseLineName Line
    return '$voltageLevel ${baseName.trim()} Line';
  }

  Future<void> _loadTransmissionLines() async {
    setState(() {
      _isLoadingLines = true;
    });
    try {
      _firestoreService.getTransmissionLinesStream().listen((lines) {
        if (mounted) {
          setState(() {
            _transmissionLines = lines;
            _isLoadingLines = false;
          });
        }
      }, onError: (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Error loading lines: ${e.toString()}',
              isError: true);
          setState(() {
            _isLoadingLines = false;
          });
        }
        print('Error loading transmission lines: $e');
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error initializing line stream: ${e.toString()}',
            isError: true);
        setState(() {
          _isLoadingLines = false;
        });
      }
      print('Error initializing line stream: $e');
    }
  }

  void _editLine(TransmissionLine line) {
    setState(() {
      _lineToEdit = line;
      // When editing, parse the consolidated name back to the base line name for the controller
      // This assumes the format "VoltageLevel BaseName Line"
      // Safely extract parts to avoid issues if format is not exact for old data
      String nameWithoutVoltageAndSuffix = line.name;
      if (line.voltageLevel != null) {
        nameWithoutVoltageAndSuffix = nameWithoutVoltageAndSuffix
            .replaceFirst(line.voltageLevel!, '')
            .trim();
      }
      nameWithoutVoltageAndSuffix =
          nameWithoutVoltageAndSuffix.replaceFirst('Line', '').trim();

      _lineNameController.text = nameWithoutVoltageAndSuffix;
      _selectedVoltageLevel = line.voltageLevel;
      _towerRangeStartController.text = line.towerRangeStart?.toString() ?? '';
      _towerRangeEndController.text = line.towerRangeEnd?.toString() ?? '';
    });
    // Scroll to the top to show the form
    Scrollable.ensureVisible(context,
        duration: const Duration(milliseconds: 300));
  }

  void _clearForm() {
    setState(() {
      _lineToEdit = null;
      _lineNameController.clear();
      _towerRangeStartController.clear();
      _towerRangeEndController.clear();
      _selectedVoltageLevel = null;
      _formKey.currentState?.reset(); // Resets dropdowns and validators
    });
  }

  Future<void> _saveLine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String baseLineName = _lineNameController.text.trim();
      final String? voltageLevel = _selectedVoltageLevel;
      final int? towerRangeStart =
          int.tryParse(_towerRangeStartController.text.trim());
      final int? towerRangeEnd =
          int.tryParse(_towerRangeEndController.text.trim());

      // NEW: More robust null checks for parsed integers
      if (towerRangeStart == null) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Invalid "From" tower number. Must be a whole number.',
              isError: true);
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }
      if (towerRangeEnd == null) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Invalid "To" tower number. Must be a whole number.',
              isError: true);
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      if (towerRangeStart <= 0 || towerRangeEnd <= 0) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Tower range values must be positive.',
              isError: true);
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      if (towerRangeStart > towerRangeEnd) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Tower range "From" cannot be greater than "To".',
              isError: true);
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Ensure voltage level is selected
      if (voltageLevel == null) {
        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'Please select a voltage level.',
              isError: true);
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final String consolidatedLineName =
          _generateConsolidatedLineName(baseLineName, voltageLevel);

      // Prevent adding duplicate line names (case-insensitive)
      final existingLineWithSameName = _transmissionLines.firstWhereOrNull(
        (line) =>
            line.id != _lineToEdit?.id &&
            line.name.toLowerCase() == consolidatedLineName.toLowerCase(),
      );

      if (existingLineWithSameName != null) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'A line with the name "$consolidatedLineName" already exists. Please choose a different name.',
            isError: true,
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      if (_lineToEdit == null) {
        // Create new line
        final newLine = TransmissionLine(
          id: _uuid.v4(),
          name: consolidatedLineName, // Store the consolidated name
          voltageLevel: voltageLevel,
          towerRangeStart: towerRangeStart,
          towerRangeEnd: towerRangeEnd,
        );
        await _firestoreService.addTransmissionLine(newLine);
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Transmission Line added successfully!');
        }
      } else {
        // Update existing line
        final updatedLine = _lineToEdit!.copyWith(
          name: consolidatedLineName, // Update with the new consolidated name
          voltageLevel: voltageLevel,
          towerRangeStart: towerRangeStart,
          towerRangeEnd: towerRangeEnd,
        );
        await _firestoreService.updateTransmissionLine(updatedLine);
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Transmission Line updated successfully!');
        }
      }
      _clearForm();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error saving line: ${e.toString()}',
            isError: true);
      }
      print('Error saving transmission line: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteLine(String lineId) async {
    final bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: const Text(
                  'Are you sure you want to delete this transmission line? This action cannot be undone.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      try {
        await _firestoreService.deleteTransmissionLine(lineId);
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Transmission Line deleted successfully!');
        }
        _clearForm();
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Error deleting line: ${e.toString()}',
              isError: true);
        }
        print('Error deleting transmission line: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Get the preview of the consolidated name
    final String consolidatedNamePreview = _generateConsolidatedLineName(
      _lineNameController.text,
      _selectedVoltageLevel,
    );

    // Compute total towers for display in the form
    final int currentComputedTowers =
        (int.tryParse(_towerRangeEndController.text.trim()) ?? 0) -
            (int.tryParse(_towerRangeStartController.text.trim()) ?? 0) +
            1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Transmission Lines'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _lineToEdit == null
                  ? 'Add New Transmission Line'
                  : 'Edit Transmission Line',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // NEW ORDER: Voltage Level first
                  DropdownButtonFormField<String>(
                    value: _selectedVoltageLevel,
                    decoration: InputDecoration(
                      labelText: 'Voltage Level',
                      prefixIcon: Icon(Icons.electrical_services,
                          color: colorScheme.primary),
                    ),
                    items: _voltageLevelOptions.map((String level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedVoltageLevel = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a voltage level';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  // NEW ORDER: Line Base Name second
                  TextFormField(
                    controller: _lineNameController,
                    decoration: InputDecoration(
                      labelText: 'Line Base Name (e.g., Shamli Aligarh)',
                      prefixIcon: Icon(Icons.speed, color: colorScheme.primary),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a line name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  // NEW ORDER: Tower Range third
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _towerRangeStartController,
                          decoration: InputDecoration(
                            labelText: 'Tower Range From',
                            prefixIcon: Icon(Icons.format_list_numbered_rtl,
                                color: colorScheme.primary),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter start tower';
                            }
                            if (int.tryParse(value) == null ||
                                int.parse(value) <= 0) {
                              return 'Valid positive number required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: _towerRangeEndController,
                          decoration: InputDecoration(
                            labelText: 'Tower Range To',
                            prefixIcon: Icon(Icons.format_list_numbered,
                                color: colorScheme.primary),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter end tower';
                            }
                            if (int.tryParse(value) == null ||
                                int.parse(value) <= 0) {
                              return 'Valid positive number required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Display Computed Total Towers and Preview of Full Line Name
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Towers: ${currentComputedTowers > 0 ? currentComputedTowers : 'N/A'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Preview: ${consolidatedNamePreview.isNotEmpty ? consolidatedNamePreview : ''}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _saveLine,
                          icon: Icon(
                              _lineToEdit == null ? Icons.add : Icons.save),
                          label: Text(
                              _lineToEdit == null ? 'Add Line' : 'Update Line'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                  if (_lineToEdit != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: OutlinedButton.icon(
                        onPressed: _clearForm,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          side: BorderSide(
                              color: colorScheme.onSurface.withOpacity(0.5)),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Existing Transmission Lines',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _isLoadingLines
                ? const Center(child: CircularProgressIndicator())
                : _transmissionLines.isEmpty
                    ? Center(
                        child: Text(
                          'No transmission lines added yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transmissionLines.length,
                        itemBuilder: (context, index) {
                          final line = _transmissionLines[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 3,
                            child: ListTile(
                              title: Text(
                                  line.name), // Display the consolidated name
                              subtitle: Text(
                                  'Towers: ${line.computedTotalTowers} (Range: ${line.towerRangeStart ?? 'N/A'} - ${line.towerRangeEnd ?? 'N/A'})'),
                              trailing: PopupMenuButton<String>(
                                // NEW: PopupMenuButton
                                icon: const Icon(Icons.more_vert),
                                onSelected: (String result) {
                                  if (result == 'edit') {
                                    _editLine(line);
                                  } else if (result == 'delete') {
                                    _deleteLine(line.id);
                                  }
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Edit'),
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: ListTile(
                                      leading:
                                          Icon(Icons.delete, color: Colors.red),
                                      title: Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
