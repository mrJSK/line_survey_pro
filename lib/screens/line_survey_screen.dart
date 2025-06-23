// lib/screens/line_survey_screen.dart
// New screen for collecting additional line survey details.

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/survey_record.dart'; // Import SurveyRecord model"
import 'package:line_survey_pro/models/transmission_line.dart'; // To get line range for Span calculation
import 'package:line_survey_pro/services/local_database_service.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:line_survey_pro/screens/camera_screen.dart'; // Next screen in flow
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:line_survey_pro/l10n/app_localizations.dart'; // Import AppLocalizations

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

  // Existing fields from the Line Survey Screen
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
  bool _riverCrossing = false;
  bool _railwayCrossing = false;
  final TextEditingController _generalNotesController =
      TextEditingController(); // NEW: Controller for general notes

  // NEW: Fields for Road Crossing
  bool _hasRoadCrossing = false;
  Set<String> _selectedRoadCrossingTypes = {};
  final TextEditingController _roadCrossingNameController =
      TextEditingController();

  // NEW: Fields for Electrical Line Crossing
  bool _hasElectricalLineCrossing = false;
  Set<String> _selectedElectricalLineTypes = {};
  List<TextEditingController> _electricalLineControllers = [];

  // NEW: Fields for Span details
  final TextEditingController _spanLengthController = TextEditingController();
  String? _bottomConductor;
  String? _topConductor;

  bool _isSaving = false;

  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();

  // Dropdown options (kept for reference, but new checkbox lists will use these values)
  final List<String> _okDamagedOptions = ['OK', 'Damaged'];
  // NEW: Options for Bottom Conductor and Top Conductor
  final List<String> _conductorOptions = [
    'OK',
    'Damaged',
    'R phase',
    'Y phase',
    'B phase'
  ];
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
    _generalNotesController.dispose();
    _roadCrossingNameController.dispose(); // Dispose new controller
    _spanLengthController.dispose(); // Dispose new controller
    for (var controller in _electricalLineControllers) {
      controller.dispose(); // Dispose dynamically created controllers
    }
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
    _riverCrossing = _currentRecord.riverCrossing ?? false;
    _railwayCrossing = _currentRecord.railwayCrossing ?? false;
    _generalNotesController.text = _currentRecord.generalNotes ?? '';

    // NEW: Populate road crossing fields
    _hasRoadCrossing = _currentRecord.hasRoadCrossing ?? false;
    if (_currentRecord.roadCrossingTypes != null) {
      _selectedRoadCrossingTypes =
          Set<String>.from(_currentRecord.roadCrossingTypes!);
    }
    _roadCrossingNameController.text = _currentRecord.roadCrossingName ?? '';

    // NEW: Populate electrical line fields
    _hasElectricalLineCrossing =
        _currentRecord.hasElectricalLineCrossing ?? false;
    if (_currentRecord.electricalLineTypes != null) {
      _selectedElectricalLineTypes =
          Set<String>.from(_currentRecord.electricalLineTypes!);
    }
    // Initialize controllers based on previously saved electrical line names
    if (_currentRecord.electricalLineNames != null) {
      _electricalLineControllers = _currentRecord.electricalLineNames!
          .map((name) => TextEditingController(text: name))
          .toList();
    } else {
      _electricalLineControllers = [];
    }

    // NEW: Populate span details
    _spanLengthController.text = _currentRecord.spanLength ?? '';
    _bottomConductor = _currentRecord.bottomConductor;
    _topConductor = _currentRecord.topConductor;
  }

  // Calculate Span heading
  String _getSpanHeading(AppLocalizations localizations) {
    if (widget.transmissionLine.towerRangeEnd != null &&
        widget.transmissionLine.towerRangeEnd ==
            widget.initialRecord.towerNumber) {
      return '${localizations.span}: END'; // Localized "Span"
    } else {
      return '${localizations.span}: ${widget.initialRecord.towerNumber}-${widget.initialRecord.towerNumber + 1}'; // Localized "Span"
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
    final localizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      SnackBarUtils.showSnackBar(context, localizations.fillAllRequiredFields,
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
        riverCrossing: _riverCrossing,
        railwayCrossing: _railwayCrossing,
        generalNotes: _generalNotesController.text.trim().isEmpty
            ? null
            : _generalNotesController.text.trim(),
        // NEW: Add road crossing fields to SurveyRecord.copyWith
        hasRoadCrossing: _hasRoadCrossing,
        roadCrossingTypes:
            _hasRoadCrossing ? _selectedRoadCrossingTypes.toList() : null,
        roadCrossingName:
            _hasRoadCrossing ? _roadCrossingNameController.text.trim() : null,
        // NEW: Add electrical line crossing fields to SurveyRecord.copyWith
        hasElectricalLineCrossing: _hasElectricalLineCrossing,
        electricalLineTypes: _hasElectricalLineCrossing
            ? _selectedElectricalLineTypes.toList()
            : null,
        electricalLineNames: _hasElectricalLineCrossing
            ? _electricalLineControllers.map((c) => c.text.trim()).toList()
            : null,
        // NEW: Add span details fields to SurveyRecord.copyWith
        spanLength: _spanLengthController.text.trim().isEmpty
            ? null
            : _spanLengthController.text.trim(),
        bottomConductor: _bottomConductor,
        topConductor: _topConductor,
      );

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
              context, localizations.lineSurveyDetailsSaved);
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, localizations.cameraCaptureCancelled,
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, localizations.errorSavingLineSurveyDetails(e.toString()),
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
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    final List<String> localizedOkDamagedOptions = [
      localizations.oK,
      localizations.damaged
    ];
    // NEW: Localized options for conductors
    final List<String> localizedConductorOptions = [
      'R',
      'Y',
      'B',
    ];
    final List<String> localizedRoadCrossingOptions = [
      localizations.nationalHighway,
      localizations.stateHighway,
      localizations.chakkRoad,
      localizations.overBridge,
      localizations.underpass
    ];
    final List<String> localizedElectricalLineOptions = [
      localizations.voltage400kV,
      localizations.voltage220kV,
      localizations.voltage132kV,
      localizations.voltage33kV,
      localizations.voltage11kV,
      localizations.privateTubeWell
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.lineSurveyDetails),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_getSpanHeading(localizations)} (${localizations.tower} ${widget.initialRecord.towerNumber} ${localizations.on} ${widget.initialRecord.lineName})',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // NEW: Span Length
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: TextFormField(
                  controller: _spanLengthController,
                  decoration: _inputDecoration(
                      localizations.spanLength, Icons.straighten, colorScheme),
                  keyboardType: TextInputType.text,
                ),
              ),
              const SizedBox(height: 15),

              // NEW: Bottom Conductor - Using localizedConductorOptions
              _buildDropdownTile(
                  localizations.bottomConductor,
                  _bottomConductor,
                  localizedConductorOptions, // Using new options
                  Icons.cable,
                  colorScheme, (value) {
                setState(() {
                  _bottomConductor = value;
                });
              }, localizations.selectBottomConductor),
              const SizedBox(height: 15),

              // NEW: Top Conductor - Using localizedConductorOptions
              _buildDropdownTile(
                  localizations.topConductor,
                  _topConductor,
                  localizedConductorOptions, // Using new options
                  Icons.cable,
                  colorScheme, (value) {
                setState(() {
                  _topConductor = value;
                });
              }, localizations.selectTopConductor),
              const SizedBox(height: 15),

              // Building (Check/Uncheck)
              _buildCheckboxTile(localizations.building, _building, (value) {
                setState(() {
                  _building = value!;
                });
              }),
              const SizedBox(height: 15),

              // Tree (Check/Uncheck with conditional text field)
              _buildCheckboxTile(localizations.tree, _tree, (value) {
                setState(() {
                  _tree = value!;
                });
              }),
              if (_tree)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: TextFormField(
                    controller: _numberOfTreesController,
                    decoration: _inputDecoration(localizations.numberOfTrees,
                        Icons.format_list_numbered, colorScheme),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_tree &&
                          (value == null ||
                              value.isEmpty ||
                              int.tryParse(value) == null ||
                              int.parse(value) <= 0)) {
                        return localizations.towerNumberPositive;
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 15),

              // Condition of OPGW (Dropdown)
              _buildDropdownTile(
                  localizations.conditionOfOpgw,
                  _conditionOfOpgw,
                  localizedOkDamagedOptions,
                  Icons.electrical_services,
                  colorScheme, (value) {
                setState(() {
                  _conditionOfOpgw = value;
                });
              }, localizations.selectConditionOfOpgw),
              const SizedBox(height: 15),

              // Condition of Earth Wire (Dropdown)
              _buildDropdownTile(
                  localizations.conditionOfEarthWire,
                  _conditionOfEarthWire,
                  localizedOkDamagedOptions,
                  Icons.electrical_services,
                  colorScheme, (value) {
                setState(() {
                  _conditionOfEarthWire = value;
                });
              }, localizations.selectConditionOfEarthWire),
              const SizedBox(height: 15),

              // Condition of Conductor (Dropdown)
              _buildDropdownTile(
                  localizations.conditionOfConductor,
                  _conditionOfConductor,
                  localizedOkDamagedOptions,
                  Icons.electrical_services,
                  colorScheme, (value) {
                setState(() {
                  _conditionOfConductor = value;
                });
              }, localizations.selectConditionOfConductor),
              const SizedBox(height: 15),

              // Mid Span Joint (Dropdown)
              _buildDropdownTile(
                  localizations.midSpanJoint,
                  _midSpanJoint,
                  localizedOkDamagedOptions,
                  Icons.electrical_services,
                  colorScheme, (value) {
                setState(() {
                  _midSpanJoint = value;
                });
              }, localizations.selectMidSpanJoint),
              const SizedBox(height: 15),

              // New Construction (Check/Uncheck)
              _buildCheckboxTile(
                  localizations.newConstruction, _newConstruction, (value) {
                setState(() {
                  _newConstruction = value!;
                });
              }),
              const SizedBox(height: 15),

              // Object on Conductor (Check/Uncheck)
              _buildCheckboxTile(
                  localizations.objectOnConductor, _objectOnConductor, (value) {
                setState(() {
                  _objectOnConductor = value!;
                });
              }),
              const SizedBox(height: 15),

              // Object on Earthwire (Check/Uncheck)
              _buildCheckboxTile(
                  localizations.objectOnEarthwire, _objectOnEarthwire, (value) {
                setState(() {
                  _objectOnEarthwire = value!;
                });
              }),
              const SizedBox(height: 15),

              // Spacers (Dropdown)
              _buildDropdownTile(
                  localizations.spacers,
                  _spacers,
                  localizedOkDamagedOptions,
                  Icons.electrical_services,
                  colorScheme, (value) {
                setState(() {
                  _spacers = value;
                });
              }, localizations.selectSpacers),
              const SizedBox(height: 15),

              // Vibration Damper (Dropdown)
              _buildDropdownTile(
                  localizations.vibrationDamper,
                  _vibrationDamper,
                  localizedOkDamagedOptions,
                  Icons.electrical_services,
                  colorScheme, (value) {
                setState(() {
                  _vibrationDamper = value;
                });
              }, localizations.selectVibrationDamper),
              const SizedBox(height: 15),

              // NEW: Road Crossing Checkbox and conditional fields
              _buildCheckboxTile(localizations.roadCrossing, _hasRoadCrossing,
                  (value) {
                setState(() {
                  _hasRoadCrossing = value!;
                  if (!_hasRoadCrossing) {
                    _selectedRoadCrossingTypes.clear();
                    _roadCrossingNameController.clear();
                  }
                });
              }),
              if (_hasRoadCrossing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: Text(localizations.selectRoadCrossingTypes,
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    ...localizedRoadCrossingOptions.map((type) {
                      return _buildCheckboxTile(
                          type, _selectedRoadCrossingTypes.contains(type),
                          (value) {
                        setState(() {
                          if (value!) {
                            _selectedRoadCrossingTypes.add(type);
                          } else {
                            _selectedRoadCrossingTypes.remove(type);
                          }
                        });
                      });
                    }).toList(),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: TextFormField(
                        controller: _roadCrossingNameController,
                        decoration: _inputDecoration(
                            localizations.roadCrossingName,
                            Icons.text_fields,
                            colorScheme),
                        validator: (value) {
                          if (_hasRoadCrossing &&
                              value != null &&
                              value.trim().isEmpty) {
                            return localizations.enterRoadCrossingName;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 15),

              // River Crossing (Check/Uncheck)
              _buildCheckboxTile(localizations.riverCrossing, _riverCrossing,
                  (value) {
                setState(() {
                  _riverCrossing = value!;
                });
              }),
              const SizedBox(height: 15),

              // NEW: Electrical Line Crossing Checkbox and conditional fields
              _buildCheckboxTile(
                  localizations.electricalLine, _hasElectricalLineCrossing,
                  (value) {
                setState(() {
                  _hasElectricalLineCrossing = value!;
                  if (!_hasElectricalLineCrossing) {
                    _selectedElectricalLineTypes.clear();
                    // Dispose and clear controllers if checkbox is unchecked
                    for (var controller in _electricalLineControllers) {
                      controller.dispose();
                    }
                    _electricalLineControllers.clear();
                  }
                });
              }),
              if (_hasElectricalLineCrossing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: Text(localizations.selectElectricalLineTypes,
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    ...localizedElectricalLineOptions.map((type) {
                      return _buildCheckboxTile(
                          type, _selectedElectricalLineTypes.contains(type),
                          (value) {
                        setState(() {
                          if (value!) {
                            _selectedElectricalLineTypes.add(type);
                          } else {
                            _selectedElectricalLineTypes.remove(type);
                          }
                          // Adjust the number of text controllers based on selected types
                          _rebuildElectricalLineControllers();
                        });
                      });
                    }).toList(),
                    // Dynamically generate text fields for each selected electrical line
                    ..._electricalLineControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      // Get the corresponding electrical line type from the selected types
                      // Ensure the list is sorted consistently for a stable index
                      final List<String> sortedSelectedTypes =
                          _selectedElectricalLineTypes.toList()..sort();
                      final String electricalLineType =
                          sortedSelectedTypes[index];

                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: TextFormField(
                          controller:
                              entry.value, // Use entry.value for controller
                          decoration: _inputDecoration(
                              // Dynamically set label based on selected type
                              '$electricalLineType ${localizations.electricalLineName}',
                              Icons.power,
                              colorScheme),
                          validator: (value) {
                            if (_hasElectricalLineCrossing &&
                                value != null &&
                                value.trim().isEmpty) {
                              return '${localizations.enterElectricalLineName} for $electricalLineType';
                            }
                            return null;
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              const SizedBox(height: 15),

              // Railway Crossing (Check/Uncheck)
              _buildCheckboxTile(
                  localizations.railwayCrossing, _railwayCrossing, (value) {
                setState(() {
                  _railwayCrossing = value!;
                });
              }),
              const SizedBox(height: 15),

              // General Notes Text Area
              TextFormField(
                controller: _generalNotesController,
                decoration: _inputDecoration(
                    localizations.generalNotes, Icons.notes, colorScheme),
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
                      label: Text(localizations.saveDetailsAndGoToCamera),
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

  // Helper for consistent dropdown tiles (kept as original, not used for new checkboxes)
  Widget _buildDropdownTile(
      String label,
      String? value,
      List<String> options,
      IconData icon,
      ColorScheme colorScheme,
      ValueChanged<String?> onChanged,
      String validatorMessage) {
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
      validator: (val) => val == null ? validatorMessage : null,
    );
  }

  // NEW: Helper to rebuild electrical line controllers based on selected types
  void _rebuildElectricalLineControllers() {
    // Convert the set to a sorted list to maintain consistent order when accessing by index.
    // This helps ensure the controller at index `i` consistently corresponds to the electrical line type at `selectedTypesList[i]`.
    final List<String> selectedTypesList = _selectedElectricalLineTypes.toList()
      ..sort();

    final int newCount = selectedTypesList.length;
    final int currentCount = _electricalLineControllers.length;

    if (newCount > currentCount) {
      // Add new controllers
      for (int i = currentCount; i < newCount; i++) {
        _electricalLineControllers.add(TextEditingController());
      }
    } else if (newCount < currentCount) {
      // Remove excess controllers and dispose them
      for (int i = currentCount - 1; i >= newCount; i--) {
        _electricalLineControllers[i].dispose();
        _electricalLineControllers.removeAt(i);
      }
    }

    // After adjusting the list size, ensure that if types change, the controllers are correctly mapped
    // or re-initialized if their corresponding type has shifted. This part needs more robust handling
    // if the order of selected types can change dynamically and you want to preserve text for specific types.
    // For now, it assumes that if a type is removed, its controller is removed, and if added, a new controller is added.
    // Re-populating existing text based on types is complex with dynamic lists and may require storing a map
    // of type to controller/value instead of just a list of controllers.
    // For simplicity, for now, we just ensure the list of controllers matches the count.
    // If _selectedElectricalLineTypes changes in content (not just count), you would lose entered text.
    // To preserve text, you would need to manage a Map<String, TextEditingController> or similar.
  }
}
