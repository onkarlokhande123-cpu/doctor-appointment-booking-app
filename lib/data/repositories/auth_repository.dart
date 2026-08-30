import 'package:appointment_booking_app/data/models/user_model.dart';

/// Contract for authentication and profile management.
///
/// This is intentionally UI-independent and Firebase-independent — a mock
/// implementation will back it now, and a Firebase Auth implementation will
/// replace it later without any change to callers (Cubits/BLoCs).
abstract class AuthRepository {
  /// Registers a new user and returns the created profile.
  /// Throws an [Exception] (or subtype) if the email is already in use or
  /// input is invalid — callers are responsible for catching and mapping
  /// this to an error state.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  });

  /// Logs in an existing user. Throws if credentials are invalid.
  Future<UserModel> login({
    required String email,
    required String password,
  });

  /// Logs out the current user and clears any stored session.
  Future<void> logout();

  /// Returns the currently signed-in user, or null if no one is signed in.
  Future<UserModel?> getCurrentUser();

  /// Emits the current user whenever auth state changes (login/logout).
  /// Used to drive route redirects (e.g. via go_router's refreshListenable).
  Stream<UserModel?> authStateChanges();

  /// Starts the password-reset flow for [email]. A mock implementation only
  /// confirms the request; a Firebase implementation will send the email.
  Future<void> sendPasswordResetEmail(String email);

  /// Updates and persists profile fields for the current user.
  Future<UserModel> updateProfile(UserModel updatedUser);
}

/// Expected authentication failure that can be safely shown to the user.
class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
