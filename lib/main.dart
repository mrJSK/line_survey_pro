// lib/main.dart
// Entry point of the Flutter application.
// Now includes Firebase initialization and routes to SignInScreen initially.

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
    return MaterialApp(
      title: 'Line Survey Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blueGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.blueGrey),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.green,
          linearTrackColor: Colors.grey,
        ),
        textTheme: const TextTheme(
          headlineSmall:
              TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
          titleMedium:
              TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.black54),
          labelLarge: TextStyle(
              fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      // Use a FutureBuilder to ensure Firebase is initialized before checking auth state
      home: FutureBuilder(
        // Initialize Firebase asynchronously
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          // Check for errors during Firebase initialization
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error initializing Firebase: ${snapshot.error}'),
              ),
            );
          }

          // Show a loading indicator until Firebase is initialized
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Firebase is initialized, now listen for auth state changes
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                // Show a loading indicator while checking initial auth state
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (authSnapshot.hasData) {
                // User is signed in, navigate to HomeScreen
                return const HomeScreen();
              } else {
                // User is not signed in, show SignInScreen
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
