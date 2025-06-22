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
import 'package:line_survey_pro/l10n/app_localizations.dart'; // Import AppLocalizations

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
          SnackBarUtils.showSnackBar(
              context, AppLocalizations.of(context)!.googleSignInCancelled);
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
            SnackBarUtils.showSnackBar(
                context, AppLocalizations.of(context)!.userProfileNotFound,
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
            SnackBarUtils.showSnackBar(
                context, AppLocalizations.of(context)!.accountStatusUnknown,
                isError: true);
            await _authService.signOut();
          }
        }
      } else {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, AppLocalizations.of(context)!.userNotFoundAfterSignIn,
              isError: true); // Add this string to ARB if not already there
        }
      }
    } on PlatformException catch (e) {
      if (e.code == 'network_error' ||
          e.message!.contains('network_error') ||
          e.message!.contains('ApiException: 7')) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, AppLocalizations.of(context)!.noInternetConnection,
              isError: true);
        }
        print('PlatformException (Network): ${e.code} - ${e.message}');
      } else {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context,
              AppLocalizations.of(context)!
                  .signInFailed(e.message ?? 'unknown error'),
              isError: true);
        }
        print('PlatformException: ${e.code} - ${e.message}');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = AppLocalizations.of(context)!
              .accountExistsWithDifferentCredential;
          break;
        case 'invalid-credential':
          message = AppLocalizations.of(context)!.invalidCredential;
          break;
        case 'user-disabled':
          message = AppLocalizations.of(context)!.userDisabled;
          break;
        case 'operation-not-allowed':
          message = AppLocalizations.of(context)!.operationNotAllowed;
          break;
        case 'network-request-failed':
          message = AppLocalizations.of(context)!.networkRequestFailed;
          break;
        default:
          message = AppLocalizations.of(context)!
              .signInFailed(e.message ?? 'unknown error');
          break;
      }
      if (mounted) {
        SnackBarUtils.showSnackBar(context, message, isError: true);
      }
      print('Auth Error: ${e.code} - ${e.message}');
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context,
            AppLocalizations.of(context)!
                .anUnexpectedErrorOccurred(e.toString()),
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
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.signIn),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                localizations.welcomeMessage,
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
                      icon: Image.asset(
                        'assets/google_logo.webp',
                        height: 28.0,
                        width: 28.0,
                      ),
                      label: Text(localizations.signInWithGoogle),
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
                localizations.signInPrompt,
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
