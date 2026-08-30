import 'package:appointment_booking_app/data/models/doctor_model.dart';
import 'package:appointment_booking_app/data/models/specialty_model.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  const HomeState({
    this.status = HomeStatus.initial,
    this.doctors = const [],
    this.specialties = const [],
    this.query = '',
    this.specialtyId,
    this.minRating,
    this.availableOnly = false,
    this.errorMessage,
  });

  final HomeStatus status;
  final List<DoctorModel> doctors;
  final List<SpecialtyModel> specialties;
  final String query;
  final String? specialtyId;
  final double? minRating;
  final bool availableOnly;
  final String? errorMessage;

  List<DoctorModel> get filteredDoctors {
    final normalizedQuery = query.trim().toLowerCase();
    return doctors.where((doctor) {
      final matchesQuery = normalizedQuery.isEmpty ||
          doctor.name.toLowerCase().contains(normalizedQuery) ||
          doctor.specialtyName.toLowerCase().contains(normalizedQuery);
      final matchesSpecialty =
          specialtyId == null || doctor.specialtyId == specialtyId;
      final matchesRating = minRating == null || doctor.rating >= minRating!;
      final matchesAvailability =
          !availableOnly || doctor.availableDays.isNotEmpty;
      return matchesQuery &&
          matchesSpecialty &&
          matchesRating &&
          matchesAvailability;
    }).toList();
  }

  HomeState copyWith({
    HomeStatus? status,
    List<DoctorModel>? doctors,
    List<SpecialtyModel>? specialties,
    String? query,
    String? specialtyId,
    double? minRating,
    bool? availableOnly,
    String? errorMessage,
    bool clearSpecialty = false,
    bool clearMinRating = false,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      doctors: doctors ?? this.doctors,
      specialties: specialties ?? this.specialties,
      query: query ?? this.query,
      specialtyId: clearSpecialty ? null : specialtyId ?? this.specialtyId,
      minRating: clearMinRating ? null : minRating ?? this.minRating,
      availableOnly: availableOnly ?? this.availableOnly,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
