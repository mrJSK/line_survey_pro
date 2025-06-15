// lib/screens/line_detail_screen.dart
// Displays details for a specific transmission line/task and allows adding new survey entries.

import 'dart:async'; // For Timer and StreamSubscription
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // For GPS coordinates
import 'package:line_survey_pro/models/task.dart'; // Import Task model
import 'package:line_survey_pro/screens/camera_screen.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:line_survey_pro/services/permission_service.dart';
import 'package:line_survey_pro/services/location_service.dart';
import 'package:line_survey_pro/services/local_database_service.dart'; // For validation
import 'package:line_survey_pro/services/auth_service.dart'; // For current user ID
import 'package:line_survey_pro/services/survey_firestore_service.dart'; // For fetching cloud records for validation

class LineDetailScreen extends StatefulWidget {
  final Task task;

  const LineDetailScreen({
    super.key,
    required this.task,
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
      10.0; // Minimum accuracy required to proceed

  final LocalDatabaseService _localDatabaseService =
      LocalDatabaseService(); // Used for local survey record saving
  final AuthService _authService = AuthService();
  final SurveyFirestoreService _surveyFirestoreService =
      SurveyFirestoreService(); // Used for fetching cloud records for validation

  static const double _minDistanceMeters =
      200.0; // Min distance between different towers
  static const double _sameTowerToleranceMeters =
      20.0; // Tolerance for re-surveying same tower number

  // Add properties to parse the targetTowerRange for validation
  int? _minTower;
  int? _maxTower;
  bool _isAllTowers = false;

  @override
  void initState() {
    super.initState();
    _parseTowerRange(widget.task.targetTowerRange);
    _getCurrentLocation();
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
      _minTower = null; // No specific min/max for "all"
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
      // Single tower case
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
        SnackBarUtils.showSnackBar(context, 'Location permission denied.',
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
                'Required accuracy (${position.accuracy.toStringAsFixed(2)}m) achieved!',
                isError: false,
              );
            }
          });
        }
      }, onError: (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Error getting location stream: ${e.toString()}',
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
                ? 'Current accuracy is ${_currentPosition!.accuracy.toStringAsFixed(2)}m, which is above the required ${_requiredAccuracyForCapture.toStringAsFixed(1)}m. Move to an open area.'
                : 'Could not get any location within $_maximumWaitSeconds seconds. Please try again.';
            SnackBarUtils.showSnackBar(
              context,
              'Timeout reached. $accuracyMessage',
              isError: true,
            );
          } else if (mounted && _currentPosition != null) {
            SnackBarUtils.showSnackBar(
              context,
              'Location acquired with best available accuracy: ${_currentPosition!.accuracy.toStringAsFixed(2)}m.',
              isError: false,
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'An unexpected error occurred while starting location: $e',
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
    // Validate against assigned task range from manager
    if (!_isAllTowers) {
      if (_minTower != null && _maxTower != null) {
        if (towerNumber < _minTower! || towerNumber > _maxTower!) {
          if (mounted) {
            SnackBarUtils.showSnackBar(
              context,
              'Tower number $towerNumber is outside the assigned range (${widget.task.targetTowerRange}).',
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
              'You are assigned to survey only Tower ${widget.task.targetTowerRange}.',
              isError: true,
            );
          }
          return false;
        }
      }
    }

    // CRITICAL CHANGE: Validate against ALL *uploaded* survey records from Firestore.
    // This ensures cross-device validation for previously surveyed points.
    final allUploadedRecordsForLine =
        (await _surveyFirestoreService.streamAllSurveyRecords().first)
            .where((record) =>
                record.lineName == widget.task.lineName &&
                record.status == 'uploaded')
            .toList();

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

    for (var record in allUploadedRecordsForLine) {
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

      // Rule 1: Cannot re-survey the SAME tower number too close to its previous (uploaded) record.
      // This prevents multiple surveys of the *same* tower number at essentially the same spot.
      if (record.towerNumber == towerNumber &&
          distance < _sameTowerToleranceMeters) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'A survey for Tower $towerNumber at this location (${distance.toStringAsFixed(2)}m from previous record) already exists for Line ${widget.task.lineName}. Please ensure you are at a new tower or update the existing record if this is a re-survey.',
            isError: true,
          );
        }
        return false;
      }

      // Rule 2: Cannot survey a DIFFERENT tower that is too close to an existing surveyed (uploaded) tower on the same line.
      // This prevents surveying adjacent towers if they are too close together, ensuring distinct survey points.
      if (record.towerNumber != towerNumber && distance < _minDistanceMeters) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Another surveyed tower on Line ${widget.task.lineName} is too close (${distance.toStringAsFixed(2)}m from Tower ${record.towerNumber}). All DIFFERENT survey points on the same line must be at least ${_minDistanceMeters.toStringAsFixed(0)} meters apart.',
            isError: true,
          );
        }
        return false;
      }
    }
    return true; // All validations passed
  }

  void _navigateToCameraScreen() async {
    if (_formKey.currentState!.validate()) {
      if (_currentPosition == null || !_isLocationAccurateEnough) {
        SnackBarUtils.showSnackBar(context,
            'Accuracy less than ${_requiredAccuracyForCapture.toStringAsFixed(1)}m. Please wait or move to an open area for better GPS signal.',
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
          SnackBarUtils.showSnackBar(
              context, 'User not logged in. Cannot save survey.',
              isError: true);
        }
        return;
      }

      // Navigate to CameraScreen, passing task details
      final String? newSurveyRecordId = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            lineName: widget.task.lineName,
            towerNumber: towerNumber,
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            taskId: widget.task.id,
            userId: currentUserId,
          ),
        ),
      );

      // After returning from CameraScreen (photo saved locally)
      if (newSurveyRecordId != null) {
        if (mounted) {
          Navigator.of(context)
              .pop(); // Go back to Real-Time Tasks list (or wherever it came from)
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    String accuracyStatusText;
    Color accuracyStatusColor;
    if (_isFetchingLocation) {
      accuracyStatusText =
          'Fetching... Current: ${_currentPosition?.accuracy.toStringAsFixed(2) ?? 'N/A'}m';
      accuracyStatusColor = colorScheme.onSurface.withOpacity(0.6);
    } else if (_currentPosition == null) {
      accuracyStatusText = 'No location obtained.';
      accuracyStatusColor = colorScheme.error;
    } else if (_currentPosition!.accuracy <= _requiredAccuracyForCapture) {
      accuracyStatusText =
          'Achieved: ${_currentPosition!.accuracy.toStringAsFixed(2)}m (Required < ${_requiredAccuracyForCapture.toStringAsFixed(1)}m)';
      accuracyStatusColor = colorScheme.secondary;
    } else {
      accuracyStatusText =
          'Current: ${_currentPosition!.accuracy.toStringAsFixed(2)}m (Required < ${_requiredAccuracyForCapture.toStringAsFixed(1)}m)';
      accuracyStatusColor = colorScheme.tertiary;
    }

    String towerRangeDisplay = widget.task.targetTowerRange;
    if (_isAllTowers) {
      towerRangeDisplay = 'All Towers';
    } else if (_minTower != null && _maxTower != null) {
      towerRangeDisplay = 'Towers ${_minTower!}-${_maxTower!}';
    } else if (_minTower != null) {
      // Single tower case
      towerRangeDisplay = 'Tower ${_minTower!}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.task.lineName} - Survey Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Details Card
            Card(
              margin: EdgeInsets.zero,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Task Details:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Line Name: ${widget.task.lineName}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      'Assigned Towers: $towerRangeDisplay',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      'Due Date: ${widget.task.dueDate.toLocal().toString().split(' ')[0]}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      'Status: ${widget.task.status}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // New Survey Entry Form
            Text(
              'Add New Survey Record',
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
                          labelText: 'Tower Number',
                          prefixIcon:
                              Icon(Icons.numbers, color: colorScheme.primary),
                          hintText: 'Enter tower number',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a tower number';
                          }
                          final int? towerNum = int.tryParse(value);
                          if (towerNum == null || towerNum <= 0) {
                            return 'Please enter a valid positive number';
                          }
                          // Validate against assigned range
                          if (!_isAllTowers) {
                            if (_minTower != null && _maxTower != null) {
                              if (towerNum < _minTower! ||
                                  towerNum > _maxTower!) {
                                return 'Tower must be within ${widget.task.targetTowerRange}';
                              }
                            } else if (_minTower != null) {
                              // Single tower assigned
                              if (towerNum != _minTower!) {
                                return 'Tower must be ${widget.task.targetTowerRange}';
                              }
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // GPS Coordinates Display Card
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
                                    'Current GPS Coordinates:',
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
                                    tooltip: 'Refresh Location',
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
                                            Text('Fetching location...',
                                                style: TextStyle(
                                                    color:
                                                        colorScheme.onSurface)),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        // Dynamic display of current accuracy while fetching
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
                                        // Show timer countdown if active
                                        if (_accuracyTimeoutTimer != null &&
                                            _accuracyTimeoutTimer!.isActive)
                                          Text(
                                            'Timeout in ${_maximumWaitSeconds - (_accuracyTimeoutTimer?.tick ?? 0)}s',
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
                                      // Display final coordinates and accuracy
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Lat: ${_currentPosition?.latitude.toStringAsFixed(6) ?? 'N/A'}\n'
                                          'Lon: ${_currentPosition?.longitude.toStringAsFixed(6) ?? 'N/A'}',
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
                                    label: Text('Get Current Location',
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
                            ? _navigateToCameraScreen
                            : null,
                        icon: const Icon(Icons.camera_alt),
                        label: Text((_currentPosition != null &&
                                _isLocationAccurateEnough)
                            ? 'Click Photo'
                            : (_isFetchingLocation
                                ? 'Getting Location...'
                                : 'Required Accuracy Not Met')),
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
