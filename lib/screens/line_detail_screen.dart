// lib/screens/line_detail_screen.dart
// Displays details for a specific transmission line and allows adding new survey entries.

import 'dart:async'; // For Timer and StreamSubscription
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // For GPS coordinates
import 'package:line_survey_pro/models/transmission_line.dart';
import 'package:line_survey_pro/screens/camera_screen.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:line_survey_pro/services/permission_service.dart';
import 'package:line_survey_pro/services/location_service.dart';
import 'package:line_survey_pro/services/local_database_service.dart'; // For validation

class LineDetailScreen extends StatefulWidget {
  final TransmissionLine line;

  const LineDetailScreen({
    super.key,
    required this.line,
  });

  @override
  State<LineDetailScreen> createState() => _LineDetailScreenState();
}

class _LineDetailScreenState extends State<LineDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _towerNumberController = TextEditingController();
  Position? _currentPosition;
  bool _isFetchingLocation = false;
  bool _isLocationAccurateEnough =
      false; // State to track if desired accuracy is met
  StreamSubscription<Position>?
      _positionStreamSubscription; // For continuous updates
  Timer? _accuracyTimeoutTimer; // Timer for maximum wait time
  static const int _maximumWaitSeconds =
      30; // Max wait time for accuracy acquisition
  static const double _desiredAccuracyMeters = 5.0; // Target accuracy set to 5m
  static const double _requiredAccuracyForCapture =
      10.0; // Minimum accuracy required to proceed

  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();

  // Define the minimum distance threshold in meters
  static const double _minDistanceMeters = 200.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Get current location on init
  }

  @override
  void dispose() {
    _towerNumberController.dispose();
    _positionStreamSubscription
        ?.cancel(); // Cancel stream to prevent memory leaks
    _accuracyTimeoutTimer?.cancel(); // Cancel timer
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (_isFetchingLocation) return; // Prevent multiple simultaneous fetches

    setState(() {
      _isFetchingLocation = true;
      _isLocationAccurateEnough = false; // Reset status
      _currentPosition = null; // Clear previous position
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

    // Cancel any existing stream and timer before starting new ones
    _positionStreamSubscription?.cancel();
    _accuracyTimeoutTimer?.cancel();

    try {
      // Start listening to continuous location updates with best accuracy
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best, // Request maximum accuracy
          distanceFilter: 0, // Get updates frequently, even for small movements
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            // Check if accuracy is within the required threshold (10m)
            if (position.accuracy <= _requiredAccuracyForCapture) {
              _isLocationAccurateEnough = true;
              _isFetchingLocation = false; // Stop loading indicator
              _accuracyTimeoutTimer?.cancel(); // Stop the timeout timer
              _positionStreamSubscription?.cancel(); // Stop listening
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

      // Start a timeout timer for maximum wait time
      _accuracyTimeoutTimer =
          Timer(const Duration(seconds: _maximumWaitSeconds), () {
        if (mounted) {
          setState(() {
            // After timeout, if desired accuracy not met, then it's NOT accurate enough
            _isLocationAccurateEnough = (_currentPosition != null &&
                _currentPosition!.accuracy <=
                    _requiredAccuracyForCapture); // Strict check
            _isFetchingLocation = false; // Stop fetching indicator
          });
          _positionStreamSubscription
              ?.cancel(); // Stop listening to further updates

          if (!_isLocationAccurateEnough && mounted) {
            String accuracyMessage = _currentPosition != null
                ? 'Current accuracy is ${_currentPosition!.accuracy.toStringAsFixed(2)}m, which is above the required ${_requiredAccuracyForCapture.toStringAsFixed(1)}m. Move to an open area.'
                : 'Could not get any location within $_maximumWaitSeconds seconds. Please try again.';
            SnackBarUtils.showSnackBar(
              context,
              'Timeout reached. $accuracyMessage',
              isError: true, // Mark as error since requirement wasn't met
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

  Future<bool> _validateSurveyEntry(String lineName, int towerNumber,
      double latitude, double longitude) async {
    final allExistingRecordsForLine =
        await _localDatabaseService.getSurveyRecordsByLine(lineName);

    final newPosition = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy:
          0.0, // This is just a placeholder, actual accuracy is in _currentPosition
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );

    for (var record in allExistingRecordsForLine) {
      final existingPosition = Position(
        latitude: record.latitude,
        longitude: record.longitude,
        timestamp: record.timestamp,
        accuracy: 0.0, // Placeholder
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

      // If it's the SAME tower number being surveyed again, allow a larger tolerance for GPS drift.
      if (record.towerNumber == towerNumber && distance < 20.0) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'A survey for Tower $towerNumber at this location (${distance.toStringAsFixed(2)}m from previous record) already exists for Line $lineName. Please ensure you are at a new tower or update the existing record if this is a re-survey.',
            isError: true,
          );
        }
        return false;
      }

      // This check applies to DIFFERENT towers on the SAME line.
      // If the new point is too close to *any other* existing point on the same line, reject it.
      if (distance < _minDistanceMeters) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Another survey point on Line $lineName is too close (${distance.toStringAsFixed(2)}m). All survey points on the same line must be at least ${_minDistanceMeters.toStringAsFixed(0)} meters apart.',
            isError: true,
          );
        }
        return false;
      }
    }
    return true;
  }

  void _navigateToCameraScreen() async {
    if (_formKey.currentState!.validate()) {
      if (_currentPosition == null || !_isLocationAccurateEnough) {
        // This condition now strictly checks if _isLocationAccurateEnough is true
        SnackBarUtils.showSnackBar(context,
            'Accuracy less than ${_requiredAccuracyForCapture.toStringAsFixed(1)}m. Please wait or move to an open area for better GPS signal.',
            isError: true);
        if (!_isFetchingLocation) {
          _getCurrentLocation();
        }
        return;
      }

      final String lineName = widget.line.name;
      final int towerNumber = int.parse(_towerNumberController.text);
      final double latitude = _currentPosition!.latitude;
      final double longitude = _currentPosition!.longitude;

      final isValid = await _validateSurveyEntry(
          lineName, towerNumber, latitude, longitude);

      if (!isValid) {
        return;
      }

      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            lineName: lineName,
            towerNumber: towerNumber,
            latitude: latitude,
            longitude: longitude,
          ),
        ),
      )
          .then((_) {
        Navigator.of(context).pop();
      });
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
      accuracyStatusColor =
          colorScheme.tertiary; // Warning color for insufficient accuracy
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.line.name} - Survey Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line Details Card
            Card(
              margin: EdgeInsets.zero,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transmission Line Details:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Name: ${widget.line.name}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      'Total Towers: ${widget.line.totalTowers}',
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
                          if (int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return 'Please enter a valid positive number';
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
                                          'Lon: ${_currentPosition?.longitude.toStringAsFixed(6) ?? 'N/A'}', // Fixed to 6 decimal places
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
                            : null, // Disable button if location isn't ready
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
