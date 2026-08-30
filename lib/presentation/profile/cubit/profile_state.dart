import 'package:appointment_booking_app/data/models/user_model.dart';

enum ProfileStatus { initial, loading, ready, saving, success, failure }

class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.fieldErrors = const {},
    this.errorMessage,
    this.successMessage,
  });

  final ProfileStatus status;
  final UserModel? user;
  final Map<String, String> fieldErrors;
  final String? errorMessage;
  final String? successMessage;

  bool get isSaving => status == ProfileStatus.saving;

  ProfileState copyWith({
    ProfileStatus? status,
    UserModel? user,
    Map<String, String>? fieldErrors,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}
