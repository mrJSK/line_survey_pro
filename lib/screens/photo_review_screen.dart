// lib/screens/photo_review_screen.dart
// Displays the captured photo (without overlay), and handles saving/retaking.
// Adapted for local-only storage, without image manipulation.

import 'dart:io'; // For File operations
import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:line_survey_pro/services/file_service.dart'; // Service for file operations
import 'package:line_survey_pro/services/local_database_service.dart'; // Local database service
import 'package:line_survey_pro/models/survey_record.dart'; // SurveyRecord data model
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Snackbar utility

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
  late File _capturedImageFile;
  bool _isSaving = false; // State for saving record

  @override
  void initState() {
    super.initState();
    _capturedImageFile = File(widget.imagePath);
  }

  Future<void> _savePhotoAndRecord() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (!_capturedImageFile.existsSync()) {
        throw Exception('Captured image file does not exist.');
      }

      final fileService = FileService();
      final permanentImagePath = await fileService.saveImageToAppDirectory(
          _capturedImageFile.path, 'survey_photos');

      final newRecord = SurveyRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        lineName: widget.lineName,
        towerNumber: widget.towerNumber,
        latitude: widget.latitude,
        longitude: widget.longitude,
        timestamp: DateTime.now(),
        photoPath: permanentImagePath,
        status: 'saved',
      );

      await LocalDatabaseService().saveSurveyRecord(newRecord);

      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Photo and record saved locally!');
        Navigator.of(context).pop(); // Pops PhotoReviewScreen
        Navigator.of(context).pop(); // Pops CameraScreen
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error saving photo and record: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _retakePhoto() {
    Navigator.of(context).pop();
  }

  void _goBack() {
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Photo')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0), // Consistent padding
              child: Card(
                // Wrap image in a card for better visual
                elevation: 4,
                clipBehavior: Clip.antiAlias, // Clip image to card shape
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Image.file(
                    _capturedImageFile,
                    fit: BoxFit.contain, // Ensure image fits
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.all(20.0), // Increased padding for buttons
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Retake Button: Changed to OutlinedButton for secondary action
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _retakePhoto,
                    icon: const Icon(
                        Icons.refresh), // More generic refresh/retake icon
                    label: const Text('Retake'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          colorScheme.primary, // Primary color for text/icon
                      side: BorderSide(
                          color: colorScheme.primary
                              .withOpacity(0.5)), // Subtle border
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14), // Consistent padding
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Save Button: Remains prominent ElevatedButton
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _savePhotoAndRecord,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme
                          .primary, // Use primary color for main action
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Back Button: Changed to TextButton for least prominence
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isSaving ? null : _goBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface
                          .withOpacity(0.7), // Subtler color
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
