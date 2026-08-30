import 'package:appointment_booking_app/core/constants/enums.dart';

/// Represents an authenticated app user.
///
/// Kept as a plain Dart class with no Flutter/Firebase imports so it can be
/// used identically by the mock data layer now and the Firebase data layer
/// later (Firestore documents map cleanly to/from this class).
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final DateTime createdAt;
  final UserRole role;

  /// Links a pre-provisioned doctor account to `doctors/{doctorId}`.
  final String? doctorId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    required this.createdAt,
    this.role = UserRole.patient,
    this.doctorId,
  });

  /// Returns a copy of this user with the given fields replaced.
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    DateTime? createdAt,
    UserRole? role,
    String? doctorId,
    bool clearDoctorId = false,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      doctorId: clearDoctorId ? null : doctorId ?? this.doctorId,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      role: UserRole.fromString(json['role'] as String?),
      doctorId: json['doctorId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'role': role.name,
      'doctorId': doctorId,
    };
  }
}
