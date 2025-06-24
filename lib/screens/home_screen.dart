// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:line_survey_pro/screens/sign_in_screen.dart';
import 'package:line_survey_pro/screens/dashboard_tab.dart';
import 'package:line_survey_pro/screens/export_screen.dart';
import 'package:line_survey_pro/screens/realtime_tasks_screen.dart';
import 'package:line_survey_pro/screens/splash_screen.dart';
import 'package:line_survey_pro/screens/waiting_for_approval_screen.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:line_survey_pro/screens/info_screen.dart';
import 'package:line_survey_pro/services/auth_service.dart';
import 'package:line_survey_pro/models/user_profile.dart';
import 'package:line_survey_pro/screens/manage_lines_screen.dart';
import 'package:line_survey_pro/screens/admin_user_management_screen.dart';
import 'package:line_survey_pro/screens/user_profile_screen.dart';
import 'package:line_survey_pro/l10n/app_localizations.dart';

final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error signing out: ${e.toString()}',
          isError: true,
        );
      }
      print('Error signing out: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToInfoScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InfoScreen()),
    );
  }

  void _navigateToManageLinesScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageLinesScreen()),
    );
  }

  void _navigateToUserProfileScreen(UserProfile currentUserProfile) {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          currentUserProfile: currentUserProfile,
          isForcedCompletion: false, // Not a forced completion here
        ),
      ),
    );
  }

  void _navigateToAdminUserManagementScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const AdminUserManagementScreen()),
    );
  }

  Widget _buildAppWithNewLocale(Locale newLocale) {
    return MaterialApp(
      locale: newLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      title: 'Line Survey Pro',
      theme: Theme.of(context).copyWith(),
      home: const SplashScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    String appBarTitle;
    switch (_selectedIndex) {
      case 0:
        appBarTitle = localizations.surveyDashboard;
        break;
      case 1:
        appBarTitle = localizations.exportRecords;
        break;
      case 2:
        appBarTitle = localizations.realtimeTasks;
        break;
      default:
        appBarTitle = localizations.appTitle;
    }

    return StreamBuilder<UserProfile?>(
      stream: _authService.userProfileStream,
      builder: (context, snapshot) {
        final UserProfile? currentUserProfile = snapshot.data;
        final bool isLoadingProfile =
            snapshot.connectionState == ConnectionState.waiting;

        Locale? targetLocale;
        if (currentUserProfile?.role == 'Worker') {
          targetLocale = const Locale('hi');
        } else if (currentUserProfile != null) {
          targetLocale = const Locale('en');
        }

        final currentContextLocale = Localizations.localeOf(context);

        if (targetLocale != null &&
            currentContextLocale.languageCode != targetLocale.languageCode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => _buildAppWithNewLocale(targetLocale!),
              ),
              (route) => false,
            );
          });
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final List<Widget> _widgetOptions = <Widget>[
          DashboardTab(currentUserProfile: currentUserProfile),
          ExportScreen(currentUserProfile: currentUserProfile),
          RealTimeTasksScreen(currentUserProfile: currentUserProfile),
        ];

        if (isLoadingProfile) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (currentUserProfile == null ||
            currentUserProfile.status != 'approved') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (currentUserProfile == null) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SignInScreen()),
                (Route<dynamic> route) => false,
              );
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => WaitingForApprovalScreen(
                        userProfile: currentUserProfile)),
                (Route<dynamic> route) => false,
              );
            }
          });
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // Now that currentUserProfile is guaranteed not null and approved, we can use it.
        return Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            centerTitle: true,
            actions: const [],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        localizations.appTitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentUserProfile.email,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                      if (currentUserProfile.role != null)
                        Text(
                          '${localizations.roleLabel}: ${currentUserProfile.role}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(localizations.info),
                  onTap: _navigateToInfoScreen,
                ),
                if (currentUserProfile.role == 'Admin')
                  ListTile(
                    leading: Icon(Icons.people,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(localizations.userManagement),
                    onTap: _navigateToAdminUserManagementScreen,
                  ),
                if (currentUserProfile.role == 'Admin' ||
                    currentUserProfile.role == 'Manager')
                  ListTile(
                    leading: Icon(Icons.settings_input_antenna,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(localizations.manageTransmissionLines),
                    onTap: _navigateToManageLinesScreen,
                  ),
                // NEW: Show "My Profile" only for Workers
                if (currentUserProfile.role == 'Worker')
                  ListTile(
                    leading: Icon(Icons.account_circle,
                        color: Theme.of(context).colorScheme.primary),
                    title: const Text(
                        'My Profile'), // You might want to localize this
                    onTap: () =>
                        _navigateToUserProfileScreen(currentUserProfile),
                  ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.logout,
                      color: Theme.of(context).colorScheme.error),
                  title: Text(localizations.logout),
                  onTap: () {
                    Navigator.pop(context);
                    _signOut();
                  },
                ),
              ],
            ),
          ),
          body: Center(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard),
                label: localizations.surveyDashboard,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.upload_file),
                label: localizations.exportRecords,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.location_on),
                label: localizations.realtimeTasks,
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Theme.of(context).hintColor,
            backgroundColor: Theme.of(context).canvasColor,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}
