// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For initial authentication check
import 'package:line_survey_pro/screens/home_screen.dart'; // Your main app screen
import 'package:line_survey_pro/screens/sign_in_screen.dart'; // Your sign-in screen
// Removed LocalDatabaseService import as it's initialized in main.dart
// Removed Firebase options import as it's initialized in main.dart
import 'package:line_survey_pro/services/auth_service.dart'; // Import AuthService
import 'package:line_survey_pro/models/user_profile.dart'; // Import UserProfile model
import 'package:line_survey_pro/screens/waiting_for_approval_screen.dart'; // Import WaitingForApprovalScreen
import 'package:line_survey_pro/screens/user_profile_screen.dart'; // Import UserProfileScreen
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Import SnackBarUtils

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService(); // AuthService instance

  @override
  void initState() {
    super.initState();
    _initializeAppAndNavigate(); // Directly call the navigation logic
  }

  // Removed dispose and animation-related methods as they are no longer needed
  // with the simplified splash screen.

  Future<void> _initializeAppAndNavigate() async {
    // Add a short delay to display the splash screen content
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Check authentication state from Firebase Auth
      User? user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (user == null) {
        // No user logged in, navigate to SignInScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        // User is logged in via Firebase Auth, now fetch or ensure UserProfile
        // Force fetch to get the latest status and profile details from Firestore
        final UserProfile? currentUserProfile =
            await _authService.getCurrentUserProfile(forceFetch: true);

        if (!mounted) return;

        if (currentUserProfile == null) {
          // This case could happen if a Firebase user exists but their profile
          // document in Firestore is somehow missing or unretrievable.
          SnackBarUtils.showSnackBar(
            context,
            'User profile not found. Please try logging in again.',
            isError: true,
          );
          await _authService.signOut(); // Force sign out
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SignInScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          // User profile exists, check approval status and completeness
          if (currentUserProfile.status == 'approved') {
            // Check if mobile and aadhaar are filled
            // Ensure you are checking against empty strings as well, not just null
            if (currentUserProfile.mobile == null ||
                currentUserProfile.mobile!.isEmpty ||
                currentUserProfile.aadhaarNumber == null ||
                currentUserProfile.aadhaarNumber!.isEmpty) {
              // If details are missing, force user to fill them
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    currentUserProfile: currentUserProfile,
                    isForcedCompletion: true, // Indicate forced completion
                  ),
                ),
                (Route<dynamic> route) =>
                    false, // Prevent going back from profile screen
              );
            } else {
              // User is approved and profile details are complete, go to Home Screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (Route<dynamic> route) => false,
              );
            }
          } else {
            // User is not approved, take them to the waiting screen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) =>
                    WaitingForApprovalScreen(userProfile: currentUserProfile),
              ),
              (Route<dynamic> route) => false,
            );
          }
        }
      }
    } catch (e) {
      // Handle any initialization or authentication errors
      print("Splash Screen Initialization Error: $e");
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'App initialization failed: ${e.toString()}',
          isError: true,
        );
        // Fallback to sign-in screen in case of critical error
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary, // Background color of your app
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple loading animation
            Icon(
              Icons.electric_bolt, // Icon representing a line/survey
              size: 120,
              color: colorScheme.tertiary,
            ),
            const SizedBox(height: 30),
            Text(
              'Line Survey Pro',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                backgroundColor: colorScheme.onPrimary.withOpacity(0.3),
                valueColor:
                    AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Patrolling the future...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
