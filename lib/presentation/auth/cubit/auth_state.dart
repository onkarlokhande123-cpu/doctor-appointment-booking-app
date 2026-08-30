import 'package:appointment_booking_app/data/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  success,
  failure,
}

/// Immutable UI state for all authentication actions.
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.fieldErrors = const {},
    this.errorMessage,
    this.successMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  final Map<String, String> fieldErrors;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    Map<String, String>? fieldErrors,
    String? errorMessage,
    String? successMessage,
    bool clearUser = false,
    bool clearErrorMessage = false,
    bool clearSuccessMessage = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccessMessage ? null : successMessage ?? this.successMessage,
    );
  }
}
