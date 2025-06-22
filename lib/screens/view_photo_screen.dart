// lib/screens/view_photo_screen.dart
// A simple screen dedicated to displaying a single full-screen image.
// It uses InteractiveViewer to enable zooming and panning capabilities.
// Updated for consistent UI theming.

import 'dart:io'; // Required for working with File objects (to load image from path)
import 'package:flutter/material.dart'; // Core Flutter UI toolkit
import 'package:line_survey_pro/l10n/app_localizations.dart';

class ViewPhotoScreen extends StatelessWidget {
  final String
      imagePath; // The local file path to the image that needs to be displayed

  // Constructor for the ViewPhotoScreen. The imagePath is a required parameter.
  const ViewPhotoScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.viewPhoto),
      ),
      body: Center(
        child: imagePath.isNotEmpty && File(imagePath).existsSync()
            ? InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: imagePath,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    localizations.imageNotFound,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
      ),
    );
  }
}
