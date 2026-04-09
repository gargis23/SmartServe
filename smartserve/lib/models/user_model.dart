class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // student, staff, admin
  final List<String> dietaryPreferences;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.role = 'student',
    this.dietaryPreferences = const [],
  });

  // Convert Firebase Doc to User Object
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'student',
      dietaryPreferences: List<String>.from(map['dietaryPreferences'] ?? []),
    );
  }

  // Convert User Object to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'dietaryPreferences': dietaryPreferences,
    };
  }
}