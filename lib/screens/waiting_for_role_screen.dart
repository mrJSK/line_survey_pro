// lib/screens/waiting_for_role_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Assuming you have this utility
import 'package:line_survey_pro/services/auth_service.dart'; // For logout
import 'package:line_survey_pro/screens/sign_in_screen.dart'; // Import SignInScreen

class WaitingForRoleScreen extends StatefulWidget {
  const WaitingForRoleScreen({super.key});

  @override
  State<WaitingForRoleScreen> createState() => _WaitingForRoleScreenState();
}

class _WaitingForRoleScreenState extends State<WaitingForRoleScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Pending Approval'),
        automaticallyImplyLeading: false, // Prevent users from going back
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut(); // Allow users to sign out
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 80,
                color: colorScheme.tertiary, // A warning/pending color
              ),
              const SizedBox(height: 20),
              Text(
                'Your account is awaiting role assignment.',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Please contact your administrator to get your role assigned (e.g., Worker or Manager). Once assigned, you will gain full access to the app features.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () async {
                  // Option to refresh status (admin might have assigned role)
                  if (mounted) {
                    SnackBarUtils.showSnackBar(
                        context, 'Checking for role update...');
                  }
                  await _authService
                      .signOut(); // Force sign out to re-check on next login
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const SignInScreen()),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Re-check Role (Requires Sign Out)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
