// lib/screens/user_profile.dart

import 'package:flutter/material.dart';
import 'package:line_survey_pro/models/user_profile.dart'; // Import the UserProfile model
import 'package:line_survey_pro/services/auth_service.dart'; // Import AuthService
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Import SnackBarUtils
import 'package:flutter/services.dart'; // Required for TextInputFormatter
import 'package:line_survey_pro/l10n/app_localizations.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileNumberController;
  late TextEditingController _aadhaarNumberController;

  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _displayNameController = TextEditingController();
    _emailController = TextEditingController();
    _mobileNumberController = TextEditingController();
    _aadhaarNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
    _aadhaarNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _userProfile = await _authService.getCurrentUserProfile();
      if (_userProfile != null) {
        _displayNameController.text = _userProfile!.displayName ?? '';
        _emailController.text = _userProfile!.email;
        _mobileNumberController.text = _userProfile!.mobileNumber ?? '';
        _aadhaarNumberController.text = _userProfile!.aadhaarNumber ?? '';
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error loading user profile: ${e.toString()}',
            isError: true);
      }
      print('Error loading user profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      try {
        final updatedProfile = _userProfile!.copyWith(
          displayName: _displayNameController.text.trim(),
          mobileNumber: _mobileNumberController.text.trim(),
          aadhaarNumber: _aadhaarNumberController.text
              .trim()
              .replaceAll('-', ''), // Remove hyphens for storage
        );

        // Call a new method in AuthService to update allowed fields
        await _authService.updateUserProfileFields(
            _userProfile!.id,
            updatedProfile.displayName,
            updatedProfile.mobileNumber,
            updatedProfile.aadhaarNumber);

        if (mounted) {
          SnackBarUtils.showSnackBar(context, 'Profile updated successfully!');
          // Refresh the profile to ensure latest data is displayed
          await _loadUserProfile();
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showSnackBar(
              context, 'Error updating profile: ${e.toString()}',
              isError: true);
        }
        print('Error updating user profile: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.userProfile)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.userProfile)),
        body: Center(
          child: Text(localizations.userProfileNotFound),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.userProfile),
        centerTitle: true,
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
              const SizedBox(height: 8),
              Text(
                'Please complete these details to proceed.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Display Name (from Google)
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name (from Google)',
                  prefixIcon: Icon(Icons.person, color: colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 20),
              // Email (from Google) - read-only
              TextFormField(
                controller: _emailController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email (from Google)',
                  prefixIcon: Icon(Icons.email, color: colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              // Mobile Number
              TextFormField(
                controller: _mobileNumberController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone, color: colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10, // Max 10 digits
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Allow only digits
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number.';
                  }
                  if (value.length != 10) {
                    return 'Mobile number must be 10 digits.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Aadhaar Number
              TextFormField(
                controller: _aadhaarNumberController,
                decoration: InputDecoration(
                  labelText: 'Aadhaar Number',
                  prefixIcon:
                      Icon(Icons.credit_card, color: colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  counterText: '', // Hide default counter
                ),
                keyboardType: TextInputType.number,
                maxLength: 19, // Max 19 characters (16 digits + 3 hyphens)
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Allow only digits
                  AadhaarInputFormatter(), // Custom formatter for hyphens
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Aadhaar number.';
                  }
                  final cleanedValue = value.replaceAll('-', '');
                  if (cleanedValue.length != 16) {
                    // Aadhaar numbers are 16 digits (as per user clarification)
                    return 'Aadhaar number must be 16 digits.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isSaving
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save),
                      label: Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom TextInputFormatter for Aadhaar Number to add hyphens
class AadhaarInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('-', ''); // Remove existing hyphens

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Build the new string with hyphens
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      // Add hyphen after every 4 digits, but not at the very end
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write('-');
      }
    }

    final String formattedText = buffer.toString();
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
