// lib/screens/patrolling_detail_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:line_survey_pro/models/survey_record.dart';
import 'package:line_survey_pro/services/local_database_service.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:line_survey_pro/models/transmission_line.dart';
import 'package:line_survey_pro/screens/line_survey_screen.dart';
import 'package:line_survey_pro/l10n/app_localizations.dart'; // Import AppLocalizations

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
  String? _towerType; // NEW: Tower Type state variable

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
    _towerType = _currentRecord.towerType; // NEW: Populate Tower Type

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
    final localizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      SnackBarUtils.showSnackBar(
          context, localizations.fillAllRequiredFields, // Assumed new string
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
        towerType: _towerType, // NEW: Add Tower Type to record
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
            context, localizations.errorProcessingDetails(e.toString()),
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
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    // --- Specific Options for Dropdowns ---
    // MODIFIED: generalGoodBadOptions now uses localized strings
    final List<String> generalGoodBadOptions = [
      localizations.okStatus,
      localizations.missing,
      localizations.notApplicable,
    ];
    final List<String> soilConditionOptions = [
      localizations.good,
      localizations.backfillingRequired,
      localizations.revetmentWallRequired,
      localizations.excavationOfSoilRequired,
      localizations.okStatus
    ];
    final List<String> towerPartsConditionOptions = [
      localizations.rusted,
      localizations.bent,
      localizations.hanging,
      localizations.damaged,
      localizations.cracked,
      localizations.broken,
      localizations.okStatus
    ];
    final List<String> insulatorStatusOptions = [
      localizations.broken,
      localizations.flashover,
      localizations.damaged,
      localizations.dirty,
      localizations.cracked,
      localizations.okStatus
    ];
    final List<String> jumperStatusOptions = [
      localizations.damaged,
      localizations.boltMissing,
      localizations.loose,
      localizations.spacersMissing,
      localizations.corroded,
      localizations.okStatus
    ];
    final List<String> numberPlateOptions = [
      localizations.missing,
      localizations.loose,
      localizations.faded,
      localizations.damaged,
      localizations.okStatus
    ];
    final List<String> birdGuardOptions = [
      localizations.damaged,
      localizations.missing,
      localizations.okStatus
    ];
    final List<String> antiClimbingOptions = [
      localizations.intact,
      localizations.damaged,
      localizations.missing,
      localizations.okStatus
    ];
    final List<String> wildGrowthOptions = [
      localizations.okStatus,
      localizations.trimmingRequired,
      localizations.loppingRequired,
      localizations.cuttingRequired
    ];
    final List<String> birdNestOptions = [
      localizations.okStatus,
      localizations.present,
    ];
    final List<String> archingHornOptions = [
      localizations.bent,
      localizations.broken,
      localizations.missing,
      localizations.corroded,
      localizations.okStatus
    ];
    final List<String> coronaRingOptions = [
      localizations.bent,
      localizations.broken,
      localizations.missing,
      localizations.corroded,
      localizations.okStatus
    ];
    final List<String> insulatorTypeOptions = [
      localizations.broken,
      localizations.flashover,
      localizations.damaged,
      localizations.dirty,
      localizations.cracked,
      localizations.okStatus,
    ];
    final List<String> opgwJointBoxOptions = [
      localizations.damaged,
      localizations.open,
      localizations.leaking,
      localizations.corroded,
      localizations.okStatus
    ];
    final List<String> earthingOptions = [
      localizations.loose,
      localizations.corroded,
      localizations.disconnected,
      localizations.missing,
      localizations.damaged,
      localizations.okStatus
    ];
    final List<String> hotSpotsOptions = [
      localizations.okStatus,
      localizations.minor,
      localizations.moderate,
      localizations.severe
    ];
    final List<String> nutAndBoltOptions = [
      localizations.loose,
      localizations.missing,
      localizations.rusted,
      localizations.damaged,
      localizations.okStatus
    ];
    // NEW: Options for Tower Type
    final List<String> towerTypeOptions = ['Suspension', 'Tension'];
    // --- END Specific Options ---

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.patrollingDetails),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.enterDetailedObservations(
                    widget.initialRecord.towerNumber,
                    widget.initialRecord.lineName),
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
              // NEW: Tower Type (Dropdown)
              DropdownButtonFormField<String>(
                value: _towerType,
                decoration: _inputDecoration(localizations.towerType,
                    Icons.cell_tower_sharp, colorScheme),
                items: towerTypeOptions
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
                    _towerType = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? localizations.selectTowerType : null,
              ),
              const SizedBox(height: 15),

              // Soil Condition (Dropdown)
              DropdownButtonFormField<String>(
                value: _soilCondition,
                decoration: _inputDecoration(
                    localizations.soilCondition, Icons.landscape, colorScheme),
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
                    value == null ? localizations.selectSoilCondition : null,
              ),
              const SizedBox(height: 15),

              // Stub / Coping Leg (Dropdown) - THIS IS THE MODIFIED SECTION
              DropdownButtonFormField<String>(
                value: _stubCopingLeg,
                decoration: _inputDecoration(
                    localizations.stubCopingLeg, Icons.foundation, colorScheme),
                // Use the localized generalGoodBadOptions list
                items: generalGoodBadOptions
                    .map((String option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option, // This will now correctly display the localized string
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _stubCopingLeg = newValue;
                  });
                },
                validator: (value) => value == null
                    ? localizations.selectStubCopingLegStatus
                    : null,
              ),
              const SizedBox(height: 15),

              // Earthing (Dropdown)
              DropdownButtonFormField<String>(
                value: _earthingController.text.isNotEmpty
                    ? _earthingController.text
                    : null,
                decoration: _inputDecoration(localizations.earthing,
                    Icons.electrical_services, colorScheme),
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
                    // This stores the canonical key for direct dropdown selection
                    _earthingController.text = newValue ?? '';
                  });
                },
                validator: (value) =>
                    value == null ? localizations.selectEarthingStatus : null,
              ),
              const SizedBox(height: 15),

              // Condition of Tower Parts (Dropdown)
              DropdownButtonFormField<String>(
                value: _conditionOfTowerParts,
                decoration: _inputDecoration(
                    localizations.conditionOfTowerParts,
                    Icons.build,
                    colorScheme),
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
                validator: (value) => value == null
                    ? localizations.selectConditionOfTowerParts
                    : null,
              ),
              const SizedBox(height: 15),

              // Status of Insulator (Dropdown)
              DropdownButtonFormField<String>(
                value: _statusOfInsulator,
                decoration: _inputDecoration(
                    localizations.statusOfInsulator, Icons.power, colorScheme),
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
                    value == null ? localizations.selectInsulatorStatus : null,
              ),
              const SizedBox(height: 15),

              // Jumper Status (Dropdown)
              DropdownButtonFormField<String>(
                value: _jumperStatus,
                decoration: _inputDecoration(
                    localizations.jumperStatus, Icons.cable, colorScheme),
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
                    value == null ? localizations.selectJumperStatus : null,
              ),
              const SizedBox(height: 15),

              // Hot Spots (Dropdown)
              DropdownButtonFormField<String>(
                value: _hotSpotsController.text.isNotEmpty
                    ? _hotSpotsController.text
                    : null,
                decoration: _inputDecoration(
                    localizations.hotSpots, Icons.fireplace, colorScheme),
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
                    value == null ? localizations.selectHotSpotStatus : null,
              ),
              const SizedBox(height: 15),

              // Number Plate (Dropdown)
              DropdownButtonFormField<String>(
                value: _numberPlate,
                decoration: _inputDecoration(
                    localizations.numberPlate, Icons.looks_one, colorScheme),
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
                validator: (value) => value == null
                    ? localizations.selectNumberPlateStatus
                    : null,
              ),
              const SizedBox(height: 15),

              // Danger Board (Dropdown)
              DropdownButtonFormField<String>(
                value: _dangerBoard,
                decoration: _inputDecoration(
                    localizations.dangerBoard, Icons.warning, colorScheme),
                items: numberPlateOptions // Reuse options if applicable
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
                validator: (value) => value == null
                    ? localizations.selectDangerBoardStatus
                    : null,
              ),
              const SizedBox(height: 15),

              // Phase Plate (Dropdown)
              DropdownButtonFormField<String>(
                value: _phasePlate,
                decoration: _inputDecoration(localizations.phasePlate,
                    Icons.power_outlined, colorScheme),
                items: numberPlateOptions // Reuse options if applicable
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
                    value == null ? localizations.selectPhasePlateStatus : null,
              ),
              const SizedBox(height: 15),

              // Nut and Bolt Condition (Dropdown)
              DropdownButtonFormField<String>(
                value: _nutAndBoltCondition,
                decoration: _inputDecoration(localizations.nutAndBoltCondition,
                    Icons.handyman, colorScheme),
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
                validator: (value) => value == null
                    ? localizations.selectNutAndBoltCondition
                    : null,
              ),
              const SizedBox(height: 15),

              // Anti Climbing Device (Dropdown)
              DropdownButtonFormField<String>(
                value: _antiClimbingDevice,
                decoration: _inputDecoration(
                    localizations.antiClimbingDevice, Icons.block, colorScheme),
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
                validator: (value) => value == null
                    ? localizations.selectAntiClimbingDeviceStatus
                    : null,
              ),
              const SizedBox(height: 15),

              // Wild Growth (Dropdown)
              DropdownButtonFormField<String>(
                value: _wildGrowthController.text.isNotEmpty
                    ? _wildGrowthController.text
                    : null,
                decoration: _inputDecoration(
                    localizations.wildGrowth, Icons.forest, colorScheme),
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
                    value == null ? localizations.selectWildGrowthStatus : null,
              ),
              const SizedBox(height: 15),

              // Bird Guard (Dropdown)
              DropdownButtonFormField<String>(
                value: _birdGuard,
                decoration: _inputDecoration(
                    localizations.birdGuard, Icons.architecture, colorScheme),
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
                    value == null ? localizations.selectBirdGuardStatus : null,
              ),
              const SizedBox(height: 15),

              // Bird Nest (Dropdown)
              DropdownButtonFormField<String>(
                value: _birdNestController.text.isNotEmpty
                    ? _birdNestController.text
                    : null,
                decoration: _inputDecoration(
                    localizations.birdNest, Icons.grass, colorScheme),
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
                    value == null ? localizations.selectBirdNestStatus : null,
              ),
              const SizedBox(height: 15),

              // Arching Horn (Dropdown)
              DropdownButtonFormField<String>(
                value: _archingHornController.text.isNotEmpty
                    ? _archingHornController.text
                    : null,
                decoration: _inputDecoration(
                    localizations.archingHorn, Icons.flash_on, colorScheme),
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
                validator: (value) => value == null
                    ? localizations.selectArchingHornStatus
                    : null,
              ),
              const SizedBox(height: 15),

              // Corona Ring (Dropdown)
              DropdownButtonFormField<String>(
                value: _coronaRingController.text.isNotEmpty
                    ? _coronaRingController.text
                    : null,
                decoration: _inputDecoration(
                    localizations.coronaRing, Icons.circle, colorScheme),
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
                    value == null ? localizations.selectCoronaRingStatus : null,
              ),
              const SizedBox(height: 15),

              // Insulator Type (Dropdown)
              DropdownButtonFormField<String>(
                value: _insulatorTypeController.text.isNotEmpty
                    ? _insulatorTypeController.text
                    : null,
                decoration: _inputDecoration(localizations.insulatorType,
                    Icons.electric_bolt, colorScheme),
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
                    value == null ? localizations.selectInsulatorType : null,
              ),
              const SizedBox(height: 15),

              // OPGW Joint Box (Dropdown)
              DropdownButtonFormField<String>(
                value: _opgwJointBoxController.text.isNotEmpty
                    ? _opgwJointBoxController.text
                    : null,
                decoration: _inputDecoration(
                    localizations.opgwJointBox, Icons.cable, colorScheme),
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
                validator: (value) => value == null
                    ? localizations.selectOpgwJointBoxStatus
                    : null,
              ),
              const SizedBox(height: 15),

              // Missing Tower Parts (TextFormField - Moved to end)
              TextFormField(
                controller: _missingTowerPartsController,
                decoration: _inputDecoration(localizations.missingTowerParts,
                    Icons.precision_manufacturing, colorScheme),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 30),

              // Continue to Line Survey Button
              _isSavingDetails
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _navigateToLineSurveyScreen,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(localizations.continueToLineSurvey),
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
      isDense: true,
      labelStyle: TextStyle(
          color: colorScheme.primary.withOpacity(0.8),
          overflow: TextOverflow.ellipsis),
    );
  }
}
