import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Information'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reordered: About this App comes first
            Text(
              'About Line Survey Pro ✨', // Added emoji
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Line Survey Pro – your essential companion for efficient and accurate transmission line and tower patrolling! 🚀\n\n'
              'This app is designed to make your daily survey tasks easier and more organized. Here’s what you can do:\n\n'
              '➡️ *Record Tower Details:* Easily log specific information for each tower you patrol, including its unique number.\n\n'
              '🗺️ *Capture Precise Location:* Automatically grab exact GPS coordinates (latitude and longitude) for every survey point.\n\n'
              '📸 *Take and Attach Photos:* Snap photos right from the app and associate them directly with your survey records. (Please note: Photos are stored *locally* on your device for privacy and efficiency).\n\n'
              '📝 *Detail Patrolling Observations:* Beyond basic tower data, you can now enter specific observations about tower parts, soil, insulators, jumpers, hot spots, bird nests, and much more, using pre-defined options for quick entry.\n\n'
              '☁️ *Sync Your Data:* When you have a stable internet connection, you can easily upload all your collected survey details (excluding photos, which remain local) to our secure cloud database. This ensures your progress is saved and visible to your manager.\n\n'
              '📊 *Track Your Progress:* See how many towers you’ve completed and uploaded, giving you a clear overview of your assigned tasks.\n\n'
              '📦 *Export Reports:* Generate detailed CSV reports of all your survey data for easy sharing and analysis.\n\n'
              'Line Survey Pro is here to streamline your work, making sure every inspection is thorough and every detail is captured accurately. Happy patrolling! 💪', // More detailed explanation with emojis
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            // Moved Developed By section
            Text(
              'Developed By:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Sanjay Kumar'),
            const Text('Sub-Divisional Officer'),
            const Text('UPPTCL'),
            const SizedBox(height: 16),
            Text(
              'Contact:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Email: fswdsanjay@gmail.com'),
            const Text('Phone: +91-8299189690'),
            // Removed Location section as requested
            const SizedBox(height: 32),
            const Text(
              'Version: 1.0.0 (Development)', // You can manage your app's version properly
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
