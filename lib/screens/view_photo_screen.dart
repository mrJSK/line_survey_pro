// lib/screens/view_photo_screen.dart
// A simple screen dedicated to displaying a single full-screen image.
// It uses InteractiveViewer to enable zooming and panning capabilities.

import 'dart:io'; // Required for working with File objects (to load image from path)
import 'package:flutter/material.dart'; // Core Flutter UI toolkit

class ViewPhotoScreen extends StatelessWidget {
  final String
      imagePath; // The local file path to the image that needs to be displayed

  // Constructor for the ViewPhotoScreen. The imagePath is a required parameter.
  const ViewPhotoScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Photo'), // Title displayed in the AppBar
      ),
      body: Center(
        // The Center widget ensures its child (the image or error message) is centered on the screen.
        child: imagePath.isNotEmpty && File(imagePath).existsSync()
            ? InteractiveViewer(
                // InteractiveViewer allows its child to be scaled (zoomed) and dragged (panned).
                panEnabled:
                    true, // Set to true to allow dragging the image around when zoomed
                minScale:
                    0.5, // Minimum zoom level (0.5 means half the original size)
                maxScale:
                    4.0, // Maximum zoom level (4.0 means four times the original size)
                child: Image.file(
                  File(
                      imagePath), // Loads the image from the provided local file path
                  fit: BoxFit
                      .contain, // Ensures the entire image is visible, fitting within the bounds
                  // without cropping, while maintaining its aspect ratio.
                ),
              )
            : Column(
                // If the imagePath is empty or the file does not exist, display an error message.
                mainAxisAlignment: MainAxisAlignment
                    .center, // Centers content vertically in the column
                children: [
                  // An icon indicating a broken or missing image
                  Icon(Icons.broken_image, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16), // Vertical spacing
                  // Text message indicating the image could not be found
                  Text(
                    'Image not found or corrupted.',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium, // Applies a predefined text style
                  ),
                ],
              ),
      ),
    );
  }
}
