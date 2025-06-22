// lib/screens/camera_screen.dart
// Handles camera access, photo capture, and saving images with GPS data.
// Now saves to local database only, with UI for retake/save/back.

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// Ensure this is imported for Position
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:line_survey_pro/models/survey_record.dart'; // Import SurveyRecord model
import 'package:line_survey_pro/services/local_database_service.dart'; // Local database service
import 'package:line_survey_pro/utils/snackbar_utils.dart';
// Removed: import 'package:line_survey_pro/screens/patrolling_detail_screen.dart'; // No longer navigate to it, pop from it
import 'package:uuid/uuid.dart';

class CameraScreen extends StatefulWidget {
  final SurveyRecord
      initialRecordWithDetails; // NEW: Receives full record (without photoPath)

  const CameraScreen({
    super.key,
    required this.initialRecordWithDetails, // Required now
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
  bool _isSaving = false;
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
      print('DEBUG: Camera not ready or already capturing.');
      return;
    }
    setState(() {
      _isCapturing = true;
      print('DEBUG: Setting _isCapturing to true (capture).');
    });
    try {
      _capturedImageFile = await _controller!.takePicture();
      setState(() {
        _isCapturing = false;
        print(
            'DEBUG: Photo captured. Setting _isCapturing to false (capture).');
      });
    } on CameraException catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error capturing picture: ${e.description}',
            isError: true);
      }
      print(
          'DEBUG: CameraException during capture: ${e.code} - ${e.description}');
      setState(() {
        _isCapturing = false;
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'An unexpected error occurred during capture: $e',
            isError: true);
      }
      print('DEBUG: General Capture Error: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImageFile = null; // Clear captured image
      _isSaving = false; // Reset saving state too
      _isCapturing = false; // Reset capture state
      _controller?.resumePreview(); // Resume camera preview
    });
    print('DEBUG: Retaking photo.');
  }

  // Saves the captured photo and updates the existing record with the photo path.
  // Then pops back to PatrollingDetailScreen.
  Future<void> _savePhotoAndRecordLocally() async {
    if (_capturedImageFile == null) {
      print('DEBUG: _capturedImageFile is null, cannot save.');
      SnackBarUtils.showSnackBar(context, 'No photo captured to save.',
          isError: true);
      return;
    }

    setState(() {
      _isSaving = true; // Show saving progress indicator on save button
      print('DEBUG: Setting _isSaving to true.');
    });

    try {
      // Define a permanent path for the image within the app's directory
      final String appDocsPath =
          (await getApplicationDocumentsDirectory()).path;
      const String subfolder = 'survey_photos';
      final String permanentImagePath =
          p.join(appDocsPath, subfolder, p.basename(_capturedImageFile!.path));

      // Ensure the subfolder exists
      await Directory(p.join(appDocsPath, subfolder)).create(recursive: true);

      // Copy the image from the temporary path to the permanent app-specific directory
      final File copiedFile =
          await File(_capturedImageFile!.path).copy(permanentImagePath);
      print('DEBUG: Photo copied to permanent path: ${copiedFile.path}');

      // Update the *existing* SurveyRecord with the photoPath and 'saved_complete' status
      final updatedRecord = widget.initialRecordWithDetails.copyWith(
        photoPath: copiedFile.path, // Add the photoPath
        status: 'saved_complete', // Status: photo taken, details entered
      );

      // Save the updated record back to the local database (this will replace the old record)
      await _localDatabaseService.saveSurveyRecord(updatedRecord);
      print(
          'DEBUG: Survey record updated in local DB with photo. Record ID: ${updatedRecord.id}');

      if (mounted) {
        print(
            'DEBUG: Widget is mounted. Attempting navigation back to PatrollingDetailScreen.');
        SnackBarUtils.showSnackBar(context, 'Photo saved locally!',
            isError: false);
        // Pop back to PatrollingDetailScreen, passing the updated record's ID to indicate success
        Navigator.of(context).pop(updatedRecord.id);
        print('DEBUG: Navigation back to PatrollingDetailScreen triggered.');
      } else {
        print(
            'DEBUG: Widget is NOT mounted after local save. Cannot navigate back.');
      }
    } on Exception catch (e) {
      // Catch more general Exception
      print('DEBUG ERROR: Exception during local save/navigation: $e');
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error saving photo and record locally: ${e.toString()}',
            isError: true);
      }
      print('Local Save Error: $e');
    } finally {
      setState(() {
        _isSaving = false; // Reset saving indicator
        print('DEBUG: Setting _isSaving to false.');
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
                ? CameraPreview(_controller!)
                : Image.file(File(_capturedImageFile!.path), fit: BoxFit.cover),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_capturedImageFile == null)
                  FloatingActionButton(
                    heroTag: 'capture',
                    onPressed: _isCapturing ? null : _capturePhoto,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: _isCapturing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.camera_alt),
                  ),
                if (_capturedImageFile != null)
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
                        onPressed:
                            _isSaving ? null : _savePhotoAndRecordLocally,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Icon(Icons.save),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: FloatingActionButton.small(
              heroTag: 'back',
              onPressed: () {
                Navigator.of(context).pop();
              },
              backgroundColor: Colors.black54,
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
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
                    'Line: ${widget.initialRecordWithDetails.lineName}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    'Tower: ${widget.initialRecordWithDetails.towerNumber}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    'Lat: ${widget.initialRecordWithDetails.latitude.toStringAsFixed(6)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'Lon: ${widget.initialRecordWithDetails.longitude.toStringAsFixed(6)}',
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
