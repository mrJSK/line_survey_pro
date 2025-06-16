// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:line_survey_pro/models/user_profile.dart'; // Ensure this is imported

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetches the current user's profile from Firestore.
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc =
          await _firestore.collection('userProfiles').doc(user.uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
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
      await docRef.set({
        'id': uid,
        'email': email,
        'displayName': displayName,
        'role': null, // Role is deliberately NOT set here initially
        'status': 'pending', // NEW: Account is pending approval by default
        'createdAt': FieldValue.serverTimestamp(),
        'assignedLineIds': [], // NEW: Initialize assigned lines for managers
      });
      print('Created initial user profile for $email with pending status.');
    } else {
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
        // Upon registration, ensure profile exists with 'pending' status
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
      print('User profile $userId deleted from Firestore.');
    } catch (e) {
      print('Error deleting user profile $userId: $e');
      rethrow;
    }
  }

  // Method for user logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Stream to listen to auth state changes
  Stream<User?> get userChanges => _auth.authStateChanges();
}
