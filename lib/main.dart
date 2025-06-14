// lib/main.dart
// Entry point of the Flutter application.
// Now includes Firebase initialization and routes to SignInScreen initially.
// Updated for a more modern UI theme.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Required for Firebase initialization
import 'package:firebase_auth/firebase_auth.dart'; // Required to check auth state
import 'package:line_survey_pro/screens/home_screen.dart';
import 'package:line_survey_pro/screens/sign_in_screen.dart'; // Your new sign-in screen
import 'package:line_survey_pro/services/local_database_service.dart'; // Service for local database initialization

// IMPORTANT: You need to generate this file using FlutterFire CLI.
// Run: `flutterfire configure` in your project root after adding Firebase to the project.
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the local SQLite database. This can run independently.
  await LocalDatabaseService().initializeDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the primary blue color based on your request
    const Color primaryBlue = Color(0xFF0D6EFD);

    return MaterialApp(
      title: 'Line Survey Pro',
      debugShowCheckedModeBanner: false, // Hide the debug banner
      theme: ThemeData(
        brightness: Brightness.light, // Ensure light mode
        // Define a custom ColorScheme using the primary blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue, // The base color for generating the scheme
          primary: primaryBlue, // Your specified blue
          onPrimary: Colors.white, // Text/icons on primary color
          secondary: const Color(
              0xFF28A745), // A vibrant green for accents (e.g., progress, success)
          onSecondary: Colors.white,
          tertiary: const Color(
              0xFFFFC107), // An orange/amber for warning/export actions
          onTertiary: Colors.black87,
          surface: Colors.white, // Background for cards and surfaces
          onSurface: Colors.black87, // Text/icons on surface
          background: Colors.white, // Main scaffold background
          onBackground: Colors.black87,
          error: const Color(0xFFDC3545), // Red for error states
          onError: Colors.white,
          brightness: Brightness.light,
        ),

        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue, // Blue AppBar background
          foregroundColor: Colors.white, // White text/icons on AppBar
          elevation: 4.0, // Subtle shadow for depth
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter', // Applying a modern font
          ),
        ),

        // ElevatedButton theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue, // Primary blue for buttons
            foregroundColor: Colors.white, // White text on buttons
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(10), // Moderately rounded corners
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 14), // Generous padding
            elevation: 4, // Good shadow for buttons
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),

        // InputDecorationTheme for text fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: primaryBlue.withOpacity(0.05), // Very light blue fill
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Rounded borders
            borderSide: BorderSide.none, // No border line by default
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: primaryBlue,
                width: 2), // Primary blue border when focused
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: primaryBlue.withOpacity(0.3),
                width: 1), // Lighter blue border when enabled
          ),
          labelStyle: TextStyle(color: primaryBlue.withOpacity(0.8)),
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIconColor: primaryBlue, // Primary blue for prefix icons
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),

        // Card theme
        cardTheme: CardThemeData(
          elevation: 4, // Consistent shadow for cards
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12), // Rounded corners for cards
          ),
          margin: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8), // Consistent margin
          color: Colors.white, // Ensure cards are white
        ),

        // Progress indicator theme
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: primaryBlue, // Use primary blue for active progress
          linearTrackColor:
              primaryBlue.withOpacity(0.2), // Lighter track for linear progress
        ),

        // Typography adjustments for a cleaner look
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87, // Strong, readable headings
              fontSize: 24),
          titleMedium: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87, // Distinct section titles
              fontSize: 18),
          bodyLarge: TextStyle(
              fontSize: 16.0,
              color: Colors.black87), // Primary body text for readability
          bodyMedium: TextStyle(
              fontSize: 14.0,
              color: Colors.black54), // Secondary body text, slightly subdued
          bodySmall: TextStyle(
            fontSize: 12.0,
            color: Colors.black45, // Fine print, timestamps etc.
          ),
          labelLarge: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.white), // Button labels
        ).apply(
          fontFamily: 'Roboto', // Material Design's default font
        ),

        // Bottom Navigation Bar theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: primaryBlue, // Selected icon/label color
          unselectedItemColor:
              Colors.grey.shade600, // Unselected icon/label color
          backgroundColor: Colors.white, // White background for the bar
          type: BottomNavigationBarType.fixed, // Ensure all items are visible
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Roboto'),
        ),
      ),
      home: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error initializing: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (authSnapshot.hasData) {
                return const HomeScreen();
              } else {
                return const SignInScreen();
              }
            },
          );
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/signIn': (context) => const SignInScreen(),
      },
    );
  }
}
