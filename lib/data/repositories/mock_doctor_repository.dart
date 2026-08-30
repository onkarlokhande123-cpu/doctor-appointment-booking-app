import 'package:appointment_booking_app/data/mock/mock_doctor_data.dart';
import 'package:appointment_booking_app/data/mock/mock_booking_store.dart';
import 'package:appointment_booking_app/data/models/doctor_model.dart';
import 'package:appointment_booking_app/data/models/specialty_model.dart';
import 'package:appointment_booking_app/data/models/time_slot_model.dart';
import 'package:appointment_booking_app/data/repositories/doctor_repository.dart';

/// In-memory doctor catalogue used until the Firebase data source is added.
class MockDoctorRepository implements DoctorRepository {
  MockDoctorRepository({required MockBookingStore bookingStore})
      : _bookingStore = bookingStore;

  final MockBookingStore _bookingStore;

  @override
  Future<List<DoctorModel>> filterDoctors({
    String? specialtyId,
    double? minRating,
  }) async {
    await _simulateRequest();
    return mockDoctors.where((doctor) {
      final matchesSpecialty =
          specialtyId == null || doctor.specialtyId == specialtyId;
      final matchesRating = minRating == null || doctor.rating >= minRating;
      return matchesSpecialty && matchesRating;
    }).toList();
  }

  @override
  Future<List<DoctorModel>> getAllDoctors() async {
    await _simulateRequest();
    return List<DoctorModel>.unmodifiable(mockDoctors);
  }

  @override
  Future<List<SpecialtyModel>> getAllSpecialties() async {
    await _simulateRequest();
    return List<SpecialtyModel>.unmodifiable(mockSpecialties);
  }

  @override
  Future<List<TimeSlotModel>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    await _simulateRequest();
    final doctor = await getDoctorById(doctorId);
    return _bookingStore.slotsFor(
      doctorId: doctorId,
      date: date,
      doctorIsAvailable: doctor.availableDays.contains(_weekdayName(date)),
    );
  }

  @override
  Future<DoctorModel> getDoctorById(String doctorId) async {
    await _simulateRequest();
    for (final doctor in mockDoctors) {
      if (doctor.id == doctorId) return doctor;
    }
    throw StateError('Doctor not found.');
  }

  @override
  Future<List<DoctorModel>> searchDoctors(String query) async {
    await _simulateRequest();
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return List<DoctorModel>.unmodifiable(mockDoctors);
    }
    return mockDoctors
        .where(
          (doctor) =>
              doctor.name.toLowerCase().contains(normalizedQuery) ||
              doctor.specialtyName.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  Future<void> _simulateRequest() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  String _weekdayName(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[date.weekday - 1];
  }
}
