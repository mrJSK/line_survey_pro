// lib/screens/camera_screen.dart
// Handles camera access, photo capture, and saving images with GPS data.
// Now saves to local database only, with UI for retake/save/back.

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:geolocator/geolocator.dart'; // Ensure this is imported for Position
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:line_survey_pro/models/survey_record.dart';
import 'package:line_survey_pro/services/local_database_service.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
// REMOVED: import 'package:line_survey_pro/services/survey_firestore_service.dart';
import 'package:uuid/uuid.dart';

class CameraScreen extends StatefulWidget {
  final String lineName;
  final int towerNumber;
  final double latitude;
  final double longitude;
  final String? taskId;
  final String? userId;

  const CameraScreen({
    super.key,
    required this.lineName,
    required this.towerNumber,
    required this.latitude,
    required this.longitude,
    this.taskId,
    this.userId,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  XFile? _capturedImageFile; // To hold the captured image temporarily

  final LocalDatabaseService _localDatabaseService = LocalDatabaseService();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isCameraInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null && _cameras != null && _cameras!.isNotEmpty) {
        _initializeCameraController(_controller!.description);
      } else {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isDenied || cameraStatus.isRestricted) {
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Camera permission denied.',
            isError: true);
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'No cameras found.',
              isError: true);
          Navigator.of(context).pop();
        }
        return;
      }

      await _initializeCameraController(_cameras![0]);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Error initializing camera: $e',
            isError: true);
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _initializeCameraController(
      CameraDescription cameraDescription) async {
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller!.addListener(() {
      if (mounted) setState(() {});
      if (_controller!.value.hasError) {
        print('Camera error: ${_controller!.value.errorDescription}');
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Camera error: ${_controller!.value.errorDescription}',
              isError: true);
        }
      }
    });

    try {
      await _controller!.initialize();
      if (!mounted) {
        return;
      }
      setState(() {
        _isCameraInitialized = true;
      });
    } on CameraException catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Camera initialization error: ${e.description}',
            isError: true);
        Navigator.of(context).pop();
      }
      print('CameraException: ${e.code} - ${e.description}');
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isCameraInitialized ||
        _controller == null ||
        _controller!.value.isTakingPicture) {
      return;
    }
    setState(() {
      _isCapturing = true;
    });
    try {
      _capturedImageFile = await _controller!.takePicture();
      setState(() {
        _isCapturing = false;
      });
    } on CameraException catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error capturing picture: ${e.description}',
            isError: true);
      }
      print('CameraException: ${e.code} - ${e.description}');
      setState(() {
        _isCapturing = false;
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'An unexpected error occurred during capture: $e',
            isError: true);
      }
      print('General Capture Error: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImageFile = null;
      _isCapturing = false;
      _controller?.resumePreview();
    });
  }

  Future<void> _savePhotoAndRecordLocally() async {
    // Renamed method
    if (_capturedImageFile == null) {
      SnackBarUtils.showSnackBar(context, 'No photo captured to save.',
          isError: true);
      return;
    }

    setState(() {
      _isCapturing = true; // Use this to show saving progress
    });

    try {
      // Define a permanent path for the image within the app's directory
      final String appDocsPath =
          (await getApplicationDocumentsDirectory()).path;
      final String subfolder = 'survey_photos';
      final String permanentImagePath =
          p.join(appDocsPath, subfolder, p.basename(_capturedImageFile!.path));

      // Ensure the subfolder exists
      await Directory(p.join(appDocsPath, subfolder)).create(recursive: true);

      // Copy the image from the temporary path to the permanent app-specific directory
      final File copiedFile =
          await File(_capturedImageFile!.path).copy(permanentImagePath);

      // Create a new SurveyRecord instance
      final String recordId = _uuid.v4(); // Generate a unique ID for the record
      final SurveyRecord newRecord = SurveyRecord(
        id: recordId,
        lineName: widget.lineName,
        towerNumber: widget.towerNumber,
        latitude: widget.latitude,
        longitude: widget.longitude,
        timestamp: DateTime.now(),
        photoPath: copiedFile.path, // Use the permanent local path
        status: 'saved', // Initial status: saved locally, not yet uploaded
        taskId: widget.taskId,
        userId: widget.userId,
      );

      // Save the record to the local database
      await _localDatabaseService.saveSurveyRecord(newRecord);

      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Photo saved locally!',
            isError: false);
        Navigator.of(context).pop(newRecord
            .id); // Pop CameraScreen and return the ID of the new survey record
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error saving photo and record locally: $e',
            isError: true);
      }
      print('Local Save Error: $e');
    } finally {
      setState(() {
        _isCapturing = false; // Reset capturing indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Take Photo')),
      body: Stack(
        children: [
          Positioned.fill(
            child: _capturedImageFile == null
                ? CameraPreview(_controller!) // Show live camera preview
                : Image.file(File(_capturedImageFile!.path),
                    fit: BoxFit.cover), // Show captured image
          ),
          // Control buttons (Capture / Retake & Save)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_capturedImageFile ==
                    null) // Show capture button if no image captured
                  FloatingActionButton(
                    heroTag: 'capture',
                    onPressed: _isCapturing ? null : _capturePhoto,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: _isCapturing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.camera_alt),
                  ),
                if (_capturedImageFile !=
                    null) // Show Retake and Save buttons if image captured
                  Row(
                    children: [
                      FloatingActionButton(
                        heroTag: 'retake',
                        onPressed: _retakePhoto,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.refresh),
                      ),
                      const SizedBox(width: 20),
                      FloatingActionButton(
                        heroTag: 'save',
                        onPressed: _isCapturing
                            ? null
                            : _savePhotoAndRecordLocally, // Call local save
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: _isCapturing
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Icon(Icons.save),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Back Button (Top Left)
          Positioned(
            top: 10,
            left: 10,
            child: FloatingActionButton.small(
              heroTag: 'back',
              onPressed: () {
                Navigator.of(context).pop(); // Simply pop the screen
              },
              backgroundColor: Colors.black54,
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          // Display current GPS coordinates (optional overlay for context)
          Positioned(
            top: 10,
            right:
                10, // Adjusted to right for better placement with back button
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Line: ${widget.lineName}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    'Tower: ${widget.towerNumber}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    'Lat: ${widget.latitude.toStringAsFixed(6)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'Lon: ${widget.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
