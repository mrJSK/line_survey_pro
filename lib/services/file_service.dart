// lib/services/file_service.dart
// Manages file system operations: saving images to persistent storage,
// generating CSV files, and facilitating file sharing.

import 'dart:io'; // Provides File and Directory classes for file system interactions
import 'dart:typed_data'; // Required for Uint8List
// import 'dart:ui' as ui; // No longer needed directly by image package
import 'package:flutter/services.dart'; // For ByteData (Uint8List)
import 'package:path_provider/path_provider.dart'; // Plugin to get common file system locations (e.g., app documents directory)
import 'package:path/path.dart'
    as p; // Utility for manipulating file paths in a cross-platform way
import 'package:csv/csv.dart'; // Package for converting List<List<dynamic>> to CSV string
import 'package:share_plus/share_plus.dart'; // Plugin for sharing files and content to other apps
import 'package:line_survey_pro/models/survey_record.dart'; // Data model for SurveyRecord
import 'package:image/image.dart'
    as img; // Import the image package for image processing

class FileService {
  // Returns a temporary file path for a given filename.
  // This is useful for storing intermediate files that do not need to persist long-term.
  Future<String> getTemporaryImagePath(String filename) async {
    final tempDir =
        await getTemporaryDirectory(); // Get the system's temporary directory
    return p.join(tempDir.path,
        filename); // Construct the full path by joining directory and filename
  }

  // Saves an image from a temporary path to a permanent, app-specific directory.
  // Images are organized into specified subfolders (e.g., 'survey_photos').
  Future<String> saveImageToAppDirectory(
      String tempImagePath, String subfolder) async {
    // Get the application's documents directory. This is a persistent location
    // accessible only by this app, suitable for user data.
    final directory = await getApplicationDocumentsDirectory();
    // Construct the full path to the desired subfolder within the app's documents directory.
    final String appDir = p.join(directory.path, subfolder);

    // Check if the target subfolder exists. If not, create it and any necessary parent directories.
    if (!await Directory(appDir).exists()) {
      await Directory(appDir).create(recursive: true);
    }

    // Extract just the filename from the temporary image path.
    final String filename = p.basename(tempImagePath);
    // Construct the full permanent path for the image.
    final String permanentPath = p.join(appDir, filename);

    // Create a File object from the temporary path.
    final File tempFile = File(tempImagePath);
    // Copy the file from the temporary location to the permanent location.
    // This creates a new file at the permanent path.
    await tempFile.copy(permanentPath);
    return permanentPath; // Return the path where the image is now permanently saved.
  }

  // Generates a CSV file from a list of SurveyRecord objects.
  // The CSV includes a header row followed by data for each record.
  // The 'photoPath' column is explicitly excluded from the CSV export.
  Future<File?> generateCsvFile(List<SurveyRecord> records) async {
    if (records.isEmpty) {
      return null; // If no records are provided, return null as there's nothing to export.
    }

    List<List<dynamic>> csvData = [];

    // Add the header row to the CSV data, EXCLUDING 'Photo Path'.
    csvData.add([
      'Record ID',
      'Line Name',
      'Tower Number',
      'Latitude',
      'Longitude',
      'Timestamp',
      'Status',
    ]);

    // Iterate through each survey record and convert its properties into a list
    // suitable for a CSV row, EXCLUDING 'photoPath'.
    for (var record in records) {
      csvData.add([
        record.id,
        record.lineName,
        record.towerNumber,
        record.latitude,
        record.longitude,
        record.timestamp
            .toIso8601String(), // Convert DateTime to ISO 8601 string for consistent formatting
        record.status,
      ]);
    }

    // Convert the List<List<dynamic>> into a single CSV formatted string.
    String csvString = const ListToCsvConverter().convert(csvData);

    // Get a temporary directory to save the generated CSV file.
    final String directory = (await getTemporaryDirectory()).path;
    // Create a unique filename for the CSV using the current timestamp,
    // replacing colons for valid file naming.
    final String path = p.join(directory,
        'survey_data_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv');
    final File file = File(path); // Create a File object for the CSV.
    await file
        .writeAsString(csvString); // Write the CSV string content to the file.
    return file; // Return the created CSV file object.
  }

  // NEW/REVIVED: Adds a semi-transparent overlay with survey details to an image.
  // Returns the File object of the modified image saved in a temporary directory.
  Future<File?> addTextOverlayToImage(SurveyRecord record) async {
    try {
      final originalFile = File(record.photoPath);
      if (!await originalFile.exists()) {
        print('Original image file not found for overlay: ${record.photoPath}');
        return null;
      }

      // Read image from file
      List<int> imageBytes = await originalFile.readAsBytes();
      img.Image? originalImage =
          img.decodeImage(Uint8List.fromList(imageBytes));

      if (originalImage == null) {
        print('Failed to decode image for overlay: ${record.photoPath}');
        return null;
      }

      // Determine font size and padding dynamically based on image width
      // These values are approximations to get a readable size.
      final int baseFontSize = (originalImage.width / 25)
          .round()
          .clamp(10, 48); // Clamped to a reasonable range
      final int smallFontSize = (originalImage.width / 40)
          .round()
          .clamp(8, 36); // Smaller font for Lat/Lon/Time/Status
      final int padding = (originalImage.width / 50)
          .round()
          .clamp(5, 20); // Clamped to a reasonable range

      // Text to overlay
      final String lineText = 'Line: ${record.lineName}';
      final String towerText = 'Tower: ${record.towerNumber}';
      final String latLonText =
          'Lat: ${record.latitude.toStringAsFixed(6)}, Lon: ${record.longitude.toStringAsFixed(6)}';
      final String timeText =
          'Time: ${record.timestamp.toLocal().toString().split('.')[0]}';
      final String statusText =
          'Status: ${record.status.toUpperCase()}'; // Include status

      // Select a font based on the calculated fontSize. The image package has fixed-size bitmap fonts.
      img.BitmapFont? baseFont;
      if (baseFontSize >= 24) {
        baseFont = img.arial24;
      } else if (baseFontSize >= 14) {
        baseFont = img.arial24;
      } else {
        baseFont = img.arial24; // Fallback to smallest available font
      }

      img.BitmapFont? smallFont;
      if (smallFontSize >= 14) {
        smallFont = img.arial24;
      } else {
        smallFont = img.arial24; // Fallback to smallest available font
      }

      if (baseFont == null || smallFont == null) {
        print(
            "Warning: No suitable font found for overlay. Text might not render.");
        return null;
      }

      // Estimate line heights using the font's own height property
      final int baseLineHeight = baseFont.lineHeight;
      final int smallLineHeight = smallFont.lineHeight;

      // Calculate approximate text widths for centering or positioning
      // Since BitmapFont does not have a 'width' property, estimate average character width.
      double getFontCharWidth(img.BitmapFont font) {
        if (font == img.arial24) return 14.0;
        if (font == img.arial24) return 8.0;
        if (font == img.arial24) return 5.0;
        return 8.0; // Default fallback
      }

      final int lineTextEstimatedWidth =
          (lineText.length * getFontCharWidth(baseFont)).toInt();
      final int towerTextEstimatedWidth =
          (towerText.length * getFontCharWidth(smallFont)).toInt();
      final int latLonTextEstimatedWidth =
          (latLonText.length * getFontCharWidth(smallFont)).toInt();
      final int timeTextEstimatedWidth =
          (timeText.length * getFontCharWidth(smallFont)).toInt();
      final int statusTextEstimatedWidth =
          (statusText.length * getFontCharWidth(smallFont)).toInt();

      // Calculate background height (enough for 5 lines of text + padding)
      int backgroundHeight = (baseLineHeight + padding) +
          (smallLineHeight + padding) + // Tower line
          (smallLineHeight + padding) + // LatLon line
          (smallLineHeight + padding) + // Time line
          (smallLineHeight + padding); // Status line

      // Ensure background rectangle doesn't exceed image height
      if (backgroundHeight > originalImage.height) {
        backgroundHeight = originalImage.height;
      }

      // Create a new image for drawing (a copy of the original)
      img.Image outputImage = img.copyResize(originalImage,
          width: originalImage.width, height: originalImage.height);

      // Draw semi-transparent rectangle at the bottom
      img.drawRect(
        outputImage,
        x1: 0,
        y1: outputImage.height - backgroundHeight,
        x2: outputImage.width,
        y2: outputImage.height,
        color: img.ColorRgba8(0, 0, 0,
            0), // Semi-transparent black (increased opacity slightly to 180)
        thickness: -1, // Fill the rectangle
      );

      // Current Y position for drawing text, starting from the top of the background rectangle
      int currentY = (outputImage.height - backgroundHeight) + padding;

      // --- Draw text with formatting attempts ---

      // Line Name: Center aligned
      int lineTextX = (outputImage.width - lineTextEstimatedWidth) ~/ 2;
      lineTextX = lineTextX.clamp(
          padding, outputImage.width - padding - lineTextEstimatedWidth);
      img.drawString(
        outputImage,
        lineText,
        font: baseFont,
        x: lineTextX,
        y: currentY,
        color: img.ColorRgb8(255, 255, 255), // White text
      );
      currentY += baseLineHeight + padding;

      // Tower Number: Left aligned
      img.drawString(
        outputImage,
        towerText,
        font: smallFont,
        x: padding,
        y: currentY,
        color: img.ColorRgb8(255, 255, 255),
      );
      currentY += smallLineHeight + 2; // Small spacing

      // Lat and Lon: Left aligned (can adjust 'x' for right alignment if font metrics allow)
      img.drawString(
        outputImage,
        latLonText,
        font: smallFont,
        x: padding, // Left aligned
        y: currentY,
        color: img.ColorRgb8(255, 255, 255),
      );
      currentY += smallLineHeight + padding;

      // Time: Left aligned
      img.drawString(
        outputImage,
        timeText,
        font: smallFont,
        x: padding,
        y: currentY,
        color: img.ColorRgb8(255, 255, 255),
      );
      currentY += smallLineHeight + 2; // Small spacing

      // Status: Left aligned, with green color for 'uploaded'
      final img.Color statusColor = record.status.toUpperCase() == 'UPLOADED'
          ? img.ColorRgb8(0, 255, 0) // Green for UPLOADED
          : img.ColorRgb8(
              255, 255, 255); // White for other statuses (saved, etc.)
      img.drawString(
        outputImage,
        statusText,
        font: smallFont,
        x: padding,
        y: currentY,
        color: statusColor,
      );

      // Get temporary directory to save the modified image
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;
      final String outputFileName =
          'survey_photo_overlay_${p.basenameWithoutExtension(record.id)}.jpg'; // Use record ID for unique filename
      final File outputFile = File('$tempPath/$outputFileName');

      // Encode and save the new image as JPEG
      await outputFile.writeAsBytes(img.encodeJpg(outputImage, quality: 90));

      return outputFile;
    } catch (e) {
      print('Error adding text overlay to image: $e');
      return null;
    }
  }

  // Shares a list of files using the platform's native sharing mechanism.
  Future<void> shareFiles(List<String> filePaths, {String? text}) async {
    final List<XFile> files = filePaths.map((path) => XFile(path)).toList();
    await Share.shareXFiles(files, text: text);
  }
}
