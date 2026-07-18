import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final DateTime createdAt;
  final int totalScans;
  final DateTime lastLogin;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.totalScans,
    required this.lastLogin,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalScans: map['total_scans'] ?? 0,
      lastLogin: (map['last_login'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'created_at': Timestamp.fromDate(createdAt),
      'total_scans': totalScans,
      'last_login': Timestamp.fromDate(lastLogin),
    };
  }
}
