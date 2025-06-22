// lib/screens/line_survey_screen.dart
// New screen for collecting additional line survey details.

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/survey_record.dart';
import 'package:line_survey_pro/models/transmission_line.dart'; // To get line range for Span calculation
import 'package:line_survey_pro/services/local_database_service.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:line_survey_pro/screens/camera_screen.dart'; // Next screen in flow
// For firstWhereOrNull

class LineSurveyScreen extends StatefulWidget {
  final SurveyRecord initialRecord; // Record from PatrollingDetailScreen
  final TransmissionLine transmissionLine; // Pass the full line object

  const LineSurveyScreen({
    super.key,
    required this.initialRecord,
    required this.transmissionLine,
  });

  @override
  State<LineSurveyScreen> createState() => _LineSurveyScreenState();
}

class _LineSurveyScreenState extends State<LineSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  late SurveyRecord _currentRecord;

  // New fields from the Line Survey Screen
  bool _building = false;
  bool _tree = false;
  final TextEditingController _numberOfTreesController =
      TextEditingController();
  String? _conditionOfOpgw;
  String? _conditionOfEarthWire;
  String? _conditionOfConductor;
  String? _midSpanJoint;
  bool _newConstruction = false;
  bool _objectOnConductor = false;
  bool _objectOnEarthwire = false;
  String? _spacers;
  String? _vibrationDamper;
  String? _roadCrossing;
  bool _riverCrossing = false;
  String? _electricalLine;
  bool _railwayCrossing = false;
  final TextEditingController _generalNotesController =
      TextEditingController(); // NEW: Controller for general notes

  bool _isSaving = false;

  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();

  // Dropdown options
  final List<String> _okDamagedOptions = ['OK', 'Damaged'];
  final List<String> _roadCrossingOptions = [
    'NH',
    'SH',
    'Chakk road',
    'Over Bridge',
    'Underpass'
  ];
  final List<String> _electricalLineOptions = [
    '400kV',
    '220kV',
    '132kV',
    '33kV',
    '11kV',
    'PTW'
  ];

  @override
  void initState() {
    super.initState();
    _currentRecord = widget.initialRecord;
    _populateFields();
  }

  @override
  void dispose() {
    _numberOfTreesController.dispose();
    _generalNotesController.dispose(); // NEW: Dispose controller
    super.dispose();
  }

  // Populate fields if record already has data (e.g., modifying an existing entry)
  void _populateFields() {
    _building = _currentRecord.building ?? false;
    _tree = _currentRecord.tree ?? false;
    _numberOfTreesController.text =
        _currentRecord.numberOfTrees?.toString() ?? '';
    _conditionOfOpgw = _currentRecord.conditionOfOpgw;
    _conditionOfEarthWire = _currentRecord.conditionOfEarthWire;
    _conditionOfConductor = _currentRecord.conditionOfConductor;
    _midSpanJoint = _currentRecord.midSpanJoint;
    _newConstruction = _currentRecord.newConstruction ?? false;
    _objectOnConductor = _currentRecord.objectOnConductor ?? false;
    _objectOnEarthwire = _currentRecord.objectOnEarthwire ?? false;
    _spacers = _currentRecord.spacers;
    _vibrationDamper = _currentRecord.vibrationDamper;
    _roadCrossing = _currentRecord.roadCrossing;
    _riverCrossing = _currentRecord.riverCrossing ?? false;
    _electricalLine = _currentRecord.electricalLine;
    _railwayCrossing = _currentRecord.railwayCrossing ?? false;
    _generalNotesController.text =
        _currentRecord.generalNotes ?? ''; // NEW: Populate general notes
  }

  // Calculate Span heading
  String _getSpanHeading() {
    if (widget.transmissionLine.towerRangeEnd != null &&
        widget.transmissionLine.towerRangeEnd ==
            widget.initialRecord.towerNumber) {
      return 'Span: END';
    } else {
      return 'Span: ${widget.initialRecord.towerNumber}-${widget.initialRecord.towerNumber + 1}';
    }
  }

  InputDecoration _inputDecoration(
      String label, IconData icon, ColorScheme colorScheme) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colorScheme.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
      labelStyle: TextStyle(
          color: colorScheme.primary.withOpacity(0.8),
          overflow: TextOverflow.ellipsis),
    );
  }

  Future<void> _saveAndNavigateToCamera() async {
    if (!_formKey.currentState!.validate()) {
      SnackBarUtils.showSnackBar(
          context, 'Please fill all required fields correctly.',
          isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedRecord = _currentRecord.copyWith(
        building: _building,
        tree: _tree,
        numberOfTrees:
            _tree ? int.tryParse(_numberOfTreesController.text.trim()) : null,
        conditionOfOpgw: _conditionOfOpgw,
        conditionOfEarthWire: _conditionOfEarthWire,
        conditionOfConductor: _conditionOfConductor,
        midSpanJoint: _midSpanJoint,
        newConstruction: _newConstruction,
        objectOnConductor: _objectOnConductor,
        objectOnEarthwire: _objectOnEarthwire,
        spacers: _spacers,
        vibrationDamper: _vibrationDamper,
        roadCrossing: _roadCrossing,
        riverCrossing: _riverCrossing,
        electricalLine: _electricalLine,
        railwayCrossing: _railwayCrossing,
        generalNotes: _generalNotesController.text.trim().isEmpty
            ? null
            : _generalNotesController.text.trim(), // NEW: Save general notes
      );

      // We are directly updating the record that came from PatrollingDetailScreen
      // and passing it to CameraScreen. CameraScreen will handle the final local save.
      final String? finalSavedRecordId = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            initialRecordWithDetails: updatedRecord,
          ),
        ),
      );

      if (finalSavedRecordId != null) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Line Survey Details saved! Proceed to camera.');
          Navigator.of(context).pop(); // Pop LineSurveyScreen
        }
      } else {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Camera capture cancelled or failed. Data not saved.',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error saving line survey details: ${e.toString()}',
            isError: true);
      }
      print('Error saving line survey details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Line Survey Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_getSpanHeading()} (Tower ${widget.initialRecord.towerNumber} on ${widget.initialRecord.lineName})',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Building (Check/Uncheck)
              _buildCheckboxTile('Building', _building, (value) {
                setState(() {
                  _building = value!;
                });
              }),
              const SizedBox(height: 15),

              // Tree (Check/Uncheck with conditional text field)
              _buildCheckboxTile('Tree', _tree, (value) {
                setState(() {
                  _tree = value!;
                });
              }),
              if (_tree)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: TextFormField(
                    controller: _numberOfTreesController,
                    decoration: _inputDecoration('Number of Trees',
                        Icons.format_list_numbered, colorScheme),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_tree &&
                          (value == null ||
                              value.isEmpty ||
                              int.tryParse(value) == null ||
                              int.parse(value) <= 0)) {
                        return 'Enter number of trees (positive number)';
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 15),

              // Condition of OPGW (Dropdown)
              _buildDropdownTile(
                  'Condition of OPGW',
                  _conditionOfOpgw,
                  _okDamagedOptions,
                  Icons.electrical_services,
                  colorScheme, (value) {
                setState(() {
                  _conditionOfOpgw = value;
                });
              }),
              const SizedBox(height: 15),

              // Condition of Earth Wire (Dropdown)
              _buildDropdownTile(
                  'Condition of Earth Wire',
                  _conditionOfEarthWire,
                  _okDamagedOptions,
                  Icons.electrical_services,
                  colorScheme, (value) {
                setState(() {
                  _conditionOfEarthWire = value;
                });
              }),
              const SizedBox(height: 15),

              // Condition of Conductor (Dropdown)
              _buildDropdownTile(
                  'Condition of Conductor',
                  _conditionOfConductor,
                  _okDamagedOptions,
                  Icons.electrical_services,
                  colorScheme, (value) {
                setState(() {
                  _conditionOfConductor = value;
                });
              }),
              const SizedBox(height: 15),

              // Mid Span Joint (Dropdown)
              _buildDropdownTile(
                  'Mid Span Joint',
                  _midSpanJoint,
                  _okDamagedOptions,
                  Icons.electrical_services,
                  colorScheme, (value) {
                setState(() {
                  _midSpanJoint = value;
                });
              }),
              const SizedBox(height: 15),

              // New Construction (Check/Uncheck)
              _buildCheckboxTile('New Construction', _newConstruction, (value) {
                setState(() {
                  _newConstruction = value!;
                });
              }),
              const SizedBox(height: 15),

              // Object on Conductor (Check/Uncheck)
              _buildCheckboxTile('Object on Conductor', _objectOnConductor,
                  (value) {
                setState(() {
                  _objectOnConductor = value!;
                });
              }),
              const SizedBox(height: 15),

              // Object on Earthwire (Check/Uncheck)
              _buildCheckboxTile('Object on Earthwire', _objectOnEarthwire,
                  (value) {
                setState(() {
                  _objectOnEarthwire = value!;
                });
              }),
              const SizedBox(height: 15),

              // Spacers (Dropdown)
              _buildDropdownTile('Spacers', _spacers, _okDamagedOptions,
                  Icons.electrical_services, colorScheme, (value) {
                setState(() {
                  _spacers = value;
                });
              }),
              const SizedBox(height: 15),

              // Vibration Damper (Dropdown)
              _buildDropdownTile(
                  'Vibration Damper',
                  _vibrationDamper,
                  _okDamagedOptions,
                  Icons.electrical_services,
                  colorScheme, (value) {
                setState(() {
                  _vibrationDamper = value;
                });
              }),
              const SizedBox(height: 15),

              // Road Crossing (Dropdown)
              _buildDropdownTile('Road Crossing', _roadCrossing,
                  _roadCrossingOptions, Icons.route, colorScheme, (value) {
                setState(() {
                  _roadCrossing = value;
                });
              }),
              const SizedBox(height: 15),

              // River Crossing (Check/Uncheck)
              _buildCheckboxTile('River Crossing', _riverCrossing, (value) {
                setState(() {
                  _riverCrossing = value!;
                });
              }),
              const SizedBox(height: 15),

              // Electrical Line (Dropdown)
              _buildDropdownTile('Electrical Line', _electricalLine,
                  _electricalLineOptions, Icons.power, colorScheme, (value) {
                setState(() {
                  _electricalLine = value;
                });
              }),
              const SizedBox(height: 15),

              // Railway Crossing (Check/Uncheck)
              _buildCheckboxTile('Railway Crossing', _railwayCrossing, (value) {
                setState(() {
                  _railwayCrossing = value!;
                });
              }),
              const SizedBox(height: 15),

              // NEW: General Notes Text Area
              TextFormField(
                controller: _generalNotesController,
                decoration: _inputDecoration(
                    'General Observations/Notes', Icons.notes, colorScheme),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 30),

              // Save Details & Go to Camera Button
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _saveAndNavigateToCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Save Details & Go to Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 55),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for consistent checkbox tiles
  Widget _buildCheckboxTile(
      String title, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding:
          EdgeInsets.zero, // Remove default padding for tighter layout
    );
  }

  // Helper for consistent dropdown tiles
  Widget _buildDropdownTile(String label, String? value, List<String> options,
      IconData icon, ColorScheme colorScheme, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(label, icon, colorScheme),
      items: options.map((String option) {
        return DropdownMenuItem(
            value: option,
            child: Text(
              option,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ));
      }).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Select $label' : null,
    );
  }
}
