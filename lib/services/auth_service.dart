// lib/services/auth_service.dart

import 'dart:convert'; // NEW: For jsonEncode/jsonDecode
import 'dart:async'; // NEW: For StreamController
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:line_survey_pro/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // NEW: SharedPreferences key for user profile cache
  static const String _kUserProfileCacheKey = 'user_profile_cache';

  // NEW: StreamController for UserProfile changes
  final StreamController<UserProfile?> _userProfileStreamController =
      StreamController<UserProfile?>.broadcast();

  // NEW: Expose the user profile stream
  Stream<UserProfile?> get userProfileStream =>
      _userProfileStreamController.stream;

  // Constructor: Initialize the stream with the current profile on app start
  AuthService() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        // Fetch and add to stream
        final profile = await getCurrentUserProfile(
            forceFetch: true); // Force fetch on auth change
        _userProfileStreamController.add(profile);
      } else {
        // Clear cache and stream null on sign out
        await _clearUserProfileCache();
        _userProfileStreamController.add(null);
      }
    });
    // Attempt to load and add cached profile on initialization
    _loadUserProfileFromCache().then((profile) {
      if (profile != null) {
        _userProfileStreamController.add(profile);
      }
    });
  }

  // NEW: Save UserProfile to SharedPreferences
  Future<void> _saveUserProfileToCache(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kUserProfileCacheKey, jsonEncode(profile.toMap())); // Use jsonEncode
    print('User profile saved to cache: ${profile.email}');
  }

  // NEW: Load UserProfile from SharedPreferences
  Future<UserProfile?> _loadUserProfileFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? profileString = prefs.getString(_kUserProfileCacheKey);
      if (profileString != null && profileString.isNotEmpty) {
        final Map<String, dynamic> map =
            jsonDecode(profileString); // Use jsonDecode
        print('User profile loaded from cache: ${map['email']}');
        return UserProfile.fromMap(map);
      }
    } catch (e) {
      print('Error loading user profile from cache: $e');
      _clearUserProfileCache(); // Clear corrupted cache
    }
    return null;
  }

  // NEW: Clear UserProfile from SharedPreferences
  Future<void> _clearUserProfileCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserProfileCacheKey);
    print('User profile cache cleared.');
  }

  // Fetches the current user's profile from Firestore.
  // UPDATED to check cache first and optionally force fetch.
  Future<UserProfile?> getCurrentUserProfile({bool forceFetch = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _clearUserProfileCache();
      return null;
    }

    if (!forceFetch) {
      // Try to load from cache first if not forcing a fetch
      UserProfile? cachedProfile = await _loadUserProfileFromCache();
      if (cachedProfile != null &&
          cachedProfile.id == user.uid &&
          cachedProfile.status == 'approved') {
        print('Returning cached user profile for ${user.email}.');
        return cachedProfile;
      }
    }

    // If no valid cached profile or forcing fetch, fetch from Firestore
    try {
      final doc =
          await _firestore.collection('userProfiles').doc(user.uid).get();
      if (doc.exists) {
        final UserProfile fetchedProfile = UserProfile.fromMap(doc.data()!);
        await _saveUserProfileToCache(
            fetchedProfile); // Save fetched profile to cache
        _userProfileStreamController.add(fetchedProfile); // Add to stream
        return fetchedProfile;
      }
    } catch (e) {
      print('Error fetching user profile from Firestore: $e');
      // If Firestore fetch fails, maybe due to network, try to return cached profile if available but not approved
      if (!forceFetch) {
        // Only fallback to cache if not explicitly forcing a fetch
        UserProfile? cachedProfile = await _loadUserProfileFromCache();
        if (cachedProfile != null && cachedProfile.id == user.uid) {
          print(
              'Firestore fetch failed, returning potentially stale cached profile.');
          return cachedProfile;
        }
      }
    }
    return null;
  }

  // Ensures a user profile exists in Firestore.
  Future<void> ensureUserProfileExists(
      String uid, String email, String? displayName) async {
    final docRef = _firestore.collection('userProfiles').doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final newUserProfile = UserProfile(
        id: uid,
        email: email,
        displayName: displayName,
        role: null,
        status: 'pending',
        assignedLineIds: [],
        // ADDED: Initialize new fields as null
        mobileNumber: null,
        aadhaarNumber: null,
      );
      await docRef.set(newUserProfile.toMap());
      await _saveUserProfileToCache(newUserProfile); // Save to cache
      _userProfileStreamController.add(newUserProfile); // Add to stream
      print('Created initial user profile for $email with pending status.');
    } else {
      final existingProfile = UserProfile.fromMap(doc.data()!);
      await _saveUserProfileToCache(
          existingProfile); // Ensure existing profile is cached/updated
      _userProfileStreamController.add(existingProfile); // Add to stream
      print('User profile for $email already exists.');
    }
  }

  // Method for traditional email/password registration.
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      if (userCredential.user != null) {
        await ensureUserProfileExists(
            userCredential.user!.uid, email, userCredential.user!.displayName);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during registration: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error during registration: $e');
      rethrow;
    }
  }

  // Method to get the current Firebase User object.
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Fetches all user profiles from Firestore (one-time get).
  Future<List<UserProfile>> getAllUserProfiles() async {
    try {
      final querySnapshot = await _firestore.collection('userProfiles').get();
      return querySnapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching all user profiles: $e');
      rethrow;
    }
  }

  // Streams all user profiles from Firestore in real-time.
  Stream<List<UserProfile>> streamAllUserProfiles() {
    return _firestore
        .collection('userProfiles')
        .orderBy('email', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserProfile.fromMap(doc.data()))
            .toList())
        .handleError((e) {
      print('Error streaming all user profiles: $e');
    });
  }

  // Admin can update a user's role.
  Future<void> updateUserRole(String userId, String? newRole) async {
    try {
      await _firestore.collection('userProfiles').doc(userId).update({
        'role': newRole,
      });
      await getCurrentUserProfile(
          forceFetch: true); // Force fetch and update cache/stream
      print('User $userId role updated to ${newRole ?? 'None'}.');
    } catch (e) {
      print('Error updating user $userId role: $e');
      rethrow;
    }
  }

  // Admin can update a user's account status.
  Future<void> updateUserStatus(String userId, String newStatus) async {
    try {
      await _firestore.collection('userProfiles').doc(userId).update({
        'status': newStatus,
      });
      await getCurrentUserProfile(
          forceFetch: true); // Force fetch and update cache/stream
      print('User $userId status updated to $newStatus.');
    } catch (e) {
      print('Error updating user $userId status: $e');
      rethrow;
    }
  }

  // NEW METHOD: Allows users to update only their own non-sensitive fields.
  Future<void> updateUserProfileFields(String userId, String? displayName,
      String? mobileNumber, String? aadhaarNumber) async {
    try {
      await _firestore.collection('userProfiles').doc(userId).update({
        'displayName': displayName,
        'mobileNumber': mobileNumber,
        'aadhaarNumber': aadhaarNumber,
      });
      await getCurrentUserProfile(
          forceFetch: true); // Force fetch and update cache/stream
      print(
          'User $userId profile fields (displayName, mobile, aadhaar) updated.');
    } catch (e) {
      print('Error updating user $userId profile fields: $e');
      rethrow;
    }
  }

  // Admin can assign lines to a manager.
  Future<void> assignLinesToManager(
      String managerId, List<String> lineIds) async {
    try {
      await _firestore.collection('userProfiles').doc(managerId).update({
        'assignedLineIds': FieldValue.arrayUnion(lineIds),
      });
      await getCurrentUserProfile(
          forceFetch: true); // Force fetch and update cache/stream
      print('Assigned lines to manager $managerId.');
    } catch (e) {
      print('Error assigning lines to manager $managerId: $e');
      rethrow;
    }
  }

  // Admin can unassign lines from a manager.
  Future<void> unassignLinesFromManager(
      String managerId, List<String> lineIds) async {
    try {
      await _firestore.collection('userProfiles').doc(managerId).update({
        'assignedLineIds': FieldValue.arrayRemove(lineIds),
      });
      await getCurrentUserProfile(
          forceFetch: true); // Force fetch and update cache/stream
      print('Unassigned lines from manager $managerId.');
    } catch (e) {
      print('Error unassigning lines from manager $managerId: $e');
      rethrow;
    }
  }

  // Admin can delete a user's profile document from Firestore.
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestore.collection('userProfiles').doc(userId).delete();
      if (_auth.currentUser?.uid == userId) {
        await _clearUserProfileCache(); // Clear cache if current user's profile deleted
      }
      _userProfileStreamController.add(null); // Emit null if profile deleted
      print('User profile $userId deleted from Firestore.');
    } catch (e) {
      print('Error deleting user profile $userId: $e');
      rethrow;
    }
  }

  // Method for user logout
  Future<void> signOut() async {
    await _auth.signOut();
    await _clearUserProfileCache(); // Clear cache on sign out
    _userProfileStreamController.add(null); // Emit null when signed out
  }

  // Stream to listen to Firebase auth state changes (used by root widget)
  Stream<User?> get userChanges => _auth.authStateChanges();
}
