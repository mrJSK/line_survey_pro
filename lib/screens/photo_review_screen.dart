// lib/screens/photo_review_screen.dart
// Displays the captured photo (without overlay), and handles saving/retaking.
// Adapted for local-only storage, without image manipulation.

import 'dart:io'; // For File operations
import 'package:flutter/material.dart'; // Flutter UI toolkit
// Removed: import 'package:image/image.dart' as img; // 'image' package no longer used
// Removed: import 'package:line_survey_pro/services/image_processing_service.dart'; // Service no longer used
import 'package:line_survey_pro/services/file_service.dart'; // Service for file operations
import 'package:line_survey_pro/services/local_database_service.dart'; // Local database service
import 'package:line_survey_pro/models/survey_record.dart'; // SurveyRecord data model
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Snackbar utility
// Removed: import 'package:intl/intl.dart'; // No longer needed for timestamp on image

class PhotoReviewScreen extends StatefulWidget {
  final String imagePath; // Path to the temporarily captured image
  final String lineName;
  final int towerNumber;
  final double latitude;
  final double longitude;

  const PhotoReviewScreen({
    super.key,
    required this.imagePath,
    required this.lineName,
    required this.towerNumber,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<PhotoReviewScreen> createState() => _PhotoReviewScreenState();
}

class _PhotoReviewScreenState extends State<PhotoReviewScreen> {
  // `_displayImageFile` can now directly be the `widget.imagePath`
  late File _capturedImageFile; // The captured image file to be displayed
  // Removed: bool _isProcessing = true; // No longer processing image
  bool _isSaving = false; // State for saving record

  @override
  void initState() {
    super.initState();
    _capturedImageFile =
        File(widget.imagePath); // Directly assign the captured image
    // Removed: _processImage(); // No longer processing image
  }

  // Removed: _processImage() method

  // Saves the captured photo locally.
  Future<void> _savePhotoAndRecord() async {
    setState(() {
      _isSaving = true; // Show saving indicator
    });

    try {
      // Ensure the image file exists.
      if (!_capturedImageFile.existsSync()) {
        throw Exception('Captured image file does not exist.');
      }

      // Save the captured image to a permanent location within the app's directory.
      final fileService = FileService();
      final permanentImagePath = await fileService.saveImageToAppDirectory(
          _capturedImageFile.path, 'survey_photos');

      // Create a new SurveyRecord object.
      final newRecord = SurveyRecord(
        id: DateTime.now()
            .millisecondsSinceEpoch
            .toString(), // Unique ID for local storage
        lineName: widget.lineName,
        towerNumber: widget.towerNumber,
        latitude: widget.latitude,
        longitude: widget.longitude,
        timestamp: DateTime.now(),
        photoPath: permanentImagePath,
        status: 'saved', // Status set to 'saved' (no cloud sync)
      );

      // Save the new record to the local SQLite database.
      await LocalDatabaseService().saveSurveyRecord(newRecord);

      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Photo and record saved locally!');
        // Pop PhotoReviewScreen then CameraScreen to return to Dashboard.
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle any errors during the saving process.
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error saving photo and record: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false; // Hide saving indicator
        });
      }
    }
  }

  // Discards the current photo and returns to the CameraScreen to retake.
  void _retakePhoto() {
    Navigator.of(context)
        .pop(); // Pops PhotoReviewScreen, returning to CameraScreen
  }

  // Discards the current photo and survey details, returning to the Dashboard.
  void _goBack() {
    Navigator.of(context).pop(); // Pops PhotoReviewScreen
    Navigator.of(context).pop(); // Pops CameraScreen, returning to DashboardTab
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Photo')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              // Directly display the captured image file
              child: Image.file(_capturedImageFile),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isSaving ? null : _retakePhoto, // Disable if saving
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange), // Orange for retake
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : _savePhotoAndRecord, // Disable if saving
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                // Loader for saving
                                color: Colors.white,
                                strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green), // Green for save
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _goBack, // Disable if saving
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey), // Grey for back
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
