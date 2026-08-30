import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/core/constants/enums.dart';

/// Contract for creating, retrieving, and cancelling appointments.
///
/// Implementations are responsible for enforcing the core booking business
/// rules server-side (or in the mock, in-memory-side) so a client can never
/// bypass them:
///  - a time slot cannot be double-booked
///  - an appointment cannot be created in the past
///  - a generated [AppointmentModel.bookingId] must be unique
///  - a user must only ever receive their own appointments back
abstract class AppointmentRepository {
  /// Checks whether [timeSlotId] for [doctorId] is still free.
  /// Must be checked immediately before [createAppointment] to guard
  /// against a slot being booked by someone else in the meantime.
  Future<bool> isSlotAvailable({
    required String doctorId,
    required String timeSlotId,
  });

  /// Creates a new appointment. Implementations must:
  ///  1. Re-validate slot availability (see [isSlotAvailable]).
  ///  2. Reject dates in the past.
  ///  3. Generate a unique `bookingId` when [appointment.bookingId] is null.
  ///
  /// The returned, confirmed appointment always has a non-null, unique
  /// booking ID. Callers creating a booking request must not generate one.
  /// Throws an [Exception] describing the failure if any check fails.
  Future<AppointmentModel> createAppointment(AppointmentModel appointment);

  /// Cancels an existing appointment by [bookingId]. Implementations must
  /// set its status to cancelled rather than deleting it, so it still
  /// appears in appointment history.
  Future<void> cancelAppointment(String bookingId);

  /// Returns a single appointment's full detail.
  Future<AppointmentModel> getAppointmentById(String bookingId);

  /// Returns [userId]'s appointments with status `upcoming`, soonest first.
  Future<List<AppointmentModel>> getUpcomingAppointments(String userId);

  /// Returns [userId]'s appointments with status `completed` or
  /// `cancelled`, most recent first.
  Future<List<AppointmentModel>> getAppointmentHistory(String userId);

  /// Returns the appointments assigned to a separately provisioned doctor.
  /// Implementations must ensure the signed-in account owns [doctorId].
  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId);

  /// Lets the assigned doctor complete or cancel an upcoming appointment.
  /// Patient-controlled appointment fields must remain immutable.
  Future<void> updateDoctorAppointmentStatus({
    required String bookingId,
    required String doctorId,
    required AppointmentStatus status,
  });
}

/// Raised when a booking cannot be completed because its slot or appointment
/// state changed, or because the requested operation violates booking rules.
class BookingConflictException implements Exception {
  const BookingConflictException(this.message);

  final String message;

  @override
  String toString() => message;
}
