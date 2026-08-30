import 'package:flutter_test/flutter_test.dart';

import 'package:appointment_booking_app/core/routes/auth_state_listenable.dart';
import 'package:appointment_booking_app/data/repositories/mock_auth_repository.dart';
import 'package:appointment_booking_app/presentation/auth/cubit/auth_cubit.dart';
import 'package:appointment_booking_app/presentation/auth/cubit/auth_state.dart';

void main() {
  test('registration authenticates the user and updates router auth state',
      () async {
    final authState = AuthStateListenable();
    final repository = MockAuthRepository();
    final cubit = AuthCubit(
      authRepository: repository,
      authState: authState,
    );

    await cubit.register(
      name: 'Alex Patient',
      email: 'alex@example.com',
      phone: '9876543210',
      password: 'secure1',
      confirmation: 'secure1',
    );

    expect(cubit.state.status, AuthStatus.authenticated);
    expect(authState.isLoggedIn, isTrue);
    expect((await repository.getCurrentUser())?.email, 'alex@example.com');

    await cubit.close();
    repository.dispose();
    authState.dispose();
  });

  test('invalid registration exposes field-level validation errors', () async {
    final authState = AuthStateListenable();
    final repository = MockAuthRepository();
    final cubit = AuthCubit(
      authRepository: repository,
      authState: authState,
    );

    await cubit.register(
      name: '',
      email: 'invalid',
      phone: '123',
      password: '123',
      confirmation: 'different',
    );

    expect(cubit.state.status, AuthStatus.failure);
    expect(
        cubit.state.fieldErrors.keys,
        containsAll(<String>[
          'name',
          'email',
          'phone',
          'password',
          'confirmation',
        ]));
    expect(authState.isLoggedIn, isFalse);

    await cubit.close();
    repository.dispose();
    authState.dispose();
  });

  test('an unauthenticated repository event clears router and Cubit state',
      () async {
    final authState = AuthStateListenable();
    final repository = MockAuthRepository();
    final cubit = AuthCubit(
      authRepository: repository,
      authState: authState,
    );

    await cubit.register(
      name: 'Alex Patient',
      email: 'alex@example.com',
      phone: '9876543210',
      password: 'secure1',
      confirmation: 'secure1',
    );
    await repository.logout();
    await Future<void>.delayed(Duration.zero);

    expect(authState.isLoggedIn, isFalse);
    expect(cubit.state.status, AuthStatus.initial);
    expect(cubit.state.user, isNull);

    await cubit.close();
    repository.dispose();
    authState.dispose();
  });
}
