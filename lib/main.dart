// lib/main.dart
// Entry point of the Flutter application.
// Now includes Firebase initialization and routes to SignInScreen initially.
// Updated for a more modern UI theme, and wrapped with ConnectivityWrapper.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Add this
import 'package:line_survey_pro/screens/home_screen.dart';
import 'package:line_survey_pro/screens/sign_in_screen.dart';
import 'package:line_survey_pro/services/local_database_service.dart';
import 'package:line_survey_pro/screens/splash_screen.dart';
import 'package:line_survey_pro/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalDatabaseService().initializeDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0D6EFD);

    return MaterialApp(
      title:
          'Line Survey Pro', // This will be set by the first available localization
      debugShowCheckedModeBanner: false,
      // Add these localization delegates
      localizationsDelegates: [
        AppLocalizations.delegate, // Generated app localizations
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Add supported locales (English and Hindi)
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
      ],

      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          onPrimary: Colors.white,
          secondary: const Color(0xFF28A745),
          onSecondary: Colors.white,
          tertiary: const Color(0xFFFFC107),
          onTertiary: Colors.black87,
          surface: Colors.white,
          onSurface: Colors.black87,
          background: Colors.white,
          onBackground: Colors.black87,
          error: const Color(0xFFDC3545),
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4.0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 4,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: primaryBlue.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: primaryBlue.withOpacity(0.3), width: 1),
          ),
          labelStyle: TextStyle(color: primaryBlue.withOpacity(0.8)),
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIconColor: primaryBlue,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: primaryBlue,
          linearTrackColor: primaryBlue.withOpacity(0.2),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 24),
          titleMedium: TextStyle(
              fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 18),
          bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.black54),
          bodySmall: TextStyle(
            fontSize: 12.0,
            color: Colors.black45,
          ),
          labelLarge: TextStyle(
              fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
        ).apply(
          fontFamily: 'Roboto',
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Roboto'),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/home': (BuildContext context) => const HomeScreen(),
        '/signIn': (BuildContext context) => const SignInScreen(),
      },
    );
  }
}
