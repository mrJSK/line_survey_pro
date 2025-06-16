// lib/screens/patrolling_detail_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:line_survey_pro/models/survey_record.dart';
import 'package:line_survey_pro/services/local_database_service.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:line_survey_pro/screens/camera_screen.dart'; // No longer direct target
import 'package:line_survey_pro/models/transmission_line.dart'; // NEW: Import TransmissionLine
import 'package:line_survey_pro/screens/line_survey_screen.dart'; // NEW: Import LineSurveyScreen

class PatrollingDetailScreen extends StatefulWidget {
  final SurveyRecord initialRecord;
  final TransmissionLine transmissionLine; // NEW: Receive TransmissionLine

  const PatrollingDetailScreen({
    super.key,
    required this.initialRecord,
    required this.transmissionLine, // NEW: Make it required
  });

  @override
  State<PatrollingDetailScreen> createState() => _PatrollingDetailScreenState();
}

class _PatrollingDetailScreenState extends State<PatrollingDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  // Use late to allow initialization in initState
  late SurveyRecord _currentRecord;

  // Controllers for text fields (only for truly free-form input)
  final TextEditingController _missingTowerPartsController =
      TextEditingController();
  final TextEditingController _earthingController =
      TextEditingController(); // Could be text for details if 'Other' is selected
  final TextEditingController _hotSpotsController = TextEditingController();
  final TextEditingController _wildGrowthController = TextEditingController();
  final TextEditingController _birdNestController = TextEditingController();
  final TextEditingController _archingHornController = TextEditingController();
  final TextEditingController _coronaRingController = TextEditingController();
  final TextEditingController _insulatorTypeController =
      TextEditingController();
  final TextEditingController _opgwJointBoxController = TextEditingController();

  // Dropdown selected values
  String? _soilCondition;
  String? _stubCopingLeg;
  String? _conditionOfTowerParts;
  String? _statusOfInsulator;
  String? _jumperStatus;
  String? _numberPlate;
  String? _dangerBoard;
  String? _phasePlate;
  String? _nutAndBoltCondition;
  String? _birdGuard;
  String? _antiClimbingDevice;

  bool _isSavingDetails = false;

  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();

  @override
  void initState() {
    super.initState();
    _currentRecord = widget.initialRecord;
    _populateFields();
  }

  @override
  void dispose() {
    _missingTowerPartsController.dispose();
    _earthingController.dispose();
    _hotSpotsController.dispose();
    _wildGrowthController.dispose();
    _birdNestController.dispose();
    _archingHornController.dispose();
    _coronaRingController.dispose();
    _insulatorTypeController.dispose();
    _opgwJointBoxController.dispose();
    super.dispose();
  }

  void _populateFields() {
    // Populate text fields
    _missingTowerPartsController.text = _currentRecord.missingTowerParts ?? '';

    // Populate dropdowns and their associated text controllers if 'Other' was selected
    _soilCondition = _currentRecord.soilCondition;
    _stubCopingLeg = _currentRecord.stubCopingLeg;
    _conditionOfTowerParts = _currentRecord.conditionOfTowerParts;
    _statusOfInsulator = _currentRecord.statusOfInsulator;
    _jumperStatus = _currentRecord.jumperStatus;
    _numberPlate = _currentRecord.numberPlate;
    _dangerBoard = _currentRecord.dangerBoard;
    _phasePlate = _currentRecord.phasePlate;
    _nutAndBoltCondition = _currentRecord.nutAndBoltCondition;
    _birdGuard = _currentRecord.birdGuard;
    _antiClimbingDevice = _currentRecord.antiClimbingDevice;

    _earthingController.text = _currentRecord.earthing ?? '';
    _hotSpotsController.text = _currentRecord.hotSpots ?? '';
    _wildGrowthController.text = _currentRecord.wildGrowth ?? '';
    _birdNestController.text = _currentRecord.birdNest ?? '';
    _archingHornController.text = _currentRecord.archingHorn ?? '';
    _coronaRingController.text = _currentRecord.coronaRing ?? '';
    _insulatorTypeController.text = _currentRecord.insulatorType ?? '';
    _opgwJointBoxController.text = _currentRecord.opgwJointBox ?? '';
  }

  Future<void> _navigateToLineSurveyScreen() async {
    // Changed method name
    if (!_formKey.currentState!.validate()) {
      SnackBarUtils.showSnackBar(
          context, 'Please fill all required fields correctly.',
          isError: true);
      return;
    }

    setState(() {
      _isSavingDetails = true;
    });

    try {
      // Create an updated record with all the details entered on this screen.
      final recordWithDetails = _currentRecord.copyWith(
        // Status remains 'saved_photo_only' until photo is taken
        missingTowerParts: _missingTowerPartsController.text.trim().isEmpty
            ? null
            : _missingTowerPartsController.text.trim(),
        soilCondition: _soilCondition,
        stubCopingLeg: _stubCopingLeg,
        earthing: _earthingController.text.trim().isEmpty
            ? null
            : _earthingController.text.trim(),
        conditionOfTowerParts: _conditionOfTowerParts,
        statusOfInsulator: _statusOfInsulator,
        jumperStatus: _jumperStatus,
        hotSpots: _hotSpotsController.text.trim().isEmpty
            ? null
            : _hotSpotsController.text.trim(),
        numberPlate: _numberPlate,
        dangerBoard: _dangerBoard,
        phasePlate: _phasePlate,
        nutAndBoltCondition: _nutAndBoltCondition,
        antiClimbingDevice: _antiClimbingDevice,
        wildGrowth: _wildGrowthController.text.trim().isEmpty
            ? null
            : _wildGrowthController.text.trim(),
        birdGuard: _birdGuard,
        birdNest: _birdNestController.text.trim().isEmpty
            ? null
            : _birdNestController.text.trim(),
        archingHorn: _archingHornController.text.trim().isEmpty
            ? null
            : _archingHornController.text.trim(),
        coronaRing: _coronaRingController.text.trim().isEmpty
            ? null
            : _coronaRingController.text.trim(),
        insulatorType: _insulatorTypeController.text.trim().isEmpty
            ? null
            : _insulatorTypeController.text.trim(),
        opgwJointBox: _opgwJointBoxController.text.trim().isEmpty
            ? null
            : _opgwJointBoxController.text.trim(),
      );

      // Navigate to LineSurveyScreen, passing the detailed record and TransmissionLine
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LineSurveyScreen(
            initialRecord: recordWithDetails,
            transmissionLine:
                widget.transmissionLine, // NEW: Pass TransmissionLine
          ),
        ),
      );
      // After LineSurveyScreen (and CameraScreen) completes and pops, this screen pops back.
      if (mounted) {
        Navigator.of(context).pop(); // Pops back to LineDetailScreen
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error processing details: ${e.toString()}',
            isError: true);
      }
      print('Error processing patrolling details for line survey nav: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // --- Specific Options for Dropdowns ---
    // Modified: Removed 'Other', added 'OK' where applicable, made names more concise
    const List<String> generalGoodBadOptions = [
      'OK',
      'Missing',
      'Not Applicable',
    ];
    const List<String> soilConditionOptions = [
      'Good',
      'Backfilling Required',
      'Revetment Wall Required',
      'Excavation Of Soil Required',
      'OK'
    ];
    const List<String> towerPartsConditionOptions = [
      'Rusted',
      'Bent',
      'Hanging',
      'Damaged',
      'Cracked',
      'Broken',
      'OK'
    ];
    const List<String> insulatorStatusOptions = [
      'Broken',
      'Flashover',
      'Damaged',
      'Dirty',
      'Cracked',
      'OK'
    ];
    const List<String> jumperStatusOptions = [
      'Damaged',
      'Bolt Missing',
      'Loose Bolt',
      'Spacers Missing',
      'Corroded',
      'OK'
    ];
    const List<String> numberPlateOptions = [
      'Missing',
      'Loose',
      'Faded',
      'Damaged',
      'OK'
    ];
    const List<String> birdGuardOptions = ['Damaged', 'Missing', 'OK'];
    const List<String> antiClimbingOptions = [
      'Intact',
      'Damaged',
      'Missing',
      'OK'
    ];
    const List<String> wildGrowthOptions = [
      'OK',
      'Trimming Required',
      'Lopping Required',
      'Cutting Required'
    ]; // 'None' changed to 'OK', 'Other' removed
    const List<String> birdNestOptions = [
      'OK',
      'Present',
    ]; // 'None' changed to 'OK', 'Other' removed
    const List<String> archingHornOptions = [
      'Bent',
      'Broken',
      'Missing',
      'Corroded',
      'OK'
    ];
    const List<String> coronaRingOptions = [
      'Bent',
      'Broken',
      'Missing',
      'Corroded',
      'OK'
    ];
    const List<String> insulatorTypeOptions = [
      'Broken',
      'Flashover',
      'Damaged',
      'Dirty',
      'Cracked',
      'OK',
    ]; // Removed 'Other', 'OK' now included as a status option
    const List<String> opgwJointBoxOptions = [
      'Damaged',
      'Open',
      'Leaking',
      'Corroded',
      'OK'
    ];
    const List<String> earthingOptions = [
      'Loose',
      'Corroded',
      'Disconnected',
      'Missing',
      'Damaged',
      'OK'
    ];
    const List<String> hotSpotsOptions = [
      'OK',
      'Minor',
      'Moderate',
      'Severe'
    ]; // 'None' changed to 'OK'
    const List<String> nutAndBoltOptions = [
      'Loose',
      'Missing',
      'Rusted',
      'Damaged',
      'OK'
    ];
    // --- END Specific Options ---

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrolling Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter detailed patrolling observations for Tower ${widget.initialRecord.towerNumber} on ${widget.initialRecord.lineName}.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Display captured image (if already existing, e.g., for editing)
              if (widget.initialRecord.photoPath.isNotEmpty &&
                  File(widget.initialRecord.photoPath).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    File(widget.initialRecord.photoPath),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 20),

              // --- Detailed Patrolling Points ---
              // Soil Condition (Dropdown)
              DropdownButtonFormField<String>(
                value: _soilCondition,
                decoration: _inputDecoration(
                    'Soil Condition', Icons.landscape, colorScheme),
                items: soilConditionOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _soilCondition = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select soil condition' : null,
              ),
              const SizedBox(height: 15),

              // Stub / Coping Leg (Dropdown)
              DropdownButtonFormField<String>(
                value: _stubCopingLeg,
                decoration: _inputDecoration(
                    'Stub / Coping Leg', Icons.foundation, colorScheme),
                items: generalGoodBadOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _stubCopingLeg = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select stub/coping leg status' : null,
              ),
              const SizedBox(height: 15),

              // Earthing (Dropdown)
              DropdownButtonFormField<String>(
                value: _earthingController.text.isNotEmpty
                    ? _earthingController.text
                    : null,
                decoration: _inputDecoration(
                    'Earthing', Icons.electrical_services, colorScheme),
                items: earthingOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _earthingController.text = newValue ?? '';
                  });
                },
                validator: (value) =>
                    value == null ? 'Select earthing status' : null,
              ),
              const SizedBox(height: 15),

              // Condition of Tower Parts (Dropdown)
              DropdownButtonFormField<String>(
                value: _conditionOfTowerParts,
                decoration: _inputDecoration(
                    'Condition of Tower Parts', Icons.build, colorScheme),
                items: towerPartsConditionOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _conditionOfTowerParts = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select condition of tower parts' : null,
              ),
              const SizedBox(height: 15),

              // Status of Insulator (Dropdown)
              DropdownButtonFormField<String>(
                value: _statusOfInsulator,
                decoration: _inputDecoration(
                    'Status of Insulator', Icons.power, colorScheme),
                items: insulatorStatusOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _statusOfInsulator = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select insulator status' : null,
              ),
              const SizedBox(height: 15),

              // Jumper Status (Dropdown)
              DropdownButtonFormField<String>(
                value: _jumperStatus,
                decoration:
                    _inputDecoration('Jumper Status', Icons.cable, colorScheme),
                items: jumperStatusOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _jumperStatus = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select jumper status' : null,
              ),
              const SizedBox(height: 15),

              // Hot Spots (Dropdown)
              DropdownButtonFormField<String>(
                value: _hotSpotsController.text.isNotEmpty
                    ? _hotSpotsController.text
                    : null,
                decoration:
                    _inputDecoration('Hot Spots', Icons.fireplace, colorScheme),
                items: hotSpotsOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _hotSpotsController.text = newValue ?? '';
                  });
                },
                validator: (value) =>
                    value == null ? 'Select hot spot status' : null,
              ),
              const SizedBox(height: 15),

              // Number Plate (Dropdown)
              DropdownButtonFormField<String>(
                value: _numberPlate,
                decoration: _inputDecoration(
                    'Number Plate', Icons.looks_one, colorScheme),
                items: numberPlateOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _numberPlate = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select number plate status' : null,
              ),
              const SizedBox(height: 15),

              // Danger Board (Dropdown)
              DropdownButtonFormField<String>(
                value: _dangerBoard,
                decoration: _inputDecoration(
                    'Danger Board', Icons.warning, colorScheme),
                items: numberPlateOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _dangerBoard = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select danger board status' : null,
              ),
              const SizedBox(height: 15),

              // Phase Plate (Dropdown)
              DropdownButtonFormField<String>(
                value: _phasePlate,
                decoration: _inputDecoration(
                    'Phase Plate', Icons.power_outlined, colorScheme),
                items: numberPlateOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _phasePlate = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select phase plate status' : null,
              ),
              const SizedBox(height: 15),

              // Nut and Bolt Condition (Dropdown)
              DropdownButtonFormField<String>(
                value: _nutAndBoltCondition,
                decoration: _inputDecoration(
                    'Nut and Bolt Condition', Icons.handyman, colorScheme),
                items: nutAndBoltOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _nutAndBoltCondition = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select nut and bolt condition' : null,
              ),
              const SizedBox(height: 15),

              // Anti Climbing Device (Dropdown)
              DropdownButtonFormField<String>(
                value: _antiClimbingDevice,
                decoration: _inputDecoration(
                    'Anti Climbing Device', Icons.block, colorScheme),
                items: antiClimbingOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _antiClimbingDevice = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select anti-climbing device status' : null,
              ),
              const SizedBox(height: 15),

              // Wild Growth (Dropdown)
              DropdownButtonFormField<String>(
                value: _wildGrowthController.text.isNotEmpty
                    ? _wildGrowthController.text
                    : null,
                decoration:
                    _inputDecoration('Wild Growth', Icons.forest, colorScheme),
                items: wildGrowthOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _wildGrowthController.text = newValue ?? '';
                  });
                },
                validator: (value) =>
                    value == null ? 'Select wild growth status' : null,
              ),
              const SizedBox(height: 15),

              // Bird Guard (Dropdown)
              DropdownButtonFormField<String>(
                value: _birdGuard,
                decoration: _inputDecoration(
                    'Bird Guard', Icons.architecture, colorScheme),
                items: birdGuardOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _birdGuard = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select bird guard status' : null,
              ),
              const SizedBox(height: 15),

              // Bird Nest (Dropdown)
              DropdownButtonFormField<String>(
                value: _birdNestController.text.isNotEmpty
                    ? _birdNestController.text
                    : null,
                decoration:
                    _inputDecoration('Bird Nest', Icons.grass, colorScheme),
                items: birdNestOptions.map((String option) {
                  return DropdownMenuItem(
                      value: option,
                      child: Text(
                        option,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _birdNestController.text = newValue ?? '';
                  });
                },
                validator: (value) =>
                    value == null ? 'Select bird nest status' : null,
              ),
              const SizedBox(height: 15),

              // Arching Horn (Dropdown)
              DropdownButtonFormField<String>(
                value: _archingHornController.text.isNotEmpty
                    ? _archingHornController.text
                    : null,
                decoration: _inputDecoration(
                    'Arching Horn', Icons.flash_on, colorScheme),
                items: archingHornOptions.map((String option) {
                  return DropdownMenuItem(
                      value: option,
                      child: Text(
                        option,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _archingHornController.text = newValue ?? '';
                  });
                },
                validator: (value) =>
                    value == null ? 'Select arching horn status' : null,
              ),
              const SizedBox(height: 15),

              // Corona Ring (Dropdown)
              DropdownButtonFormField<String>(
                value: _coronaRingController.text.isNotEmpty
                    ? _coronaRingController.text
                    : null,
                decoration:
                    _inputDecoration('Corona Ring', Icons.circle, colorScheme),
                items: coronaRingOptions.map((String option) {
                  return DropdownMenuItem(
                      value: option,
                      child: Text(
                        option,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _coronaRingController.text = newValue ?? '';
                  });
                },
                validator: (value) =>
                    value == null ? 'Select corona ring status' : null,
              ),
              const SizedBox(height: 15),

              // Insulator Type (Dropdown)
              DropdownButtonFormField<String>(
                value: _insulatorTypeController.text.isNotEmpty
                    ? _insulatorTypeController.text
                    : null,
                decoration: _inputDecoration(
                    'Insulator Type', Icons.electric_bolt, colorScheme),
                items: insulatorTypeOptions.map((String option) {
                  return DropdownMenuItem(
                      value: option,
                      child: Text(
                        option,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _insulatorTypeController.text = newValue ?? '';
                  });
                },
                validator: (value) =>
                    value == null ? 'Select insulator type' : null,
              ),
              const SizedBox(height: 15),

              // OPGW Joint Box (Dropdown)
              DropdownButtonFormField<String>(
                value: _opgwJointBoxController.text.isNotEmpty
                    ? _opgwJointBoxController.text
                    : null,
                decoration: _inputDecoration(
                    'OPGW Joint Box', Icons.cable, colorScheme),
                items: opgwJointBoxOptions.map((String option) {
                  return DropdownMenuItem(
                      value: option,
                      child: Text(
                        option,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _opgwJointBoxController.text = newValue ?? '';
                  });
                },
                validator: (value) =>
                    value == null ? 'Select OPGW Joint Box status' : null,
              ),
              const SizedBox(height: 15),

              // Missing Tower Parts (TextFormField - Moved to end)
              TextFormField(
                controller: _missingTowerPartsController,
                decoration: _inputDecoration(
                    'Missing Tower Parts', // Shorter label
                    Icons.precision_manufacturing,
                    colorScheme),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 30),

              // Continue to Line Survey Button
              _isSavingDetails
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed:
                          _navigateToLineSurveyScreen, // Changed navigation target
                      icon: const Icon(Icons.arrow_forward), // Changed icon
                      label: const Text(
                          'Continue to Line Survey'), // Changed label
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

  // Helper for InputDecoration consistent style
  InputDecoration _inputDecoration(
      String label, IconData icon, ColorScheme colorScheme) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colorScheme.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true, // Make input fields more compact
      labelStyle: TextStyle(
          color: colorScheme.primary.withOpacity(0.8),
          overflow:
              TextOverflow.ellipsis), // Ensure label text overflows gracefully
    );
  }
}
