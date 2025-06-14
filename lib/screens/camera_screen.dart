// lib/screens/camera_screen.dart
// Displays a live camera preview and allows capturing photos.
// Passes captured image path and survey details to PhotoReviewScreen.
// Updated for consistent UI theming.

import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:camera/camera.dart'; // Camera package for camera access
import 'package:line_survey_pro/screens/photo_review_screen.dart'; // Photo review screen navigation
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Snackbar utility for user feedback
import 'package:line_survey_pro/services/permission_service.dart'; // Permission service for camera access

class CameraScreen extends StatefulWidget {
  final String
      lineName; // The name of the transmission line from the survey form
  final int towerNumber; // The tower number from the survey form
  final double latitude; // The GPS latitude coordinate
  final double longitude; // The GPS longitude coordinate

  const CameraScreen({
    super.key,
    required this.lineName,
    required this.towerNumber,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

// WidgetsBindingObserver is used to listen to app lifecycle changes (e.g., app in background/foreground)
// This is important for properly managing camera resources.
class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController?
      _controller; // Controller for camera operations (e.g., initialize, takePicture)
  List<CameraDescription>?
      _cameras; // List of available cameras on the device (front, rear, etc.)
  bool _isCameraInitialized =
      false; // State to track whether the camera controller is ready
  bool _isTakingPicture =
      false; // State to prevent multiple picture captures while one is in progress

  @override
  void initState() {
    super.initState();
    // Add this state as an observer for app lifecycle events.
    // This allows us to pause/resume the camera when the app goes into the background/foreground.
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera(); // Initialize the camera as soon as the screen loads
  }

  // Initializes the camera: requests permission, finds available cameras, and sets up the controller.
  Future<void> _initializeCamera() async {
    // Request camera permission using our custom PermissionService.
    // If permission is denied, show a snackbar and navigate back.
    final hasPermission =
        await PermissionService().requestCameraPermission(context);
    if (!hasPermission) {
      if (mounted) {
        // Check if the widget is still in the widget tree before showing UI
        SnackBarUtils.showSnackBar(context, 'Camera permission denied.',
            isError: true);
        Navigator.of(context)
            .pop(); // Go back to the previous screen (Dashboard)
      }
      return;
    }

    try {
      // Get the list of available cameras on the device.
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'No cameras found on device.',
              isError: true);
          Navigator.of(context).pop();
        }
        return;
      }

      // Prefer the rear camera if available. If not, default to the first camera found.
      CameraDescription? rearCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first, // Fallback to the first available camera
      );

      // Initialize CameraController with the selected camera and a high resolution preset.
      // `enableAudio: false` is set because we don't need audio for survey photos.
      _controller = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      // Initialize the camera controller. This prepares the camera for use.
      await _controller!.initialize();
      if (mounted) {
        // Update the UI to show the camera preview once initialized.
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } on CameraException catch (e) {
      // Handle specific camera-related exceptions (e.g., camera not available, permission issues).
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error initializing camera: ${e.code}\n${e.description}',
            isError: true);
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Catch any other unexpected errors during initialization.
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'An unexpected error occurred: $e',
            isError: true);
        Navigator.of(context).pop();
      }
    }
  }

  // Captures a photo and navigates to the PhotoReviewScreen with the captured image path
  // and all relevant survey details.
  Future<void> _takePicture() async {
    // Prevent taking a picture if the camera is not initialized or if a picture
    // is already being taken (to avoid multiple rapid captures).
    if (!_isCameraInitialized || _controller == null || _isTakingPicture) {
      return;
    }

    setState(() {
      _isTakingPicture =
          true; // Set state to indicate picture capture is in progress
    });

    try {
      // Use the camera controller to take a picture. This returns an XFile object.
      final XFile file = await _controller!.takePicture();
      if (mounted) {
        // Navigate to PhotoReviewScreen, passing the image path and survey details.
        // `.then((_) { ... })` ensures that code inside this block runs when
        // PhotoReviewScreen is popped (when the user returns from it).
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (context) => PhotoReviewScreen(
              imagePath: file.path,
              lineName: widget.lineName,
              towerNumber: widget.towerNumber,
              latitude: widget.latitude,
              longitude: widget.longitude,
            ),
          ),
        )
            .then((_) {
          // When returning from PhotoReviewScreen (after saving or retaking),
          // ensure `_isTakingPicture` is reset and resume camera preview.
          if (mounted) {
            setState(() {
              _isTakingPicture = false;
            });
          }
          _controller?.resumePreview(); // Resume the camera's live preview
        });
      }
    } on CameraException catch (e) {
      // Handle errors specific to taking a picture.
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error taking picture: ${e.code}\n${e.description}',
            isError: true);
      }
    } finally {
      if (mounted) {
        // Ensure the loading state is reset even if an error occurs.
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // This method is called when the app's lifecycle state changes.
    // If the controller is not initialized, there's nothing to do.
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // When the app goes into the background, dispose the camera controller
      // to release camera resources and prevent conflicts with other apps.
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // When the app comes back to the foreground, reinitialize the camera
      // to resume the preview and enable picture taking.
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    // Remove the app lifecycle observer when the widget is disposed to prevent memory leaks.
    WidgetsBinding.instance.removeObserver(this);
    _controller
        ?.dispose(); // Dispose the camera controller to free up resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Survey Photo'),
        // AppBar style is inherited from main.dart ThemeData
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                // Display the live camera preview across the entire screen.
                Positioned.fill(
                  child: CameraPreview(_controller!),
                ),
                // Floating action button positioned at the bottom center to trigger photo capture.
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FloatingActionButton(
                      onPressed: _isTakingPicture
                          ? null
                          : _takePicture, // Disable button if currently taking picture
                      // Use theme's primary color for background, or a specific accent
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30.0), // Fully rounded
                      ),
                      elevation: 8, // More pronounced shadow
                      child: _isTakingPicture
                          ? const SizedBox(
                              width: 28, // Slightly larger loader
                              height: 28,
                              child: CircularProgressIndicator(
                                // Show a loading indicator during capture
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3, // Thicker stroke
                              ),
                            )
                          : const Icon(Icons.camera_alt,
                              size: 36), // Camera icon
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child:
                  CircularProgressIndicator()), // Show a loading spinner while camera initializes
    );
  }
}
