// lib/services/file_service.dart
// Manages file system operations: saving images to persistent storage,
// generating CSV files, and facilitating file sharing.

import 'dart:io'; // Provides File and Directory classes for file system interactions
// Alias 'dart:ui' to 'ui' for image operations
import 'package:flutter/services.dart'; // For ByteData
import 'package:path_provider/path_provider.dart'; // Plugin to get common file system locations (e.g., app documents directory)
import 'package:path/path.dart'
    as p; // Utility for manipulating file paths in a cross-platform way
import 'package:csv/csv.dart'; // Package for converting List<List<dynamic>> to CSV string
import 'package:share_plus/share_plus.dart'; // Plugin for sharing files and content to other apps
import 'package:line_survey_pro/models/survey_record.dart'; // Data model for SurveyRecord
import 'package:image/image.dart'
    as img; // Import the image package for image processing
import 'package:line_survey_pro/models/transmission_line.dart'; // NEW: Import TransmissionLine for Span calculation
import 'package:collection/collection.dart'; // For firstWhereOrNull

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
  // The CSV includes a header row followed by data for each record, now including patrolling details.
  Future<File?> generateCsvFile(List<SurveyRecord> records,
      {List<TransmissionLine>? allTransmissionLines}) async {
    // NEW: Added optional TransmissionLine list
    if (records.isEmpty) {
      return null; // If no records are provided, return null as there's nothing to export.
    }

    List<List<dynamic>> csvData = [];

    // Add the header row to the CSV data, including NEW Patrolling Details and Line Survey Details.
    csvData.add([
      'Record ID', 'Line Name', 'Tower Number', 'Span', // NEW: Span column
      'Latitude', 'Longitude', 'Timestamp', 'Status',
      'Missing Tower Parts', 'Soil Condition', 'Stub / Coping Leg', 'Earthing',
      'Condition of Tower Parts', 'Status of Insulator', 'Jumper Status',
      'Hot Spots',
      'Number Plate', 'Danger Board', 'Phase Plate', 'Nut and Bolt Condition',
      'Anti Climbing Device', 'Wild Growth', 'Bird Guard', 'Bird Nest',
      'Arching Horn', 'Corona Ring', 'Insulator Type', 'OPGW Joint Box',
      // NEW Line Survey Details
      'Building', 'Tree', 'Number of Trees', 'Condition of OPGW',
      'Condition of Earth Wire', 'Condition of Conductor', 'Mid Span Joint',
      'New Construction', 'Object on Conductor', 'Object on Earthwire',
      'Spacers', 'Vibration Damper', 'Road Crossing', 'River Crossing',
      'Electrical Line', 'Railway Crossing',
      'General Notes', // NEW: General Notes
    ]);

    // Iterate through each survey record and convert its properties into a list
    // suitable for a CSV row, including all details.
    for (var record in records) {
      String span = '';
      if (allTransmissionLines != null) {
        final line = allTransmissionLines
            .firstWhereOrNull((l) => l.name == record.lineName);
        if (line != null) {
          if (line.towerRangeEnd != null &&
              line.towerRangeEnd == record.towerNumber) {
            span = 'END';
          } else {
            span = '${record.towerNumber}-${record.towerNumber + 1}';
          }
        }
      }

      csvData.add([
        record.id,
        record.lineName,
        record.towerNumber,
        span, // Add calculated span
        record.latitude,
        record.longitude,
        record.timestamp
            .toIso8601String(), // Convert DateTime to ISO 8601 string
        record.status,
        record.missingTowerParts ?? '', // Use empty string if null
        record.soilCondition ?? '',
        record.stubCopingLeg ?? '',
        record.earthing ?? '',
        record.conditionOfTowerParts ?? '',
        record.statusOfInsulator ?? '',
        record.jumperStatus ?? '',
        record.hotSpots ?? '',
        record.numberPlate ?? '',
        record.dangerBoard ?? '',
        record.phasePlate ?? '',
        record.nutAndBoltCondition ?? '',
        record.antiClimbingDevice ?? '',
        record.wildGrowth ?? '',
        record.birdGuard ?? '',
        record.birdNest ?? '',
        record.archingHorn ?? '',
        record.coronaRing ?? '',
        record.insulatorType ?? '',
        record.opgwJointBox ?? '',
        // NEW Line Survey Details
        record.building == true ? 'Yes' : 'No',
        record.tree == true ? 'Yes' : 'No',
        record.numberOfTrees ?? '',
        record.conditionOfOpgw ?? '',
        record.conditionOfEarthWire ?? '',
        record.conditionOfConductor ?? '',
        record.midSpanJoint ?? '',
        record.newConstruction == true ? 'Yes' : 'No',
        record.objectOnConductor == true ? 'Yes' : 'No',
        record.objectOnEarthwire == true ? 'Yes' : 'No',
        record.spacers ?? '',
        record.vibrationDamper ?? '',
        record.roadCrossing ?? '',
        record.riverCrossing == true ? 'Yes' : 'No',
        record.electricalLine ?? '',
        record.railwayCrossing == true ? 'Yes' : 'No',
        record.generalNotes ?? '', // Add General Notes
      ]);
    }

    // Convert the List<List<dynamic>> into a single CSV formatted string.
    String csvString = const ListToCsvConverter().convert(csvData);

    // Get a temporary directory to save the generated CSV file.
    final String directory = (await getTemporaryDirectory()).path;
    // Create a unique filename for the CSV using the current timestamp.
    final String path = p.join(directory,
        'survey_data_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv');
    final File file = File(path); // Create a File object for the CSV.
    await file
        .writeAsString(csvString); // Write the CSV string content to the file.
    return file; // Return the created CSV file object.
  }

  // Adds a semi-transparent overlay with survey details to an image.
  // Returns the File object of the modified image saved in a temporary directory.
  Future<File?> addTextOverlayToImage(SurveyRecord record) async {
    try {
      final originalFile = File(record.photoPath);
      if (!await originalFile.exists()) {
        print('Original image file not found: ${record.photoPath}');
        return null;
      }

      // Read image from file
      List<int> imageBytes = await originalFile.readAsBytes();
      img.Image? originalImage =
          img.decodeImage(Uint8List.fromList(imageBytes));

      if (originalImage == null) {
        print('Failed to decode image: ${record.photoPath}');
        return null;
      }

      // Determine font size and padding dynamically based on image width
      // These divisors can be tuned for better appearance on different image resolutions
      final int fontSize = (originalImage.width / 30)
          .round()
          .clamp(12, 40); // Adjusted for more lines
      final int padding = (originalImage.width / 60)
          .round()
          .clamp(5, 15); // Adjusted for more lines

      // Text to overlay
      final String lineText = 'Line: ${record.lineName}';
      final String towerText = 'Tower: ${record.towerNumber}';
      final String latLonText =
          'Lat: ${record.latitude.toStringAsFixed(6)}, Lon: ${record.longitude.toStringAsFixed(6)}';
      final String timeText =
          'Time: ${record.timestamp.toLocal().toString().split('.')[0]}';
      final String statusText = 'Status: ${record.status.toUpperCase()}';

      final List<String> textLines = [
        lineText,
        towerText,
        latLonText,
        timeText,
        statusText,
      ];

      // Calculate approximate total text height to determine background rectangle size.
      // This is an approximation as actual text rendering size can vary.
      double textHeightPerLine =
          fontSize * 1.3; // Rough estimation for line height, adjusted
      double totalTextHeight = textLines.length * textHeightPerLine;
      double backgroundHeight = totalTextHeight + (padding * 2);

      // Ensure background rectangle doesn't exceed image height
      if (backgroundHeight > originalImage.height) {
        backgroundHeight = originalImage.height.toDouble();
      }

      // Create a new image for drawing (a copy of the original)
      img.Image outputImage = img.copyResize(originalImage,
          width: originalImage.width, height: originalImage.height);

      // Draw semi-transparent rectangle at the bottom
      // Using drawRect with thickness -1 to fill it. Rgba8 for transparency.
      img.drawRect(
        outputImage,
        x1: 0,
        y1: (outputImage.height - backgroundHeight).toInt(),
        x2: outputImage.width,
        y2: outputImage.height,
        color: img.ColorUint16.rgba(
            0, 0, 0, 255), // Semi-transparent black (150/255 opacity)
        thickness: 1, // Fill the rectangle
      );

      // Current Y position for drawing text, starting from the top of the background rectangle
      int currentY =
          (originalImage.height - backgroundHeight).toInt() + padding;

      // Use a default font from the `image` package.
      img.BitmapFont? font;
      if (fontSize >= 24) {
        font = img.arial24;
      } else if (fontSize >= 14) {
        font = img.arial14;
      } else {
        font = img.arial14; // Fallback to a smaller font
      }

      // Draw each text line
      for (String line in textLines) {
        img.drawString(
          outputImage,
          line,
          font: font,
          x: padding,
          y: currentY,
          color: img.ColorRgb8(255, 255, 255), // White text
        );
        currentY += textHeightPerLine.toInt();
      }

      // Get temporary directory to save the modified image
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;
      final String outputFileName =
          'survey_photo_overlay_${p.basenameWithoutExtension(record.photoPath)}.jpg';
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
  // This allows users to send files to other apps (e.g., email, cloud storage, messaging).
  Future<void> shareFiles(List<String> filePaths, {String? text}) async {
    // Convert a list of file paths (String) to a list of XFile objects,
    // which is the required input type for `share_plus`.
    final List<XFile> files = filePaths.map((path) => XFile(path)).toList();
    // Use the `share_plus` plugin to open the native share sheet.
    await Share.shareXFiles(files, text: text);
  }
}
