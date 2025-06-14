// lib/screens/sign_in_screen.dart
// Updated for consistent UI theming.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Authentication
import 'package:google_sign_in/google_sign_in.dart'; // For Google Sign-In
import 'package:line_survey_pro/screens/home_screen.dart'; // Your home screen

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isSigningIn = false; // To manage the loading state

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign-In cancelled.')),
          );
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

      // If sign-in is successful, navigate to the HomeScreen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase specific authentication errors
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
          message = 'Google Sign-In is not enabled for this Firebase project.';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      print('Firebase Auth Error: ${e.code} - ${e.message}');
    } catch (e) {
      // Catch any other general errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
      print('General Sign-In Error: $e');
    } finally {
      setState(() {
        _isSigningIn = false; // Reset loading state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the color scheme from the theme
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        // AppBar style is inherited from main.dart ThemeData
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(
              32.0), // Increased padding for better spacing
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your app's logo or a welcoming message
              Text(
                'Welcome to Line Survey Pro!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: colorScheme.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50), // More vertical spacing
              _isSigningIn
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.tertiary), // Use tertiary color (orange)
                    )
                  : ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/2048px-Google_%22G%22_logo.svg.png',
                        height: 28.0, // Slightly larger icon
                        width: 28.0,
                      ),
                      label: const Text('Sign in with Google'),
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size(double.infinity, 55), // Taller button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              30), // More rounded corners (Pill shape)
                        ),
                        backgroundColor:
                            Colors.white, // White background for Google button
                        foregroundColor:
                            Colors.black87, // Dark text for Google button
                        elevation: 5, // More prominent shadow
                        textStyle: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                                color: Colors.black87), // Use themed text style
                      ),
                    ),
              const SizedBox(height: 30), // More spacing
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
