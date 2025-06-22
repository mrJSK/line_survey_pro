// lib/screens/photo_review_screen.dart
// Displays the captured photo (without overlay), and handles saving/retaking.
// Adapted for local-only storage, without image manipulation.

import 'dart:io'; // For File operations
import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:line_survey_pro/services/file_service.dart'; // Service for file operations
import 'package:line_survey_pro/services/local_database_service.dart'; // Local database service
import 'package:line_survey_pro/models/survey_record.dart'; // SurveyRecord data model
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Snackbar utility
import 'package:line_survey_pro/l10n/app_localizations.dart'; // Import AppLocalizations

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
    final localizations = AppLocalizations.of(context)!;

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
        SnackBarUtils.showSnackBar(context, localizations.photoSavedLocally);
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(context,
            localizations.errorSavingPhotoAndRecordLocally(e.toString()),
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
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.reviewPhoto)),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Card(
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Image.file(
                    _capturedImageFile,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _retakePhoto,
                    icon: const Icon(Icons.refresh),
                    label: Text(localizations.retake),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(
                          color: colorScheme.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
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
                    label: Text(_isSaving
                        ? localizations.saving
                        : localizations.save), // Assuming 'saving' string
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isSaving ? null : _goBack,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(localizations.back),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface.withOpacity(0.7),
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
