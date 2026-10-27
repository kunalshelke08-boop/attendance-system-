import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'student' or 'teacher'
  final String classId;
  final DateTime createdAt;
  final String subject; // teacher's subject (e.g. 'Cloud Computing')
  final bool needsNameSetup; // true if teacher hasn't set their name yet

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.classId,
    required this.createdAt,
    this.subject = '',
    this.needsNameSetup = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      classId: map['classId'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      subject: map['subject'] ?? '',
      needsNameSetup: map['needsNameSetup'] == true ||
          map['needsNameSetup'] == 'true',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'classId': classId,
      'createdAt': Timestamp.fromDate(createdAt),
      'subject': subject,
      'needsNameSetup': needsNameSetup,
    };
  }

  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? classId,
    DateTime? createdAt,
    String? subject,
    bool? needsNameSetup,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      classId: classId ?? this.classId,
      createdAt: createdAt ?? this.createdAt,
      subject: subject ?? this.subject,
      needsNameSetup: needsNameSetup ?? this.needsNameSetup,
    );
  }
}

