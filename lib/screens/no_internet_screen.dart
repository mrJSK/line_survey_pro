// lib/screens/no_internet_screen.dart

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity_plus
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // For potential feedback

class NoInternetScreen extends StatefulWidget {
  // This callback allows us to notify the parent screen (e.g., SignInScreen)
  // when internet connectivity is restored, so it can try to proceed.
  final VoidCallback onRetry;

  const NoInternetScreen({super.key, required this.onRetry});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _isCheckingConnectivity = false;

  Future<void> _checkAndRetry() async {
    setState(() {
      _isCheckingConnectivity = true;
    });

    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet)) {
        // Internet is available, trigger the retry callback
        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'Internet connection restored!');
          widget
              .onRetry(); // Call the callback to try navigating back/re-authenticating
        }
      } else {
        // Still no internet
        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'Still no internet connection.',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Error checking connectivity: $e',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingConnectivity = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('No Internet Connection'),
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 100,
                color: colorScheme.error, // Use error color for attention
              ),
              const SizedBox(height: 30),
              Text(
                'Oops! No Internet Connection',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'It seems you\'re offline. Please check your network settings and try again.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _isCheckingConnectivity
                  ? CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    )
                  : ElevatedButton.icon(
                      onPressed: _checkAndRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
