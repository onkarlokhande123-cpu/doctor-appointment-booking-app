import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/data/mock/mock_booking_store.dart';
import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/data/repositories/appointment_repository.dart';

/// In-memory appointment repository with atomic mock-slot reservation.
class MockAppointmentRepository implements AppointmentRepository {
  MockAppointmentRepository({
    required MockBookingStore bookingStore,
    Iterable<AppointmentModel> initialAppointments = const [],
  })  : _bookingStore = bookingStore,
        _appointmentsById = {
          for (final appointment in initialAppointments)
            if (appointment.bookingId != null)
              appointment.bookingId!: appointment,
        };

  final MockBookingStore _bookingStore;
  final Map<String, AppointmentModel> _appointmentsById;
  int _bookingSequence = 0;

  @override
  Future<void> cancelAppointment(String bookingId) async {
    final appointment = _appointmentsById[bookingId];
    if (appointment == null) throw StateError('Appointment not found.');
    if (appointment.status != AppointmentStatus.upcoming) {
      throw const BookingConflictException(
        'Only upcoming appointments can be cancelled.',
      );
    }
    final cancelled = appointment.copyWith(status: AppointmentStatus.cancelled);
    _appointmentsById[bookingId] = cancelled;
    _bookingStore.release(appointment.timeSlotId);
  }

  @override
  Future<AppointmentModel> createAppointment(
      AppointmentModel appointment) async {
    if (_isPastDate(appointment.date)) {
      throw const BookingConflictException(
          'Appointments cannot be booked in the past.');
    }
    if (!_bookingStore.isAvailable(
      doctorId: appointment.doctorId,
      timeSlotId: appointment.timeSlotId,
    )) {
      throw const BookingConflictException(
          'This time slot is no longer available.');
    }

    if (appointment.bookingId != null &&
        _appointmentsById.containsKey(appointment.bookingId)) {
      throw const BookingConflictException(
          'This booking ID is already in use.');
    }

    // Reservation happens before the appointment is stored, so concurrent
    // callers cannot create two records for the same mock slot.
    _bookingStore.reserve(
      doctorId: appointment.doctorId,
      timeSlotId: appointment.timeSlotId,
      userId: appointment.userId,
    );
    final bookingId = appointment.bookingId ?? _nextBookingId();
    final confirmed = AppointmentModel(
      bookingId: bookingId,
      userId: appointment.userId,
      doctorId: appointment.doctorId,
      doctorName: appointment.doctorName,
      doctorImageUrl: appointment.doctorImageUrl,
      date: appointment.date,
      timeSlotId: appointment.timeSlotId,
      startTime: appointment.startTime,
      endTime: appointment.endTime,
      patientName: appointment.patientName,
      patientEmail: appointment.patientEmail,
      patientAge: appointment.patientAge,
      patientGender: appointment.patientGender,
      patientPhone: appointment.patientPhone,
      reason: appointment.reason,
      fee: appointment.fee,
      status: AppointmentStatus.upcoming,
      createdAt: DateTime.now(),
    );
    _appointmentsById[bookingId] = confirmed;
    return confirmed;
  }

  @override
  Future<AppointmentModel> getAppointmentById(String bookingId) async {
    final appointment = _appointmentsById[bookingId];
    if (appointment == null) throw StateError('Appointment not found.');
    return appointment;
  }

  @override
  Future<List<AppointmentModel>> getAppointmentHistory(String userId) async {
    final history = _appointmentsById.values
        .where(
          (appointment) =>
              appointment.userId == userId &&
              (appointment.status == AppointmentStatus.completed ||
                  appointment.status == AppointmentStatus.cancelled),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return history;
  }

  @override
  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) async {
    final appointments = _appointmentsById.values
        .where((appointment) => appointment.doctorId == doctorId)
        .toList()
      ..sort((first, second) => first.date.compareTo(second.date));
    return appointments;
  }

  @override
  Future<List<AppointmentModel>> getUpcomingAppointments(String userId) async {
    final today = DateTime.now();
    final upcoming = _appointmentsById.values
        .where(
          (appointment) =>
              appointment.userId == userId &&
              appointment.status == AppointmentStatus.upcoming &&
              !_isPastDate(appointment.date, now: today),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming;
  }

  @override
  Future<bool> isSlotAvailable({
    required String doctorId,
    required String timeSlotId,
  }) async =>
      _bookingStore.isAvailable(doctorId: doctorId, timeSlotId: timeSlotId);

  @override
  Future<void> updateDoctorAppointmentStatus({
    required String bookingId,
    required String doctorId,
    required AppointmentStatus status,
  }) async {
    final appointment = _appointmentsById[bookingId];
    if (appointment == null || appointment.doctorId != doctorId) {
      throw StateError('Appointment not found.');
    }
    if (appointment.status != AppointmentStatus.upcoming) {
      throw const BookingConflictException(
        'Only upcoming appointments can be updated.',
      );
    }
    if (status == AppointmentStatus.completed && !_hasStarted(appointment)) {
      throw const BookingConflictException(
        'An appointment can only be completed after its scheduled time.',
      );
    }
    if (status != AppointmentStatus.completed &&
        status != AppointmentStatus.cancelled) {
      throw const BookingConflictException('Unsupported appointment status.');
    }
    _appointmentsById[bookingId] = appointment.copyWith(status: status);
    if (status == AppointmentStatus.cancelled) {
      _bookingStore.release(appointment.timeSlotId);
    }
  }

  String _nextBookingId() {
    _bookingSequence += 1;
    return 'BK${DateTime.now().microsecondsSinceEpoch}$_bookingSequence';
  }

  bool _isPastDate(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return DateTime(date.year, date.month, date.day).isBefore(
      DateTime(today.year, today.month, today.day),
    );
  }

  bool _hasStarted(AppointmentModel appointment) {
    final parts = appointment.startTime.split(' ');
    if (parts.length != 2) return !appointment.date.isAfter(DateTime.now());
    final time = parts.first.split(':');
    if (time.length != 2) return !appointment.date.isAfter(DateTime.now());
    var hour = int.tryParse(time[0]) ?? 0;
    final minute = int.tryParse(time[1]) ?? 0;
    final period = parts.last.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    final scheduled = DateTime(
      appointment.date.year,
      appointment.date.month,
      appointment.date.day,
      hour,
      minute,
    );
    return !scheduled.isAfter(DateTime.now());
  }
}
