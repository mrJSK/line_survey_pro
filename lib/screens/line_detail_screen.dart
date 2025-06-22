// lib/screens/line_detail_screen.dart
// Displays details for a specific transmission line/task and allows adding new survey entries.

import 'dart:async'; // For Timer and StreamSubscription
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // For GPS coordinates
import 'package:line_survey_pro/models/task.dart'; // Import Task model
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:line_survey_pro/services/permission_service.dart';
import 'package:line_survey_pro/services/local_database_service.dart'; // For local database records
import 'package:line_survey_pro/services/auth_service.dart'; // For current user ID
import 'package:line_survey_pro/services/survey_firestore_service.dart'; // For fetching cloud records for validation
import 'package:line_survey_pro/models/survey_record.dart'; // Import SurveyRecord for validation
import 'package:line_survey_pro/screens/patrolling_detail_screen.dart'; // Import PatrollingDetailScreen
import 'package:line_survey_pro/models/transmission_line.dart'; // Import TransmissionLine
import 'package:line_survey_pro/l10n/app_localizations.dart';

class LineDetailScreen extends StatefulWidget {
  final Task task;
  final TransmissionLine transmissionLine; // Receive TransmissionLine

  const LineDetailScreen({
    super.key,
    required this.task,
    required this.transmissionLine, // Make it required
  });

  @override
  State<LineDetailScreen> createState() => _LineDetailScreenState();
}

class _LineDetailScreenState extends State<LineDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _towerNumberController = TextEditingController();
  Position? _currentPosition;
  bool _isFetchingLocation = false;
  bool _isLocationAccurateEnough = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _accuracyTimeoutTimer;
  static const int _maximumWaitSeconds = 30;
  static const double _requiredAccuracyForCapture =
      20.0; // Minimum accuracy required to proceed

  final LocalDatabaseService _localDatabaseService =
      LocalDatabaseService(); // Used for local survey record saving
  final AuthService _authService = AuthService();
  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService();

  static const double _minDistanceMeters =
      200.0; // Min distance between different towers
  static const double _sameTowerToleranceMeters =
      20.0; // Tolerance for re-surveying same tower number

  int? _minTower;
  int? _maxTower;
  bool _isAllTowers = false;

  @override
  void initState() {
    super.initState();
    _parseTowerRange(widget.task.targetTowerRange);
    _getCurrentLocation(); // This is already called here
  }

  @override
  void dispose() {
    _towerNumberController.dispose();
    _positionStreamSubscription?.cancel();
    _accuracyTimeoutTimer?.cancel();
    super.dispose();
  }

  void _parseTowerRange(String range) {
    range = range.trim().toLowerCase();
    if (range == 'all') {
      _isAllTowers = true;
      _minTower = null;
      _maxTower = null;
    } else if (range.contains('-')) {
      final parts = range.split('-');
      if (parts.length == 2) {
        _minTower = int.tryParse(parts[0].trim());
        _maxTower = int.tryParse(parts[1].trim());
        if (_minTower == null || _maxTower == null || _minTower! > _maxTower!) {
          print('Warning: Invalid tower range format (from-to): $range');
          _minTower = null;
          _maxTower = null;
          _isAllTowers = false;
        }
      } else {
        print('Warning: Invalid tower range format (multiple hyphens): $range');
        _minTower = null;
        _maxTower = null;
        _isAllTowers = false;
      }
    } else {
      _minTower = int.tryParse(range);
      _maxTower = _minTower;
      if (_minTower == null) {
        print('Warning: Invalid single tower number: $range');
        _minTower = null;
        _maxTower = null;
        _isAllTowers = false;
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    // Removed: final localizations = AppLocalizations.of(context)!;
    if (_isFetchingLocation) return;

    setState(() {
      _isFetchingLocation = true;
      _isLocationAccurateEnough = false;
      _currentPosition = null;
    });

    final hasPermission =
        await PermissionService().requestLocationPermission(context);
    if (!hasPermission) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, AppLocalizations.of(context)!.locationPermissionDenied,
            isError: true);
      }
      setState(() {
        _isFetchingLocation = false;
      });
      return;
    }

    _positionStreamSubscription?.cancel();
    _accuracyTimeoutTimer?.cancel();

    try {
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            if (position.accuracy <= _requiredAccuracyForCapture) {
              _isLocationAccurateEnough = true;
              _isFetchingLocation = false;
              _accuracyTimeoutTimer?.cancel();
              _positionStreamSubscription?.cancel();
              SnackBarUtils.showSnackBar(
                context,
                AppLocalizations.of(context)!.requiredAccuracyAchieved(
                    position.accuracy.toStringAsFixed(2),
                    _requiredAccuracyForCapture.toStringAsFixed(1)),
                isError: false,
              );
            }
          });
        }
      }, onError: (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(context,
              AppLocalizations.of(context)!.errorGettingLocation(e.toString()),
              isError: true);
          setState(() {
            _isFetchingLocation = false;
            _isLocationAccurateEnough = false;
          });
        }
        _positionStreamSubscription?.cancel();
        _accuracyTimeoutTimer?.cancel();
      });

      _accuracyTimeoutTimer =
          Timer(const Duration(seconds: _maximumWaitSeconds), () {
        if (mounted) {
          setState(() {
            _isLocationAccurateEnough = (_currentPosition != null &&
                _currentPosition!.accuracy <= _requiredAccuracyForCapture);
            _isFetchingLocation = false;
          });
          _positionStreamSubscription?.cancel();

          if (!_isLocationAccurateEnough && mounted) {
            String accuracyMessage = _currentPosition != null
                ? AppLocalizations.of(context)!.currentAccuracy(
                        _currentPosition!.accuracy.toStringAsFixed(2),
                        _requiredAccuracyForCapture.toStringAsFixed(1)) +
                    '. ' +
                    AppLocalizations.of(context)!.moveToOpenArea
                : AppLocalizations.of(context)!
                    .couldNotGetLocationWithinSeconds(_maximumWaitSeconds);
            SnackBarUtils.showSnackBar(
              context,
              AppLocalizations.of(context)!.timeoutReached(accuracyMessage),
              isError: true,
            );
          } else if (mounted && _currentPosition != null) {
            SnackBarUtils.showSnackBar(
              context,
              AppLocalizations.of(context)!.locationAcquired(_currentPosition!
                  .accuracy
                  .toStringAsFixed(2)), // Assuming new string
              isError: false,
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context,
            AppLocalizations.of(context)!
                .unexpectedErrorStartingLocation(e.toString()),
            isError: true);
        setState(() {
          _isFetchingLocation = false;
          _isLocationAccurateEnough = false;
        });
      }
      _positionStreamSubscription?.cancel();
      _accuracyTimeoutTimer?.cancel();
    }
  }

  Future<bool> _validateSurveyEntry(int towerNumber) async {
    final localizations = AppLocalizations.of(context)!;
    // Validate against assigned task range from manager
    if (!_isAllTowers) {
      if (_minTower != null && _maxTower != null) {
        if (towerNumber < _minTower! || towerNumber > _maxTower!) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              localizations.towerOutOfRange(
                  towerNumber, widget.task.targetTowerRange),
              isError: true,
            );
          }
          return false;
        }
      } else if (_minTower != null) {
        // Case for a single assigned tower number
        if (towerNumber != _minTower!) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              localizations.towerSpecificRequired(widget.task.targetTowerRange),
              isError: true,
            );
          }
          return false;
        }
      }
    }

    // Get all *uploaded* survey records for this line from Firestore.
    final allUploadedRecordsForLine =
        (await _surveyFirestoreService.streamAllSurveyRecords().first)
            .where((record) =>
                record.lineName == widget.task.lineName &&
                record.status == 'uploaded')
            .toList();

    // Get all *local* survey records for this line from SQLite.
    final allLocalRecordsForLine = await _localDatabaseService
        .getSurveyRecordsByLine(widget.task.lineName);

    // Combine these two lists into a single list for validation.
    // Ensure that records are unique by ID, preferring the Firestore version for status if an ID matches.
    Map<String, SurveyRecord> allRecordsForValidation = {};
    for (var record in allLocalRecordsForLine) {
      allRecordsForValidation[record.id] = record;
    }
    for (var record in allUploadedRecordsForLine) {
      allRecordsForValidation[record.id] = record;
    }
    final List<SurveyRecord> recordsToValidateAgainst =
        allRecordsForValidation.values.toList();

    // Debugging: Print records being validated against to confirm lineName filtering
    print(
        'DEBUG: Validating against ${recordsToValidateAgainst.length} records for line: ${widget.task.lineName}');
    for (var record in recordsToValidateAgainst) {
      print(
          'DEBUG: Record being validated: ID: ${record.id}, Line: ${record.lineName}, Tower: ${record.towerNumber}, Status: ${record.status}, Lat: ${record.latitude}, Lon: ${record.longitude}');
    }

    final newPosition = Position(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );

    for (var record in recordsToValidateAgainst) {
      // Ensure we are ONLY comparing records that actually belong to the current task's line.
      // This explicit check ensures no rogue records slip through if initial filtering failed (which it shouldn't).
      if (record.lineName != widget.task.lineName) {
        print(
            'DEBUG WARNING: Record with ID ${record.id} and line ${record.lineName} found in validation list for task line ${widget.task.lineName}. This should not happen.');
        continue; // Skip this record, it's not for the current line
      }

      final existingPosition = Position(
        latitude: record.latitude,
        longitude: record.longitude,
        timestamp: record.timestamp,
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final distance = Geolocator.distanceBetween(
        existingPosition.latitude,
        existingPosition.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );

      // Rule 1: Cannot re-survey the SAME tower number too close to its previous (any status) record.
      if (record.towerNumber == towerNumber &&
          distance < _sameTowerToleranceMeters) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            localizations.towerAlreadyExists(
                towerNumber, distance.toStringAsFixed(2), widget.task.lineName),
            isError: true,
          );
        }
        return false;
      }

      // Rule 2: Cannot survey a DIFFERENT tower that is too close to an existing (any status) tower on the same line.
      if (record.towerNumber != towerNumber && distance < _minDistanceMeters) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            localizations.towerTooClose(
                widget.task.lineName,
                distance.toStringAsFixed(2),
                record.towerNumber,
                _minDistanceMeters.toStringAsFixed(0)),
            isError: true,
          );
        }
        return false;
      }
    }
    return true; // All validations passed
  }

  void _navigateToPatrollingDetailScreen() async {
    final localizations = AppLocalizations.of(context)!;

    if (_formKey.currentState!.validate()) {
      if (_currentPosition == null || !_isLocationAccurateEnough) {
        SnackBarUtils.showSnackBar(
            context,
            localizations
                .accuracyLow(_requiredAccuracyForCapture.toStringAsFixed(1)),
            isError: true);
        if (!_isFetchingLocation) {
          _getCurrentLocation();
        }
        return;
      }

      final int towerNumber = int.parse(_towerNumberController.text);

      final isValid = await _validateSurveyEntry(towerNumber);

      if (!isValid) {
        return;
      }

      final String? currentUserId = _authService.getCurrentUser()?.uid;
      if (currentUserId == null) {
        if (mounted) {
          SnackBarUtils.showSnackBar(context, localizations.userNotLoggedIn,
              isError: true);
        }
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PatrollingDetailScreen(
            initialRecord: SurveyRecord(
              lineName: widget.task.lineName,
              towerNumber: towerNumber,
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
              timestamp: DateTime.now(),
              photoPath: '',
              status: 'saved_photo_only',
              taskId: widget.task.id,
              userId: currentUserId,
            ),
            transmissionLine: widget.transmissionLine,
          ),
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    String accuracyStatusText;
    Color accuracyStatusColor;
    if (_isFetchingLocation) {
      accuracyStatusText =
          '${localizations.fetchingLocation}... ${localizations.current}: ${_currentPosition?.accuracy.toStringAsFixed(2) ?? 'N/A'}m'; // Assuming 'current' string
      accuracyStatusColor = colorScheme.onSurface.withOpacity(0.6);
    } else if (_currentPosition == null) {
      accuracyStatusText = localizations.noLocationObtained;
      accuracyStatusColor = colorScheme.error;
    } else if (_currentPosition!.accuracy <= _requiredAccuracyForCapture) {
      accuracyStatusText = localizations.requiredAccuracyAchieved(
          _currentPosition!.accuracy.toStringAsFixed(2),
          _requiredAccuracyForCapture.toStringAsFixed(1));
      accuracyStatusColor = colorScheme.secondary;
    } else {
      accuracyStatusText = localizations.currentAccuracy(
          _currentPosition!.accuracy.toStringAsFixed(2),
          _requiredAccuracyForCapture.toStringAsFixed(1));
      accuracyStatusColor = colorScheme.tertiary;
    }

    String towerRangeDisplay = widget.task.targetTowerRange;
    if (_isAllTowers) {
      towerRangeDisplay = localizations.allTowers; // Assuming new string
    } else if (_minTower != null && _maxTower != null) {
      towerRangeDisplay = '${localizations.towers} ${_minTower!}-${_maxTower!}';
    } else if (_minTower != null) {
      towerRangeDisplay = '${localizations.tower} ${_minTower!}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.task.lineName} - ${localizations.surveyEntry}'), // Assuming new string
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.zero,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.assignedTaskDetails,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${localizations.lineNameField}: ${widget.task.lineName}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      '${localizations.assignedTowers}: $towerRangeDisplay',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      '${localizations.dueDateField}: ${widget.task.dueDate.toLocal().toString().split(' ')[0]}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      '${localizations.status}: ${widget.task.derivedStatus}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              localizations.addNewSurveyRecord,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 15),
            Card(
              margin: EdgeInsets.zero,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _towerNumberController,
                        decoration: InputDecoration(
                          labelText: localizations.towerNumberField,
                          prefixIcon:
                              Icon(Icons.numbers, color: colorScheme.primary),
                          hintText: localizations.enterTowerNumber,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.towerNumberInvalid;
                          }
                          final int? towerNum = int.tryParse(value);
                          if (towerNum == null || towerNum <= 0) {
                            return localizations.towerNumberPositive;
                          }
                          if (!_isAllTowers) {
                            if (_minTower != null && _maxTower != null) {
                              if (towerNum < _minTower! ||
                                  towerNum > _maxTower!) {
                                return localizations.towerOutOfRange(
                                    towerNum, widget.task.targetTowerRange);
                              }
                            } else if (_minTower != null) {
                              if (towerNum != _minTower!) {
                                return localizations.towerSpecificRequired(
                                    widget.task.targetTowerRange);
                              }
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 2,
                        color: colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: colorScheme.primary.withOpacity(0.1)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    localizations.gpsCoordinates,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                  ),
                                  IconButton(
                                    onPressed: _isFetchingLocation
                                        ? null
                                        : _getCurrentLocation,
                                    icon: Icon(
                                      Icons.refresh,
                                      color: _isFetchingLocation
                                          ? Colors.grey
                                          : colorScheme.secondary,
                                    ),
                                    tooltip: localizations.refreshLocation,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _isFetchingLocation
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          colorScheme.primary)),
                                            ),
                                            const SizedBox(width: 15),
                                            Text(localizations.fetchingLocation,
                                                style: TextStyle(
                                                    color:
                                                        colorScheme.onSurface)),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          accuracyStatusText,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: accuracyStatusColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        if (_accuracyTimeoutTimer != null &&
                                            _accuracyTimeoutTimer!.isActive)
                                          Text(
                                            localizations.timeoutInSeconds(
                                                _maximumWaitSeconds -
                                                    (_accuracyTimeoutTimer
                                                            ?.tick ??
                                                        0)),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: colorScheme.tertiary,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                          ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${localizations.lat}: ${_currentPosition?.latitude.toStringAsFixed(6) ?? 'N/A'}\n'
                                          '${localizations.lon}: ${_currentPosition?.longitude.toStringAsFixed(6) ?? 'N/A'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  color: colorScheme.onSurface),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          accuracyStatusText,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: accuracyStatusColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                              if (_currentPosition == null &&
                                  !_isFetchingLocation)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: TextButton.icon(
                                    icon: Icon(Icons.location_searching,
                                        size: 20, color: colorScheme.secondary),
                                    label: Text(
                                        localizations
                                            .getCurrentLocation, // Assuming new string
                                        style: TextStyle(
                                            color: colorScheme.secondary)),
                                    onPressed: _getCurrentLocation,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: (_currentPosition != null &&
                                _isLocationAccurateEnough)
                            ? _navigateToPatrollingDetailScreen
                            : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text((_currentPosition != null &&
                                _isLocationAccurateEnough)
                            ? localizations.continueToPatrollingDetails
                            : (_isFetchingLocation
                                ? localizations.gettingLocation
                                : localizations.requiredAccuracyNotMet)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          minimumSize: const Size(double.infinity, 55),
                          elevation: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
