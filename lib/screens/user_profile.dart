// lib/models/user_profile.dart

// Ensure this is imported for Timestamp if needed, though not directly used in UserProfile itself.

class UserProfile {
  final String id;
  final String email;
  String?
      role; // Made nullable to handle cases where role is not yet assigned (e.g., after initial signup)
  final String? displayName;
  // NEW: Added status for account approval workflow
  String status; // e.g., 'pending', 'approved', 'rejected'
  // NEW: Added field for lines assigned to a manager
  List<String> assignedLineIds; // Only relevant for Manager role

  UserProfile({
    required this.id,
    required this.email,
    this.role,
    this.displayName,
    this.status = 'pending', // Default status for new accounts
    this.assignedLineIds = const [], // Default empty list
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      role: map['role'] as String?, // Safely cast as nullable String
      displayName: map['displayName'] as String?,
      status: map['status'] as String? ??
          'pending', // Read status, default to 'pending' if not present
      assignedLineIds: List<String>.from(
          map['assignedLineIds'] ?? []), // Read assignedLineIds
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'displayName': displayName,
      'status': status,
      'assignedLineIds': assignedLineIds,
    };
  }

  // NEW: copyWith method for immutability and updating specific fields
  UserProfile copyWith({
    String? id,
    String? email,
    String? role,
    String? displayName,
    String? status,
    List<String>? assignedLineIds,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      assignedLineIds: assignedLineIds ?? this.assignedLineIds,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, role: $role, displayName: $displayName, status: $status, assignedLineIds: $assignedLineIds)';
  }
}
