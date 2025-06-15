// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Required for Firebase Authentication
import 'package:google_sign_in/google_sign_in.dart'; // Required for Google Sign-In
import 'package:line_survey_pro/screens/sign_in_screen.dart'; // Path to your sign-in screen
import 'package:line_survey_pro/screens/dashboard_tab.dart'; // Import your DashboardTab
import 'package:line_survey_pro/screens/export_screen.dart'; // Import your ExportScreen
import 'package:line_survey_pro/screens/realtime_tasks_screen.dart'; // Import your RealTimeTasksScreen

// Define a GlobalKey for HomeScreenState
final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      HomeScreenState(); // Changed to public for GlobalKey
}

class HomeScreenState extends State<HomeScreen> {
  // Changed to public
  User? _currentUser; // Variable to hold the current authenticated user
  int _selectedIndex = 0; // State for the currently selected tab index

  // List of widgets (screens) to display in the BottomNavigationBar
  // These correspond to the tabs: Dashboard, Export, Real-Time Tasks
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardTab(),
    ExportScreen(),
    RealTimeTasksScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize _currentUser with the current user upon widget creation
    _currentUser = FirebaseAuth.instance.currentUser;

    // Listen for authentication state changes and update _currentUser
    // This ensures the UI reflects login/logout status dynamically
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        // Check if the widget is still in the widget tree
        setState(() {
          _currentUser = user; // Update the user when auth state changes
        });
      }
    });
  }

  // NEW: Method to change the selected tab programmatically
  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to handle user sign out from both Firebase and Google
  Future<void> _signOut() async {
    try {
      // 1. Sign out from Firebase Authentication
      await FirebaseAuth.instance.signOut();

      // 2. Sign out from GoogleSignIn as well, if the user used Google to log in.
      // This is important to clear the Google session.
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      // 3. After successful sign-out, navigate back to the SignInScreen.
      // pushAndRemoveUntil removes all routes from the stack until the predicate returns true.
      // Here, it removes all previous routes, effectively making SignInScreen the new root.
      if (mounted) {
        // Check if the widget is still mounted before navigating
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Handle any errors that occur during the sign-out process
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
      print('Error signing out: $e'); // Log the error for debugging
    }
  }

  // Callback for when a tab is tapped in the BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user from the state variable, which is updated by the authStateChanges listener
    final user = _currentUser;

    // Determine the AppBar title based on the selected tab
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
        title: Text(appBarTitle), // Dynamic title based on selected tab
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Logout icon
            onPressed: _signOut, // Assign the _signOut function to the button
            tooltip: 'Sign Out', // Tooltip for accessibility
          ),
        ],
      ),
      body: Center(
        // Display the widget corresponding to the selected index
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
        currentIndex: _selectedIndex, // The currently selected tab
        selectedItemColor:
            Theme.of(context).primaryColor, // Color for selected icon/label
        unselectedItemColor:
            Theme.of(context).hintColor, // Color for unselected icons/labels
        backgroundColor:
            Theme.of(context).canvasColor, // Background color of the bar
        type: BottomNavigationBarType.fixed, // Ensure all items are visible
        onTap: _onItemTapped, // Callback when a tab is tapped
      ),
    );
  }
}
