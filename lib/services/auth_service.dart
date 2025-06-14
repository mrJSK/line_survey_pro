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

  // Ensures a user profile exists in Firestore. If it doesn't, creates a basic one without a role.
  Future<void> ensureUserProfileExists(
      String uid, String email, String? displayName) async {
    final docRef = _firestore.collection('userProfiles').doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'id': uid,
        'email': email,
        'displayName': displayName,
        // Role is deliberately NOT set here. It will be assigned by an admin.
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Created initial user profile for $email without a role.');
    } else {
      print('User profile for $email already exists.');
    }
  }

  // Placeholder method for user login (you'll implement actual login logic here)
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    // This is where you'd add try-catch for Firebase errors, etc.
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  // Method for traditional email/password registration.
  // This will create a Firebase Auth user AND then call ensureUserProfileExists
  // to set up their Firestore profile with a default 'Worker' role.
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      if (userCredential.user != null) {
        // For new email/password users, create their profile with a default 'Worker' role.
        // You might consider 'Pending' here if you want admin approval for all registrations.
        await createUserProfileInFirestore(userCredential.user!.uid, email,
            'Worker', userCredential.user!.displayName);
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

  // Method to create/update a user's profile in Firestore with a specified role.
  // This method is intended for use by an admin/backend process.
  // It uses merge: true to ensure it updates existing fields without overwriting the entire document.
  Future<void> createUserProfileInFirestore(
      String uid, String email, String role, String? displayName) async {
    try {
      await _firestore.collection('userProfiles').doc(uid).set(
          {
            'id': uid,
            'email': email,
            'role': role, // Role is explicitly set here
            'displayName': displayName,
          },
          SetOptions(
              merge: true)); // Use merge: true to update existing document
    } catch (e) {
      print('Error creating/updating user profile in Firestore: $e');
      rethrow;
    }
  }

  // NEW METHOD: Fetches all user profiles from Firestore.
  // This is used by the manager to see available workers.
  Future<List<UserProfile>> getAllUserProfiles() async {
    try {
      final querySnapshot = await _firestore.collection('userProfiles').get();
      return querySnapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching all user profiles: $e');
      rethrow; // Re-throw the error to be handled by the UI
    }
  }

  // Method for user logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Stream to listen to auth state changes
  Stream<User?> get userChanges => _auth.authStateChanges();
}
