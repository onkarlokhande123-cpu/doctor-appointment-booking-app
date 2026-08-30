import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/data/models/user_model.dart';
import 'package:appointment_booking_app/data/repositories/auth_repository.dart';
import 'package:appointment_booking_app/presentation/auth/cubit/auth_validators.dart';
import 'package:appointment_booking_app/presentation/profile/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required AuthRepository authRepository,
    required UserModel user,
  })  : _authRepository = authRepository,
        _userId = user.id,
        super(ProfileState(user: user)) {
    load();
  }

  final AuthRepository _authRepository;
  final String _userId;

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null || user.id != _userId) {
        throw const AuthRepositoryException('Profile is no longer available.');
      }
      emit(state.copyWith(status: ProfileStatus.ready, user: user));
    } on AuthRepositoryException catch (error) {
      emit(
        state.copyWith(
            status: ProfileStatus.failure, errorMessage: error.message),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'Unable to load your profile. Please try again.',
        ),
      );
    }
  }

  Future<void> save({
    required String name,
    required String phone,
    String? profileImageUrl,
  }) async {
    final errors = <String, String>{};
    final nameError = AuthValidators.name(name);
    final phoneError = AuthValidators.mobileNumber(phone);
    if (nameError != null) errors['name'] = nameError;
    if (phoneError != null) errors['phone'] = phoneError;
    if (profileImageUrl != null && profileImageUrl.trim().isNotEmpty) {
      final imageUri = Uri.tryParse(profileImageUrl.trim());
      if (imageUri == null || !imageUri.hasScheme || imageUri.host.isEmpty) {
        errors['image'] = 'Enter a valid image URL.';
      }
    }
    if (errors.isNotEmpty) {
      emit(state.copyWith(status: ProfileStatus.failure, fieldErrors: errors));
      return;
    }

    final user = state.user;
    if (user == null) return;
    emit(
      state.copyWith(
        status: ProfileStatus.saving,
        fieldErrors: const {},
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      final updated = await _authRepository.updateProfile(
        user.copyWith(
          name: name.trim(),
          phone: phone.trim(),
          profileImageUrl: profileImageUrl?.trim(),
        ),
      );
      emit(
        ProfileState(
          status: ProfileStatus.success,
          user: updated,
          successMessage: 'Profile updated successfully.',
        ),
      );
    } on AuthRepositoryException catch (error) {
      emit(
        state.copyWith(
            status: ProfileStatus.failure, errorMessage: error.message),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'Unable to save your profile. Please try again.',
        ),
      );
    }
  }
}
