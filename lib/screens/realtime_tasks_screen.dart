// lib/screens/realtime_tasks_screen.dart
// A placeholder screen for future real-time functionalities.
// This screen currently displays a message indicating that real-time features are coming soon.

import 'package:flutter/material.dart'; // Required for Flutter UI components
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Utility for showing Snackbars

class RealTimeTasksScreen extends StatelessWidget {
  const RealTimeTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      // Centers its child widget within the available space.
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Adds padding around the content
        child: Column(
          mainAxisAlignment: MainAxisAlignment
              .center, // Centers content vertically within the column
          children: [
            // An icon representing construction or future development
            Icon(Icons.construction, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20), // Vertical spacing
            // Main title text for the screen
            Text(
              'Real-Time Tasks Coming Soon!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall, // Applies a predefined text style
              textAlign: TextAlign.center, // Centers the text horizontally
            ),
            const SizedBox(height: 10), // Vertical spacing
            // Descriptive text for the screen
            Text(
              'This section will feature live updates and interactive tasks for transmission line patrolling.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge, // Applies a predefined text style
              textAlign: TextAlign.center, // Centers the text horizontally
            ),
            const SizedBox(height: 30), // Vertical spacing
            // An example button to illustrate future interaction.
            // Currently, it just shows a snackbar.
            ElevatedButton.icon(
              onPressed: () {
                // Show a simple snackbar as a placeholder action
                SnackBarUtils.showSnackBar(context, 'Stay tuned for updates!');
              },
              icon: const Icon(Icons.info_outline), // Icon for the button
              label: const Text('Learn More'), // Text label for the button
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.blueGrey, // Custom background color for the button
              ),
            ),
          ],
        ),
      ),
    );
  }
}
