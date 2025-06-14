// lib/models/user_profile.dart

class UserProfile {
  final String id;
  final String email;
  final String?
      role; // Made nullable to handle cases where role is not yet assigned
  final String? displayName;

  UserProfile({
    required this.id,
    required this.email,
    this.role, // No longer required in constructor
    this.displayName,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      role: map['role'] as String?, // Safely cast as nullable String
      displayName: map['displayName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role, // Will be null if not set
      'displayName': displayName,
    };
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, role: $role, displayName: $displayName)';
  }
}
