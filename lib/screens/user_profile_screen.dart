// lib/screens/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/user_profile.dart'; // Import the UserProfile model
import 'package:line_survey_pro/services/auth_service.dart'; // To update user profile
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // For user feedback
import 'package:line_survey_pro/screens/home_screen.dart'; // For navigation after forced completion

class UserProfileScreen extends StatefulWidget {
  final UserProfile currentUserProfile;
  final bool
      isForcedCompletion; // NEW: Indicator if user is forced to fill details

  const UserProfileScreen({
    super.key,
    required this.currentUserProfile,
    this.isForcedCompletion = false, // Default to false
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _aadhaarController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController =
        TextEditingController(text: widget.currentUserProfile.displayName);
    _emailController =
        TextEditingController(text: widget.currentUserProfile.email);
    _mobileController =
        TextEditingController(text: widget.currentUserProfile.mobile);
    _aadhaarController =
        TextEditingController(text: widget.currentUserProfile.aadhaarNumber);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Basic validation for mobile and Aadhaar for forced completion
    // These checks are already in the validator, but an explicit check here
    // ensures the snackbar is shown if the user tries to save an invalid form.
    if (widget.isForcedCompletion) {
      if (_mobileController.text.trim().isEmpty) {
        SnackBarUtils.showSnackBar(context, 'Mobile Number is required.',
            isError: true);
        return;
      }
      if (_aadhaarController.text.trim().isEmpty) {
        SnackBarUtils.showSnackBar(context, 'Aadhaar Number is required.',
            isError: true);
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create an updated UserProfile object
      final updatedProfile = widget.currentUserProfile.copyWith(
        displayName: _displayNameController.text.trim(),
        mobile: _mobileController.text.trim(),
        aadhaarNumber: _aadhaarController.text.trim(),
      );

      // Call AuthService to update the profile in Firestore
      await AuthService().updateUserProfile(updatedProfile);

      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Profile updated successfully!');
        if (widget.isForcedCompletion) {
          // After successful forced completion, navigate to HomeScreen
          // and remove all previous routes to prevent going back to SplashScreen/SignIn.
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          // If not forced, simply pop the screen (for regular profile editing from drawer)
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Error updating profile: $e',
            isError: true);
      }
      print('Error saving user profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Helper for InputDecoration consistent style
  InputDecoration _inputDecoration(
      String label, IconData icon, ColorScheme colorScheme) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colorScheme.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
      labelStyle: TextStyle(
          color: colorScheme.primary.withOpacity(0.8),
          overflow: TextOverflow.ellipsis),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      // Use PopScope for back button control
      canPop: !widget.isForcedCompletion, // Prevent pop if forced completion
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Optionally show a message if pop is prevented
        SnackBarUtils.showSnackBar(
            context, 'Please complete your profile details before proceeding.',
            isError: true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Profile'),
          // Hide the back button if forced completion
          automaticallyImplyLeading: !widget.isForcedCompletion,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'My Profile Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (widget
                    .isForcedCompletion) // Optional: Add a hint for forced completion
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      'Please complete these details to proceed.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _displayNameController,
                  decoration: _inputDecoration(
                      'Display Name (from Google)', Icons.person, colorScheme),
                  readOnly:
                      true, // Display name typically comes from Google, not editable here
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration(
                      'Email (from Google)', Icons.email, colorScheme),
                  readOnly: true, // Email usually not editable from app
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _mobileController,
                  decoration: _inputDecoration(
                      'Mobile Number', Icons.phone, colorScheme),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    // Add validator for mandatory field
                    if (widget.isForcedCompletion &&
                        (value == null || value.isEmpty)) {
                      return 'Mobile Number cannot be empty';
                    }
                    // Optional: Add regex validation for mobile number format
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _aadhaarController,
                  decoration: _inputDecoration(
                      'Aadhaar Number', Icons.credit_card, colorScheme),
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  validator: (value) {
                    // Add validator for mandatory field
                    if (widget.isForcedCompletion &&
                        (value == null || value.isEmpty)) {
                      return 'Aadhaar Number cannot be empty';
                    }
                    if (value != null &&
                        value.isNotEmpty &&
                        value.length != 12) {
                      return 'Aadhaar Number must be 12 digits';
                    }
                    // Optional: Add more robust Aadhaar validation (e.g., checksum)
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          minimumSize: const Size(double.infinity, 55),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
