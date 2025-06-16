// lib/screens/sign_in_screen.dart
// Updated for consistent UI theming and account approval workflow, with enhanced error handling.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Authentication
import 'package:google_sign_in/google_sign_in.dart'; // For Google Sign-In
import 'package:flutter/services.dart'; // NEW: For PlatformException
import 'package:line_survey_pro/screens/home_screen.dart'; // Your home screen
import 'package:line_survey_pro/services/auth_service.dart'; // Import AuthService
import 'package:line_survey_pro/screens/waiting_for_approval_screen.dart'; // Import WaitingForApprovalScreen
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Import SnackBarUtils

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isSigningIn = false; // To manage the loading state
  final AuthService _authService = AuthService();

  // Function to handle Google Sign-In
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSigningIn = true; // Set loading state to true
    });

    try {
      // 1. Create a GoogleSignIn instance
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 2. Start the interactive sign-in process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in flow
        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'Google Sign-In cancelled.');
        }
        return;
      }

      // 3. Obtain the auth details from the Google request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. Create a new credential with Google ID token and access token
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Sign in to Firebase with the Google credential
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Get the current Firebase user after successful authentication
      final User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        // Ensure user profile exists in Firestore.
        await _authService.ensureUserProfileExists(
          firebaseUser.uid,
          firebaseUser.email!,
          firebaseUser.displayName,
        );

        final userProfile = await _authService.getCurrentUserProfile();

        if (mounted) {
          if (userProfile == null) {
            SnackBarUtils.showSnackBar(context,
                'User profile not found after sign-in. Please try again.',
                isError: true);
            await _authService.signOut();
            return;
          }

          if (userProfile.status == 'approved') {
            if (userProfile.role == 'Worker' ||
                userProfile.role == 'Manager' ||
                userProfile.role == 'Admin') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) =>
                        WaitingForApprovalScreen(userProfile: userProfile)),
              );
            }
          } else if (userProfile.status == 'pending' ||
              userProfile.status == 'rejected') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) =>
                      WaitingForApprovalScreen(userProfile: userProfile)),
            );
          } else {
            SnackBarUtils.showSnackBar(context,
                'Account status unknown. Please contact administrator.',
                isError: true);
            await _authService.signOut();
          }
        }
      } else {
        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'User not found after sign-in.',
              isError: true);
        }
      }
    } on PlatformException catch (e) {
      // NEW: Catch PlatformException specifically
      if (e.code == 'network_error' ||
          e.message!.contains('network_error') ||
          e.message!.contains('ApiException: 7')) {
        // Check for common network error codes/messages
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'No internet connection. Please connect and try again.',
              isError: true);
        }
        print('PlatformException (Network): ${e.code} - ${e.message}');
      } else {
        // Handle other PlatformExceptions
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Sign-in failed due to platform error: ${e.message}',
              isError: true);
        }
        print('PlatformException: ${e.code} - ${e.message}');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = 'An account already exists with different credentials.';
          break;
        case 'invalid-credential':
          message = 'The credential provided is invalid.';
          break;
        case 'user-disabled':
          message =
              'The user associated with the given credential has been disabled.';
          break;
        case 'operation-not-allowed':
          message = 'Google Sign-In is not enabled for this project.';
          break;
        case 'network-request-failed':
          message =
              'A network error occurred. Please check your internet connection.';
          break;
        default:
          message = 'Sign-in failed: ${e.message}';
          break;
      }
      if (mounted) {
        SnackBarUtils.showSnackBar(context, message, isError: true);
      }
      print('Auth Error: ${e.code} - ${e.message}');
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'An unexpected error occurred: $e',
            isError: true);
      }
      print('General Sign-In Error: $e');
    } finally {
      setState(() {
        _isSigningIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Line Survey Pro!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: colorScheme.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              _isSigningIn
                  ? CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.tertiary),
                    )
                  : ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      // Use a local asset for the Google logo
                      icon: Image.asset(
                        'assets/google_logo.webp', // Assuming you downloaded and placed it here
                        height: 28.0,
                        width: 28.0,
                      ),
                      label: const Text('Sign in with Google'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 5,
                        textStyle: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: Colors.black87),
                      ),
                    ),
              const SizedBox(height: 30),
              Text(
                'Please sign in to continue using the app.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
