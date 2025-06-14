// lib/services/location_service.dart
// Provides functionality to get the current GPS location using the geolocator package.

import 'package:geolocator/geolocator.dart'; // Geolocator package for location services

class LocationService {
  // Fetches the current geographic position (latitude, longitude, etc.) of the device.
  // It first checks for location service enablement and permissions.
  // Throws an error if location services are disabled or permissions are denied.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Test if location services are enabled on the device.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, so throw an error.
      // The calling UI should typically show a message to the user prompting them
      // to enable location services in their device settings.
      return Future.error(
          'Location services are disabled. Please enable them to get GPS coordinates.');
    }

    // 2. Check the current status of location permissions for the app.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // If permissions are denied, attempt to request them from the user.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // If permissions are still denied after the request, throw an error.
        // The user explicitly denied the permission.
        return Future.error('Location permissions are denied by the user.');
      }
    }

    // 3. Check if permissions are permanently denied.
    // If so, the user needs to manually enable them from the app settings.
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied. Please enable them from your device\'s app settings.');
    }

    // 4. If all checks pass (location services enabled and permissions granted),
    // proceed to get the current position of the device.
    // `desiredAccuracy: LocationAccuracy.high` requests the most accurate location.
    // `timeLimit` adds a timeout to prevent waiting indefinitely for a fix.
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high, // Request high accuracy GPS data
      timeLimit:
          const Duration(seconds: 10), // Set a timeout for getting the location
    );
  }
}
