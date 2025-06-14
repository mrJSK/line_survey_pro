// lib/screens/dashboard_tab.dart
// Displays survey progress and provides a form for new survey entry.
// Fetches transmission lines from Firestore, gets current GPS, and navigates to camera.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:geolocator/geolocator.dart'; // For GPS coordinates and distance calculation
import 'package:line_survey_pro/models/transmission_line.dart'; // TransmissionLine model
import 'package:line_survey_pro/services/local_database_service.dart'; // Local database interaction
import 'package:line_survey_pro/services/firestore_service.dart'; // Firestore service
import 'package:line_survey_pro/services/location_service.dart'; // Location service
import 'package:line_survey_pro/screens/camera_screen.dart'; // Camera screen navigation
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Snackbar utility
import 'package:line_survey_pro/services/permission_service.dart'; // Permission service for location
import 'dart:async'; // For StreamSubscription
// Import SurveyRecord for validation

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _formKey = GlobalKey<FormState>(); // Global key for the survey form
  List<TransmissionLine> _transmissionLines =
      []; // List of available transmission lines
  TransmissionLine? _selectedLine; // The currently selected transmission line
  final TextEditingController _towerNumberController =
      TextEditingController(); // Controller for tower number input
  Position? _currentPosition; // Current GPS coordinates
  bool _isLoadingLines = true; // State for loading transmission lines
  bool _isFetchingLocation = false; // State for fetching GPS location
  Map<String, int> _surveyProgress = {}; // Map: Line Name -> Towers Completed

  // Instantiate FirestoreService and LocalDatabaseService
  final FirestoreService _firestoreService = FirestoreService();
  final LocalDatabaseService _localDatabaseService =
      LocalDatabaseService(); // New instance for local DB access

  StreamSubscription?
      _linesSubscription; // To manage the Firestore stream subscription

  // Define the minimum distance threshold in meters
  static const double _minDistanceMeters = 200.0;

  @override
  void initState() {
    super.initState();
    _listenToTransmissionLines(); // Start listening to lines from Firestore
    _getCurrentLocation(); // Get current location on init
    _loadSurveyProgress(); // Load local survey progress on init
  }

  @override
  void dispose() {
    _towerNumberController
        .dispose(); // Dispose controller to prevent memory leaks
    _linesSubscription?.cancel(); // Cancel the Firestore stream subscription
    super.dispose();
  }

  // Listens to real-time updates for transmission lines from Firestore.
  Future<void> _listenToTransmissionLines() async {
    setState(() {
      _isLoadingLines = true; // Show loading indicator for lines
    });
    // Cancel any previous subscription to avoid multiple listeners
    _linesSubscription?.cancel();

    _linesSubscription = _firestoreService.getTransmissionLinesStream().listen(
      (lines) {
        if (mounted) {
          setState(() {
            _transmissionLines = lines;
            _isLoadingLines = false;
            // Re-select the line if it was previously selected and still exists.
            // If the previously selected line is no longer in the list, or if list is empty, clear selection.
            if (_selectedLine != null &&
                !lines.any((line) => line.id == _selectedLine!.id)) {
              _selectedLine =
                  null; // Deselect if the line is removed from Firestore
            } else if (_selectedLine == null && lines.isNotEmpty) {
              _selectedLine = lines
                  .first; // Select first line if none selected and lines exist
            } else if (lines.isEmpty) {
              _selectedLine = null; // Clear selection if no lines
            }
          });
          if (lines.isEmpty && mounted) {
            SnackBarUtils.showSnackBar(context,
                'No transmission lines found. Add new lines from the Firebase console or an admin screen.',
                isError: false);
          }
        }
      },
      onError: (error) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Error loading transmission lines: ${error.toString()}',
              isError: true);
          setState(() {
            _isLoadingLines = false; // Hide loading indicator on error
          });
        }
      },
      cancelOnError: true, // Automatically cancel subscription on error
    );
  }

  // Loads survey progress from the local database.
  Future<void> _loadSurveyProgress() async {
    final progress = await _localDatabaseService
        .getSurveyProgress(); // Use localDatabaseService
    if (mounted) {
      setState(() {
        _surveyProgress = progress; // Update survey progress map
      });
    }
  }

  // Fetches the current GPS location of the device.
  // Requests permission if not already granted.
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true; // Show loading for location
    });
    // Request location permission using PermissionService.
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
    try {
      Position position =
          await LocationService().getCurrentLocation(); // Get position
      if (mounted) {
        setState(() {
          _currentPosition = position; // Update current position
        });
      }
    } catch (e) {
      // Handle errors during location fetching.
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Could not get location: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false; // Hide loading for location
        });
        // If location is still null after fetching attempt, inform user.
        if (_currentPosition == null) {
          SnackBarUtils.showSnackBar(
            context,
            'Failed to get GPS location. Please ensure GPS is enabled and permissions are granted.',
            isError: true,
          );
        }
      }
    }
  }

  // NEW: Validation method for survey entry
  Future<bool> _validateSurveyEntry(String lineName, int towerNumber,
      double latitude, double longitude) async {
    // Fetch ALL existing records for this line, to check proximity regardless of tower number.
    // If we only query by line AND tower, we cannot check against other towers on the same line.
    final allExistingRecordsForLine =
        await _localDatabaseService.getSurveyRecordsByLine(
            lineName); // New method needed in LocalDatabaseService

    // Create Position object for the new survey
    final newPosition = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0, // Use 0.0 for non-nullable doubles
      headingAccuracy: 0.0, // Use 0.0 for non-nullable doubles
    );

    for (var record in allExistingRecordsForLine) {
      final existingPosition = Position(
        latitude: record.latitude,
        longitude: record.longitude,
        timestamp: record.timestamp,
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0, // Use 0.0 for non-nullable doubles
        headingAccuracy: 0.0, // Use 0.0 for non-nullable doubles
      );

      final distance = Geolocator.distanceBetween(
        existingPosition.latitude,
        existingPosition.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );

      // Rule 1: Prevent same line, same tower, same location (very close, e.g., < 1m)
      if (record.towerNumber == towerNumber && distance < 1.0) {
        if (mounted) {
          // Ensure context is still valid
          SnackBarUtils.showSnackBar(
            context,
            'A survey for Tower $towerNumber at this exact location already exists for Line $lineName. Please move to a different location or select a different tower.',
            isError: true,
          );
        }
        return false;
      }

      // Rule 2: Prevent ANY survey on this line if it's within _minDistanceMeters of an EXISTING survey on this line,
      // regardless of the tower number being surveyed.
      // This enforces a minimum distance between *any* two survey points on the same line.
      if (distance < _minDistanceMeters) {
        if (mounted) {
          // Ensure context is still valid
          SnackBarUtils.showSnackBar(
            context,
            'Another survey point on Line $lineName is too close (${distance.toStringAsFixed(2)}m). All survey points on the same line must be at least ${_minDistanceMeters.toStringAsFixed(0)} meters apart.',
            isError: true,
          );
        }
        return false;
      }
    }
    return true; // All validations passed
  }

  // Navigates to the CameraScreen if form is valid and location is available.
  void _navigateToCameraScreen() async {
    // Made async to await validation
    if (_formKey.currentState!.validate()) {
      // Validate form fields.
      if (_selectedLine == null) {
        SnackBarUtils.showSnackBar(
            context, 'Please select a transmission line.',
            isError: true);
        return;
      }
      if (_currentPosition == null) {
        SnackBarUtils.showSnackBar(context, 'Waiting for GPS coordinates...',
            isError: true);
        _getCurrentLocation(); // Try to get location again if null
        return;
      }

      // Extract survey details to pass to CameraScreen.
      final String lineName = _selectedLine!.name;
      final int towerNumber = int.parse(_towerNumberController.text);
      final double latitude = _currentPosition!.latitude;
      final double longitude = _currentPosition!.longitude;

      // NEW: Perform the validation before navigating
      final isValid = await _validateSurveyEntry(
          lineName, towerNumber, latitude, longitude);

      if (!isValid) {
        return; // Stop if validation fails (SnackBar is already shown by _validateSurveyEntry)
      }

      // Navigate to CameraScreen and refresh progress when returning.
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
        // This callback is executed when returning from CameraScreen/PhotoReviewScreen.
        _loadSurveyProgress(); // Refresh survey progress
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section for displaying survey progress.
          Text(
            'Survey Progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _isLoadingLines
              ? const Center(
                  child:
                      CircularProgressIndicator()) // Show loader if lines are loading
              : _transmissionLines.isEmpty
                  ? const Center(
                      // Show message when no lines are available
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'No transmission lines found. Please add lines in the Firebase console.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap:
                          true, // Prevents ListView from taking infinite height
                      physics:
                          const NeverScrollableScrollPhysics(), // Disables ListView's own scrolling
                      itemCount: _transmissionLines.length,
                      itemBuilder: (context, index) {
                        final line = _transmissionLines[index];
                        final completedTowers = _surveyProgress[line.name] ?? 0;
                        final totalTowers = line.totalTowers;
                        final progress = totalTowers > 0
                            ? completedTowers / totalTowers
                            : 0.0; // Calculate progress percentage
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Line: ${line.name}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Towers Completed: $completedTowers / $totalTowers',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value:
                                      progress, // Current progress value (0.0 to 1.0)
                                  backgroundColor: Colors
                                      .grey[300], // Background color of the bar
                                  color: Colors
                                      .green, // Color of the progress filled part
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          const Divider(height: 32), // Separator

          // Section for new survey entry form.
          Text(
            'New Survey Entry',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey, // Assign the form key
            child: Column(
              children: [
                DropdownButtonFormField<TransmissionLine>(
                  value: _selectedLine,
                  decoration: const InputDecoration(
                    labelText: 'Transmission Line',
                    prefixIcon: Icon(Icons.line_axis),
                  ),
                  hint: const Text('Select a transmission line'),
                  items: _transmissionLines.map((line) {
                    return DropdownMenuItem(
                      value: line,
                      child: Text(line.name),
                    );
                  }).toList(),
                  onChanged: (line) {
                    setState(() {
                      _selectedLine = line; // Update selected line
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a line'; // Validation for dropdown
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _towerNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Tower Number',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number, // Numeric keyboard
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a tower number';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  color: Colors.blueGrey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.blueGrey.shade100),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current GPS Coordinates:',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.blueGrey[700],
                                  ),
                        ),
                        const SizedBox(height: 8),
                        _isFetchingLocation
                            ? const Row(
                                children: [
                                  CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blueAccent)),
                                  SizedBox(width: 10),
                                  Text('Fetching location...'),
                                ],
                              )
                            : Text(
                                // Display formatted latitude and longitude, or 'N/A'
                                'Lat: ${_currentPosition?.latitude.toStringAsFixed(6) ?? 'N/A'}\n'
                                'Lon: ${_currentPosition?.longitude.toStringAsFixed(6) ?? 'N/A'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                        // Button to retry location if it failed to fetch
                        if (_currentPosition == null && !_isFetchingLocation)
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 20),
                            label: const Text('Retry Location'),
                            onPressed: _getCurrentLocation,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed:
                      _navigateToCameraScreen, // Trigger camera navigation
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Click Photo'),
                  style: ElevatedButton.styleFrom(
                    minimumSize:
                        const Size(double.infinity, 50), // Full width button
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
