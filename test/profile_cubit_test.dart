import 'package:flutter_test/flutter_test.dart';

import 'package:appointment_booking_app/core/routes/auth_state_listenable.dart';
import 'package:appointment_booking_app/data/repositories/mock_auth_repository.dart';
import 'package:appointment_booking_app/presentation/auth/cubit/auth_cubit.dart';
import 'package:appointment_booking_app/presentation/auth/cubit/auth_state.dart';
import 'package:appointment_booking_app/presentation/profile/cubit/profile_cubit.dart';
import 'package:appointment_booking_app/presentation/profile/cubit/profile_state.dart';

void main() {
  late MockAuthRepository repository;
  late AuthStateListenable authState;
  late AuthCubit authCubit;

  setUp(() {
    repository = MockAuthRepository();
    authState = AuthStateListenable();
    authCubit = AuthCubit(authRepository: repository, authState: authState);
  });

  tearDown(() async {
    await authCubit.close();
    repository.dispose();
    authState.dispose();
  });

  test('ProfileCubit loads and updates the authenticated user profile',
      () async {
    await authCubit.register(
      name: 'Alex Patient',
      email: 'alex@example.com',
      phone: '9876543210',
      password: 'secure1',
      confirmation: 'secure1',
    );
    final profileCubit = ProfileCubit(
      authRepository: repository,
      user: authCubit.state.user!,
    );
    await _flush();

    expect(profileCubit.state.status, ProfileStatus.ready);
    expect(profileCubit.state.user?.email, 'alex@example.com');

    await profileCubit.save(
      name: 'Alexandra Patient',
      phone: '9988776655',
      profileImageUrl: 'https://example.com/avatar.png',
    );

    expect(profileCubit.state.status, ProfileStatus.success);
    expect(profileCubit.state.user?.name, 'Alexandra Patient');
    expect(profileCubit.state.user?.phone, '9988776655');
    expect((await repository.getCurrentUser())?.profileImageUrl,
        'https://example.com/avatar.png');

    await profileCubit.close();
  });

  test('ProfileCubit exposes validation errors for invalid edits', () async {
    await authCubit.register(
      name: 'Alex Patient',
      email: 'alex@example.com',
      phone: '9876543210',
      password: 'secure1',
      confirmation: 'secure1',
    );
    final profileCubit = ProfileCubit(
      authRepository: repository,
      user: authCubit.state.user!,
    );
    await _flush();

    await profileCubit.save(name: '', phone: '12', profileImageUrl: 'invalid');

    expect(profileCubit.state.status, ProfileStatus.failure);
    expect(
      profileCubit.state.fieldErrors.keys,
      containsAll(<String>['name', 'phone', 'image']),
    );
    await profileCubit.close();
  });

  test('logout clears auth state and current user', () async {
    await authCubit.register(
      name: 'Alex Patient',
      email: 'alex@example.com',
      phone: '9876543210',
      password: 'secure1',
      confirmation: 'secure1',
    );

    await authCubit.logout();

    expect(authState.isLoggedIn, isFalse);
    expect(authCubit.state.status, AuthStatus.initial);
    expect(authCubit.state.user, isNull);
    expect(await repository.getCurrentUser(), isNull);
  });
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);
