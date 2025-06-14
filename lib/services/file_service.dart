// lib/services/file_service.dart
// Manages file system operations: saving images to persistent storage,
// generating CSV files, and facilitating file sharing.

import 'dart:io'; // Provides File and Directory classes for file system interactions
import 'package:path_provider/path_provider.dart'; // Plugin to get common file system locations (e.g., app documents directory)
import 'package:path/path.dart'
    as p; // Utility for manipulating file paths in a cross-platform way
import 'package:csv/csv.dart'; // Package for converting List<List<dynamic>> to CSV string
import 'package:share_plus/share_plus.dart'; // Plugin for sharing files and content to other apps
import 'package:line_survey_pro/models/survey_record.dart'; // Data model for SurveyRecord

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
  Future<File?> generateCsvFile(List<SurveyRecord> records) async {
    if (records.isEmpty) {
      return null; // If no records are provided, return null as there's nothing to export.
    }

    List<List<dynamic>> csvData = [];

    // Add the header row to the CSV data.
    csvData.add([
      'Record ID',
      'Line Name',
      'Tower Number',
      'Latitude',
      'Longitude',
      'Timestamp',
      'Status', // Local status (e.g., 'saved')
    ]);

    // Iterate through each survey record and convert its properties into a list
    // suitable for a CSV row.
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
