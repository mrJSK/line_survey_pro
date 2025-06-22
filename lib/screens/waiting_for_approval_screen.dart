// lib/screens/waiting_for_approval_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:line_survey_pro/services/auth_service.dart';
import 'package:line_survey_pro/screens/sign_in_screen.dart';
import 'package:line_survey_pro/models/user_profile.dart';
import 'package:line_survey_pro/l10n/app_localizations.dart'; // Import AppLocalizations

class WaitingForApprovalScreen extends StatefulWidget {
  final UserProfile userProfile;

  const WaitingForApprovalScreen({super.key, required this.userProfile});

  @override
  State<WaitingForApprovalScreen> createState() =>
      _WaitingForApprovalScreenState();
}

class _WaitingForApprovalScreenState extends State<WaitingForApprovalScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    String titleText = '';
    String messageText = '';
    IconData displayIcon = Icons.hourglass_empty;
    Color iconColor = colorScheme.tertiary;
    bool showRefreshButton = true;

    switch (widget.userProfile.status) {
      case 'pending':
        titleText = localizations.accountPendingApproval;
        messageText = localizations.awaitingApprovalMessage;
        displayIcon = Icons.hourglass_empty;
        iconColor = colorScheme.tertiary;
        break;
      case 'rejected':
        titleText = localizations.accountRejected;
        messageText = localizations.rejectedMessage;
        displayIcon = Icons.cancel;
        iconColor = colorScheme.error;
        showRefreshButton = false;
        break;
      default:
        titleText = localizations.accountStatusUnknown;
        messageText = localizations.unexpectedAccountStatus;
        displayIcon = Icons.help_outline;
        iconColor = Colors.grey;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            tooltip: localizations.logout,
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
                displayIcon,
                size: 80,
                color: iconColor,
              ),
              const SizedBox(height: 20),
              Text(
                titleText,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                messageText,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (showRefreshButton)
                ElevatedButton.icon(
                  onPressed: () async {
                    if (mounted) {
                      SnackBarUtils.showSnackBar(
                          context,
                          localizations
                              .recheckingAccountStatus); // Assuming new string
                    }
                    await _authService.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const SignInScreen()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(localizations.recheckStatus),
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
