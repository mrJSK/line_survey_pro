import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:line_survey_pro/screens/sign_in_screen.dart';
import 'package:line_survey_pro/screens/dashboard_tab.dart';
import 'package:line_survey_pro/screens/export_screen.dart';
import 'package:line_survey_pro/screens/realtime_tasks_screen.dart';
import 'package:line_survey_pro/utils/snackbar_utils.dart';
import 'package:line_survey_pro/screens/info_screen.dart';
import 'package:line_survey_pro/services/auth_service.dart'; // Import AuthService
import 'package:line_survey_pro/models/user_profile.dart'; // Import UserProfile
import 'package:line_survey_pro/screens/manage_lines_screen.dart'; // Import ManageLinesScreen
import 'package:line_survey_pro/screens/admin_user_management_screen.dart'; // Import AdminUserManagementScreen

final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  UserProfile? _currentUserProfile; // Store the UserProfile
  int _selectedIndex = 0;

  // The list of widgets for the BottomNavigationBar tabs.
  // These are static and do not change based on role. Content within them will.
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardTab(),
    ExportScreen(),
    RealTimeTasksScreen(),
  ];

  final AuthService _authService = AuthService(); // Instantiate AuthService

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _listenToAuthChanges(); // Listen to Firebase Auth state changes
    _fetchUserProfile(); // Fetch initial user profile
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
        if (user != null) {
          _fetchUserProfile(); // Re-fetch profile if user changes (e.g., re-login)
        } else {
          _currentUserProfile = null; // Clear profile on logout
        }
      }
    });
  }

  void _fetchUserProfile() async {
    if (_currentUser != null) {
      final profile = await _authService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _currentUserProfile = profile;
        });
      }
    }
  }

  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
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
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InfoScreen()),
    );
  }

  void _navigateToManageLinesScreen() {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageLinesScreen()),
    );
  }

  void _navigateToAdminUserManagementScreen() {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const AdminUserManagementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    switch (_selectedIndex) {
      case 0:
        appBarTitle = 'Survey Dashboard';
        break;
      case 1:
        appBarTitle = 'Export Records';
        break;
      case 2:
        appBarTitle = 'Real-Time Tasks';
        break;
      default:
        appBarTitle = 'Line Survey Pro';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
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
                    'Line Survey Pro',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentUser?.email ?? 'Guest',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  if (_currentUserProfile != null &&
                      _currentUserProfile!.role != null)
                    Text(
                      'Role: ${_currentUserProfile!.role}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('Info'),
              onTap: _navigateToInfoScreen,
            ),
            // Admin-specific menu items
            if (_currentUserProfile?.role == 'Admin')
              ListTile(
                leading: Icon(Icons.people,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('User Management'),
                onTap: _navigateToAdminUserManagementScreen,
              ),
            // Admin and Manager menu item
            if (_currentUserProfile?.role == 'Admin' ||
                _currentUserProfile?.role == 'Manager')
              ListTile(
                leading: Icon(Icons.settings_input_antenna,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('Manage Transmission Lines'),
                onTap: _navigateToManageLinesScreen,
              ),
            const Divider(), // A separator before logout
            ListTile(
              leading: Icon(Icons.logout,
                  color: Theme.of(context).colorScheme.error),
              title: const Text('Logout'),
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Export',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Real-Time',
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
  }
}
