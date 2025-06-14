// lib/services/permission_service.dart
// Manages requesting runtime permissions for camera, location, and storage
// using the `permission_handler` package.
// Provides user feedback via `SnackBarUtils`.

import 'package:flutter/material.dart'; // Required for BuildContext and SnackBarAction
import 'package:permission_handler/permission_handler.dart'; // The permission_handler package
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Custom utility for displaying Snackbars

class PermissionService {
  // Requests camera permission from the user.
  // Returns `true` if permission is granted, `false` otherwise.
  Future<bool> requestCameraPermission(BuildContext context) async {
    // Get the current status of the camera permission.
    var status = await Permission.camera.status;

    if (status.isGranted) {
      // Permission is already granted.
      return true;
    } else if (status.isDenied) {
      // Permission is denied, so request it from the user.
      status = await Permission.camera.request();
      if (status.isGranted) {
        // Permission granted after the request.
        return true;
      } else if (status.isPermanentlyDenied) {
        // If permission is permanently denied, inform the user and offer to open app settings.
        // `context.mounted` check is crucial to ensure the widget is still in the tree.
        if (context.mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Camera permission permanently denied. Please enable it from app settings.',
            isError: true,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () =>
                  openAppSettings(), // Opens the app's settings screen
            ),
          );
        }
        return false;
      }
    }
    // Return false if permission is neither granted nor permanently denied (e.g., restricted, limited).
    return false;
  }

  // Requests location permission (specifically, when in use) from the user.
  // Returns `true` if permission is granted, `false` otherwise.
  Future<bool> requestLocationPermission(BuildContext context) async {
    // Get the current status of the location permission (when in use).
    var status = await Permission.locationWhenInUse.status;

    if (status.isGranted) {
      // Permission is already granted.
      return true;
    } else if (status.isDenied) {
      // Permission is denied, so request it from the user.
      status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        // Permission granted after the request.
        return true;
      } else if (status.isPermanentlyDenied) {
        // If permission is permanently denied, inform the user and offer to open app settings.
        if (context.mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Location permission permanently denied. Please enable it from app settings.',
            isError: true,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          );
        }
        return false;
      }
    }
    return false;
  }

  // Requests storage permission (READ/WRITE).
  // IMPORTANT NOTES:
  // - For Android 10 (API 29) and above, `WRITE_EXTERNAL_STORAGE` is largely deprecated
  //   for app-specific files due to scoped storage. `getApplicationDocumentsDirectory()`
  //   (used in `FileService`) does NOT require this permission.
  // - This permission is still relevant for:
  //   - Older Android versions (API 28 and below).
  //   - Accessing/modifying files in general external storage (e.g., Downloads folder).
  //   - Sharing files to other apps (though `share_plus` often handles this via content URIs).
  Future<bool> requestStoragePermission(BuildContext context) async {
    // Get the current status of the storage permission.
    var status = await Permission.storage.status;

    if (status.isGranted) {
      // Permission is already granted.
      return true;
    } else if (status.isDenied) {
      // Permission is denied, so request it from the user.
      status = await Permission.storage.request();
      if (status.isGranted) {
        // Permission granted after the request.
        return true;
      } else if (status.isPermanentlyDenied) {
        // If permission is permanently denied, inform the user and offer to open app settings.
        if (context.mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Storage permission permanently denied. Please enable it from app settings.',
            isError: true,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          );
        }
        return false;
      }
    }
    return false;
  }
}
