// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:line_survey_pro/models/user_profile.dart'; // Ensure this is imported
import 'package:shared_preferences/shared_preferences.dart'; // NEW: Import shared_preferences
import 'dart:convert'; // For jsonEncode/jsonDecode

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // NEW: SharedPreferences key for user profile cache
  static const String _kUserProfileCacheKey = 'user_profile_cache';

  // NEW: Save UserProfile to SharedPreferences
  Future<void> _saveUserProfileToCache(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserProfileCacheKey,
        jsonEncode(profile.toMap())); // Convert map to JSON string
    print('User profile saved to cache: ${profile.email}');
  }

  // NEW: Load UserProfile from SharedPreferences
  Future<UserProfile?> _loadUserProfileFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? profileString = prefs.getString(_kUserProfileCacheKey);
      if (profileString != null) {
        // Parse string back to Map using jsonDecode for robustness.
        final Map<String, dynamic> map =
            Map<String, dynamic>.from(jsonDecode(profileString));
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
  // UPDATED to check cache first.
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      _clearUserProfileCache(); // Ensure cache is clear if no active user
      return null;
    }

    // Try to load from cache first
    UserProfile? cachedProfile = await _loadUserProfileFromCache();
    if (cachedProfile != null &&
        cachedProfile.id == user.uid &&
        cachedProfile.status == 'approved') {
      // If cached profile is for the current user and is approved, return it for quick access.
      // We still need to refresh from Firestore periodically to get latest role/assignedLines,
      // but for immediate UI display, this helps.
      // A background refresh or a timestamp check could be added here for staleness.
      print('Returning cached user profile for ${user.email}.');
      return cachedProfile;
    }

    // If no valid cached profile, fetch from Firestore
    try {
      final doc =
          await _firestore.collection('userProfiles').doc(user.uid).get();
      if (doc.exists) {
        final UserProfile fetchedProfile = UserProfile.fromMap(doc.data()!);
        await _saveUserProfileToCache(
            fetchedProfile); // Save fetched profile to cache
        return fetchedProfile;
      }
    } catch (e) {
      print('Error fetching user profile from Firestore: $e');
      // If Firestore fetch fails, maybe due to network, try to return cached profile if available but not approved
      if (cachedProfile != null && cachedProfile.id == user.uid) {
        print(
            'Firestore fetch failed, returning potentially stale cached profile.');
        return cachedProfile;
      }
    }
    return null;
  }

  // Ensures a user profile exists in Firestore. If it doesn't, creates a basic one with 'pending' status and no role.
  Future<void> ensureUserProfileExists(
      String uid, String email, String? displayName) async {
    final docRef = _firestore.collection('userProfiles').doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final newUserProfile = UserProfile(
        id: uid,
        email: email,
        displayName: displayName,
        role: null, // Role is deliberately NOT set here initially
        status: 'pending', // NEW: Account is pending approval by default
        assignedLineIds: [],
      );
      await docRef.set(newUserProfile.toMap());
      await _saveUserProfileToCache(newUserProfile); // Save to cache
      print('Created initial user profile for $email with pending status.');
    } else {
      final existingProfile = UserProfile.fromMap(doc.data()!);
      await _saveUserProfileToCache(
          existingProfile); // Ensure existing profile is cached/updated
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
  // Used for manager to select workers for task assignment.
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

  // NEW METHOD: Streams all user profiles from Firestore in real-time.
  // Used by Admin's User Management Screen.
  Stream<List<UserProfile>> streamAllUserProfiles() {
    return _firestore
        .collection('userProfiles')
        .orderBy('email', descending: false)
        .snapshots() // Provides real-time updates
        .map((snapshot) => snapshot.docs
            .map((doc) => UserProfile.fromMap(doc.data()))
            .toList())
        .handleError((e) {
      print('Error streaming all user profiles: $e');
    });
  }

  // NEW METHOD: Admin can update a user's role.
  Future<void> updateUserRole(String userId, String? newRole) async {
    try {
      await _firestore.collection('userProfiles').doc(userId).update({
        'role': newRole, // Can be 'Admin', 'Manager', 'Worker', or null
      });
      // After Firestore update, refresh cache for this user
      final updatedProfile =
          await getCurrentUserProfile(); // This will fetch and cache
      print('User $userId role updated to ${newRole ?? 'None'}.');
    } catch (e) {
      print('Error updating user $userId role: $e');
      rethrow;
    }
  }

  // NEW METHOD: Admin can update a user's account status.
  Future<void> updateUserStatus(String userId, String newStatus) async {
    try {
      await _firestore.collection('userProfiles').doc(userId).update({
        'status': newStatus, // Can be 'pending', 'approved', 'rejected'
      });
      // After Firestore update, refresh cache for this user
      final updatedProfile =
          await getCurrentUserProfile(); // This will fetch and cache
      print('User $userId status updated to $newStatus.');
    } catch (e) {
      print('Error updating user $userId status: $e');
      rethrow;
    }
  }

  // NEW METHOD: Admin can assign lines to a manager.
  Future<void> assignLinesToManager(
      String managerId, List<String> lineIds) async {
    try {
      await _firestore.collection('userProfiles').doc(managerId).update({
        'assignedLineIds': FieldValue.arrayUnion(lineIds),
      });
      // After Firestore update, refresh cache for this user
      final updatedProfile =
          await getCurrentUserProfile(); // This will fetch and cache
      print('Assigned lines to manager $managerId.');
    } catch (e) {
      print('Error assigning lines to manager $managerId: $e');
      rethrow;
    }
  }

  // NEW METHOD: Admin can unassign lines from a manager.
  Future<void> unassignLinesFromManager(
      String managerId, List<String> lineIds) async {
    try {
      await _firestore.collection('userProfiles').doc(managerId).update({
        'assignedLineIds': FieldValue.arrayRemove(lineIds),
      });
      // After Firestore update, refresh cache for this user
      final updatedProfile =
          await getCurrentUserProfile(); // This will fetch and cache
      print('Unassigned lines from manager $managerId.');
    } catch (e) {
      print('Error unassigning lines from manager $managerId: $e');
      rethrow;
    }
  }

  // NEW METHOD: Admin can delete a user's profile document from Firestore.
  // Note: Deleting the Firebase Authentication user account requires Admin SDK (server-side).
  // This method only deletes the Firestore profile document.
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestore.collection('userProfiles').doc(userId).delete();
      // If deleting current user's profile, clear cache
      if (_auth.currentUser?.uid == userId) {
        await _clearUserProfileCache();
      }
      print('User profile $userId deleted from Firestore.');
    } catch (e) {
      print('Error deleting user profile $userId: $e');
      rethrow;
    }
  }

  // Method for user logout
  // UPDATED to clear cache on signOut
  Future<void> signOut() async {
    await _auth.signOut();
    await _clearUserProfileCache(); // Clear cache on sign out
  }

  // Stream to listen to auth state changes
  Stream<User?> get userChanges => _auth.authStateChanges();
}
