import 'package:appointment_booking_app/data/models/doctor_model.dart';
import 'package:appointment_booking_app/data/models/specialty_model.dart';
import 'package:appointment_booking_app/data/models/time_slot_model.dart';

/// Contract for browsing doctors, specialties, and slot availability.
abstract class DoctorRepository {
  /// Returns every doctor available for booking.
  Future<List<DoctorModel>> getAllDoctors();

  /// Returns a single doctor's full profile.
  /// Throws if no doctor exists with [doctorId].
  Future<DoctorModel> getDoctorById(String doctorId);

  /// Returns doctors whose name or specialty matches [query]
  /// (case-insensitive). Returns an empty list if nothing matches —
  /// callers render this as an empty state, not an error.
  Future<List<DoctorModel>> searchDoctors(String query);

  /// Returns doctors matching the given filters. Passing null for a filter
  /// means "don't filter on this field".
  Future<List<DoctorModel>> filterDoctors({
    String? specialtyId,
    double? minRating,
  });

  /// Returns all specialty categories, used to populate filter chips/lists.
  Future<List<SpecialtyModel>> getAllSpecialties();

  /// Returns the time slots for [doctorId] on [date], including both
  /// booked and free slots — the caller decides how to render each state.
  Future<List<TimeSlotModel>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  });
}
