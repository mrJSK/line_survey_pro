// lib/services/auth_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:line_survey_pro/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _kUserProfileCacheKey = 'user_profile_cache';

  final StreamController<UserProfile?> _userProfileStreamController =
      StreamController<UserProfile?>.broadcast();

  Stream<UserProfile?> get userProfileStream =>
      _userProfileStreamController.stream;

  AuthService() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        final profile = await getCurrentUserProfile(forceFetch: true);
        _userProfileStreamController.add(profile);
      } else {
        await _clearUserProfileCache();
        _userProfileStreamController.add(null);
      }
    });
    _loadUserProfileFromCache().then((profile) {
      if (profile != null) {
        _userProfileStreamController.add(profile);
      }
    });
  }

  Future<void> _saveUserProfileToCache(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserProfileCacheKey, jsonEncode(profile.toMap()));
    print('User profile saved to cache: ${profile.email}');
  }

  Future<UserProfile?> _loadUserProfileFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? profileString = prefs.getString(_kUserProfileCacheKey);
      if (profileString != null && profileString.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(profileString);
        print('User profile loaded from cache: ${map['email']}');
        return UserProfile.fromMap(map);
      }
    } catch (e) {
      print('Error loading user profile from cache: $e');
      _clearUserProfileCache();
    }
    return null;
  }

  Future<void> _clearUserProfileCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserProfileCacheKey);
    print('User profile cache cleared.');
  }

  Future<UserProfile?> getCurrentUserProfile({bool forceFetch = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _clearUserProfileCache();
      return null;
    }

    if (!forceFetch) {
      UserProfile? cachedProfile = await _loadUserProfileFromCache();
      if (cachedProfile != null &&
          cachedProfile.id == user.uid &&
          cachedProfile.status == 'approved') {
        print('Returning cached user profile for ${user.email}.');
        return cachedProfile;
      }
    }

    try {
      final doc =
          await _firestore.collection('userProfiles').doc(user.uid).get();
      if (doc.exists) {
        final UserProfile fetchedProfile = UserProfile.fromMap(doc.data()!);
        await _saveUserProfileToCache(fetchedProfile);
        _userProfileStreamController.add(fetchedProfile);
        return fetchedProfile;
      }
    } catch (e) {
      print('Error fetching user profile from Firestore: $e');
      if (!forceFetch) {
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
      );
      await docRef.set(newUserProfile.toMap());
      await _saveUserProfileToCache(newUserProfile);
      _userProfileStreamController.add(newUserProfile);
      print('Created initial user profile for $email with pending status.');
    } else {
      final existingProfile = UserProfile.fromMap(doc.data()!);
      await _saveUserProfileToCache(existingProfile);
      _userProfileStreamController.add(existingProfile);
      print('User profile for $email already exists.');
    }
  }

  // NEW/RE-ADDED: Method to update a user's profile from the app (e.g., from UserProfileScreen)
  Future<void> updateUserProfile(UserProfile userProfile) async {
    try {
      await _firestore.collection('userProfiles').doc(userProfile.id).set(
          userProfile.toMap(),
          SetOptions(
              merge: true)); // Use merge: true to only update provided fields
      await getCurrentUserProfile(
          forceFetch: true); // Force fetch and update cache/stream
      print('User profile ${userProfile.id} updated in Firestore.');
    } catch (e) {
      print('Error updating user profile ${userProfile.id}: $e');
      rethrow;
    }
  }

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

  User? getCurrentUser() {
    return _auth.currentUser;
  }

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

  Future<void> updateUserRole(String userId, String? newRole) async {
    try {
      await _firestore.collection('userProfiles').doc(userId).update({
        'role': newRole,
      });
      await getCurrentUserProfile(forceFetch: true);
      print('User $userId role updated to ${newRole ?? 'None'}.');
    } catch (e) {
      print('Error updating user $userId role: $e');
      rethrow;
    }
  }

  Future<void> updateUserStatus(String userId, String newStatus) async {
    try {
      await _firestore.collection('userProfiles').doc(userId).update({
        'status': newStatus,
      });
      await getCurrentUserProfile(forceFetch: true);
      print('User $userId status updated to $newStatus.');
    } catch (e) {
      print('Error updating user $userId status: $e');
      rethrow;
    }
  }

  Future<void> assignLinesToManager(
      String managerId, List<String> lineIds) async {
    try {
      await _firestore.collection('userProfiles').doc(managerId).update({
        'assignedLineIds': FieldValue.arrayUnion(lineIds),
      });
      await getCurrentUserProfile(forceFetch: true);
      print('Assigned lines to manager $managerId.');
    } catch (e) {
      print('Error assigning lines to manager $managerId: $e');
      rethrow;
    }
  }

  Future<void> unassignLinesFromManager(
      String managerId, List<String> lineIds) async {
    try {
      await _firestore.collection('userProfiles').doc(managerId).update({
        'assignedLineIds': FieldValue.arrayRemove(lineIds),
      });
      await getCurrentUserProfile(forceFetch: true);
      print('Unassigned lines from manager $managerId.');
    } catch (e) {
      print('Error unassigning lines from manager $managerId: $e');
      rethrow;
    }
  }

  Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestore.collection('userProfiles').doc(userId).delete();
      if (_auth.currentUser?.uid == userId) {
        await _clearUserProfileCache();
      }
      _userProfileStreamController.add(null);
      print('User profile $userId deleted from Firestore.');
    } catch (e) {
      print('Error deleting user profile $userId: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _clearUserProfileCache();
    _userProfileStreamController.add(null);
  }

  Stream<User?> get userChanges => _auth.authStateChanges();
}
