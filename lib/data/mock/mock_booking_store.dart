import 'package:appointment_booking_app/data/models/time_slot_model.dart';
import 'package:appointment_booking_app/data/repositories/appointment_repository.dart';

export 'package:appointment_booking_app/data/repositories/appointment_repository.dart'
    show BookingConflictException;

/// Shared in-memory availability store for the mock doctor and appointment
/// repositories. Reserving a slot is an atomic operation in this store.
class MockBookingStore {
  final Map<String, TimeSlotModel> _slotsById = {};

  List<TimeSlotModel> slotsFor({
    required String doctorId,
    required DateTime date,
    required bool doctorIsAvailable,
  }) {
    if (!doctorIsAvailable) return const [];

    return [
      _slot(
        doctorId: doctorId,
        date: date,
        suffix: '0900',
        startTime: '9:00 AM',
        endTime: '9:30 AM',
      ),
      _slot(
        doctorId: doctorId,
        date: date,
        suffix: '1030',
        startTime: '10:30 AM',
        endTime: '11:00 AM',
        initiallyBooked: true,
      ),
      _slot(
        doctorId: doctorId,
        date: date,
        suffix: '1500',
        startTime: '3:00 PM',
        endTime: '3:30 PM',
      ),
    ];
  }

  bool isAvailable({required String doctorId, required String timeSlotId}) {
    final slot = _slotsById[timeSlotId];
    return slot != null && slot.doctorId == doctorId && !slot.isBooked;
  }

  TimeSlotModel reserve({
    required String doctorId,
    required String timeSlotId,
    required String userId,
  }) {
    final slot = _slotsById[timeSlotId];
    if (slot == null || slot.doctorId != doctorId || slot.isBooked) {
      throw const BookingConflictException(
          'This time slot is no longer available.');
    }
    final reserved = slot.copyWith(isBooked: true, bookedByUserId: userId);
    _slotsById[timeSlotId] = reserved;
    return reserved;
  }

  void release(String timeSlotId) {
    final slot = _slotsById[timeSlotId];
    if (slot == null) return;
    _slotsById[timeSlotId] =
        slot.copyWith(isBooked: false, bookedByUserId: null);
  }

  TimeSlotModel _slot({
    required String doctorId,
    required DateTime date,
    required String suffix,
    required String startTime,
    required String endTime,
    bool initiallyBooked = false,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final id = '${doctorId}_${normalizedDate.toIso8601String()}_$suffix';
    return _slotsById.putIfAbsent(
      id,
      () => TimeSlotModel(
        id: id,
        doctorId: doctorId,
        date: normalizedDate,
        startTime: startTime,
        endTime: endTime,
        isBooked: initiallyBooked,
        bookedByUserId: initiallyBooked ? 'sample-user' : null,
      ),
    );
  }
}
