// lib/widgets/connectivity_wrapper.dart

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:line_survey_pro/screens/no_internet_screen.dart';
import 'dart:async';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false; // Initial state

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // Check connectivity once on startup
  Future<void> _checkInitialConnectivity() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final bool currentlyOffline =
        !results.contains(ConnectivityResult.mobile) &&
            !results.contains(ConnectivityResult.wifi) &&
            !results.contains(ConnectivityResult.ethernet);

    if (currentlyOffline != _isOffline) {
      setState(() {
        _isOffline = currentlyOffline;
      });

      if (_isOffline) {
        // If offline, push NoInternetScreen on top
        // Use a persistent route to avoid popping it accidentally if multiple screens are pushed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => NoInternetScreen(onRetry: () {
                // When "Try Again" is pressed on NoInternetScreen, it will attempt to pop itself.
                // The wrapper will then re-evaluate the status.
              }),
            ),
            (route) => false, // Clear all routes below it
          );
        });
      } else if (Navigator.of(context).canPop() &&
          ModalRoute.of(context)?.settings.name == '/noInternet') {
        // If back online and NoInternetScreen is currently displayed, pop it
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
