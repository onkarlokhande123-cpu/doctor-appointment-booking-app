import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/core/routes/auth_state_listenable.dart';
import 'package:appointment_booking_app/data/models/user_model.dart';
import 'package:appointment_booking_app/data/repositories/auth_repository.dart';
import 'package:appointment_booking_app/presentation/auth/cubit/auth_state.dart';
import 'package:appointment_booking_app/presentation/auth/cubit/auth_validators.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository authRepository,
    required AuthStateListenable authState,
  })  : _authRepository = authRepository,
        _authState = authState,
        super(const AuthState()) {
    _authSubscription = _authRepository.authStateChanges().listen(
          _onAuthStateChanged,
        );
    _restoreSession();
  }

  final AuthRepository _authRepository;
  final AuthStateListenable _authState;
  late final StreamSubscription<UserModel?> _authSubscription;

  Future<void> login({required String email, required String password}) async {
    final fieldErrors = <String, String>{};
    _addError(fieldErrors, 'email', AuthValidators.email(email));
    _addError(fieldErrors, 'password', AuthValidators.password(password));
    if (fieldErrors.isNotEmpty) {
      emit(AuthState(status: AuthStatus.failure, fieldErrors: fieldErrors));
      return;
    }

    emit(const AuthState(status: AuthStatus.loading));
    try {
      final user =
          await _authRepository.login(email: email, password: password);
      _authState.setUser(user);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on AuthRepositoryException catch (error) {
      emit(AuthState(status: AuthStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          errorMessage: 'Unable to sign in. Please try again.',
        ),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmation,
  }) async {
    final fieldErrors = <String, String>{};
    _addError(fieldErrors, 'name', AuthValidators.name(name));
    _addError(fieldErrors, 'email', AuthValidators.email(email));
    _addError(fieldErrors, 'phone', AuthValidators.mobileNumber(phone));
    _addError(fieldErrors, 'password', AuthValidators.password(password));
    _addError(
      fieldErrors,
      'confirmation',
      AuthValidators.confirmPassword(
        password: password,
        confirmation: confirmation,
      ),
    );
    if (fieldErrors.isNotEmpty) {
      emit(AuthState(status: AuthStatus.failure, fieldErrors: fieldErrors));
      return;
    }

    emit(const AuthState(status: AuthStatus.loading));
    try {
      final user = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      _authState.setUser(user);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on AuthRepositoryException catch (error) {
      emit(AuthState(status: AuthStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          errorMessage: 'Unable to create your account. Please try again.',
        ),
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final emailError = AuthValidators.email(email);
    if (emailError != null) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          fieldErrors: {'email': emailError},
        ),
      );
      return;
    }

    emit(const AuthState(status: AuthStatus.loading));
    try {
      await _authRepository.sendPasswordResetEmail(email);
      emit(
        const AuthState(
          status: AuthStatus.success,
          successMessage: 'Password-reset instructions have been sent.',
        ),
      );
    } on AuthRepositoryException catch (error) {
      emit(AuthState(status: AuthStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          errorMessage: 'Unable to process your request. Please try again.',
        ),
      );
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _authState.setUser(null);
    emit(const AuthState());
  }

  void clearFieldError(String field) {
    if (!state.fieldErrors.containsKey(field)) return;
    final errors = Map<String, String>.from(state.fieldErrors)..remove(field);
    emit(
      state.copyWith(
        status: AuthStatus.initial,
        fieldErrors: errors,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );
  }

  Future<void> _restoreSession() async {
    final user = await _authRepository.getCurrentUser();
    _authState.setUser(user);
    if (user != null && !isClosed) {
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    }
  }

  void _onAuthStateChanged(UserModel? user) {
    _authState.setUser(user);
    if (isClosed) return;
    emit(
      user == null
          ? const AuthState()
          : AuthState(status: AuthStatus.authenticated, user: user),
    );
  }

  static void _addError(
      Map<String, String> errors, String field, String? error) {
    if (error != null) errors[field] = error;
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }
}
