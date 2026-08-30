import 'dart:async';

import 'package:appointment_booking_app/data/models/user_model.dart';
import 'package:appointment_booking_app/data/repositories/auth_repository.dart';

/// In-memory implementation used until Firebase authentication is introduced.
/// Data intentionally lasts only for the current app session.
class MockAuthRepository implements AuthRepository {
  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();
  final Map<String, String> _passwordsByEmail = {};
  final Map<String, UserModel> _usersByEmail = {};

  UserModel? _currentUser;

  String _emailKey(String email) => email.trim().toLowerCase();

  @override
  Stream<UserModel?> authStateChanges() => _authStateController.stream;

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await _simulateRequest();
    final key = _emailKey(email);
    final user = _usersByEmail[key];

    if (user == null || _passwordsByEmail[key] != password) {
      throw const AuthRepositoryException('Invalid email or password.');
    }

    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    await _simulateRequest();
    final key = _emailKey(email);
    if (_usersByEmail.containsKey(key)) {
      throw const AuthRepositoryException(
        'An account already exists for this email address.',
      );
    }

    final user = UserModel(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: key,
      phone: phone.trim(),
      createdAt: DateTime.now(),
    );
    _usersByEmail[key] = user;
    _passwordsByEmail[key] = password;
    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _simulateRequest();
    if (!_usersByEmail.containsKey(_emailKey(email))) {
      throw const AuthRepositoryException(
          'No account was found for this email.');
    }
  }

  @override
  Future<UserModel> updateProfile(UserModel updatedUser) async {
    final currentUser = _currentUser;
    if (currentUser == null || currentUser.id != updatedUser.id) {
      throw const AuthRepositoryException(
          'You must be signed in to edit a profile.');
    }

    final oldKey = _emailKey(currentUser.email);
    final newKey = _emailKey(updatedUser.email);
    if (oldKey != newKey && _usersByEmail.containsKey(newKey)) {
      throw const AuthRepositoryException(
        'An account already exists for this email address.',
      );
    }

    _usersByEmail.remove(oldKey);
    _usersByEmail[newKey] = updatedUser;
    final password = _passwordsByEmail.remove(oldKey);
    if (password != null) _passwordsByEmail[newKey] = password;
    _currentUser = updatedUser;
    _authStateController.add(updatedUser);
    return updatedUser;
  }

  Future<void> _simulateRequest() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  void dispose() => _authStateController.close();
}
