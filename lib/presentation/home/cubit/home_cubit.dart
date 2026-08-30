import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/data/repositories/doctor_repository.dart';
import 'package:appointment_booking_app/presentation/home/cubit/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required DoctorRepository doctorRepository})
      : _doctorRepository = doctorRepository,
        super(const HomeState()) {
    load();
  }

  final DoctorRepository _doctorRepository;

  Future<void> load() async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    try {
      final doctorsFuture = _doctorRepository.getAllDoctors();
      final specialtiesFuture = _doctorRepository.getAllSpecialties();
      final doctors = await doctorsFuture;
      final specialties = await specialtiesFuture;
      emit(
        state.copyWith(
          status: HomeStatus.success,
          doctors: doctors,
          specialties: specialties,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Unable to load doctors. Please try again.',
        ),
      );
    }
  }

  void search(String query) => emit(state.copyWith(query: query));

  void selectSpecialty(String? specialtyId) {
    emit(
      state.copyWith(
        specialtyId: specialtyId,
        clearSpecialty: specialtyId == null,
      ),
    );
  }

  void setMinimumRating(double? rating) {
    emit(
      state.copyWith(
        minRating: rating,
        clearMinRating: rating == null,
      ),
    );
  }

  void setAvailableOnly(bool value) =>
      emit(state.copyWith(availableOnly: value));

  void clearFilters() => emit(
        state.copyWith(
          clearSpecialty: true,
          clearMinRating: true,
          availableOnly: false,
        ),
      );
}
