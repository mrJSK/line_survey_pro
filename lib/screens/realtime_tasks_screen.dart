// lib/screens/realtime_tasks_screen.dart
// A placeholder screen for future real-time functionalities.
// This screen currently displays a message indicating that real-time features are coming soon.
// Updated for consistent UI theming.

import 'package:flutter/material.dart'; // Required for Flutter UI components
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Utility for showing Snackbars

class RealTimeTasksScreen extends StatelessWidget {
  const RealTimeTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the color scheme from the theme
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Center(
      // Centers its child widget within the available space.
      child: Padding(
        padding: const EdgeInsets.all(24.0), // Increased padding
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Centers content vertically
          children: [
            // An icon representing construction or future development
            Icon(Icons.construction,
                size: 100,
                color: colorScheme.primary
                    .withOpacity(0.4)), // Larger, themed icon
            const SizedBox(height: 30), // Vertical spacing
            // Main title text for the screen
            Text(
              'Real-Time Tasks Coming Soon!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: colorScheme.primary), // Themed title
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15), // Vertical spacing
            // Descriptive text for the screen
            Text(
              'This section will feature live updates and interactive tasks for transmission line patrolling. Stay tuned for exciting new features!',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colorScheme.onSurface), // Themed body text
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40), // Vertical spacing
            // An example button to illustrate future interaction.
            ElevatedButton.icon(
              onPressed: () {
                SnackBarUtils.showSnackBar(context, 'Stay tuned for updates!');
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('Learn More'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    colorScheme.secondary, // Use a themed accent color
                foregroundColor: colorScheme.onSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
