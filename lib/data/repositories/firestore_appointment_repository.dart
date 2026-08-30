import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/data/repositories/appointment_repository.dart';

/// Firestore-backed implementation of appointment booking and cancellation.
///
/// Slot reservation and appointment creation happen in a single Firestore
/// transaction. The slot document is therefore the concurrency guard that
/// prevents two patients from booking the same doctor/date/time.
class FirestoreAppointmentRepository implements AppointmentRepository {
  FirestoreAppointmentRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestoreOverride = firestore,
        _firebaseAuthOverride = firebaseAuth;

  static const String _appointmentsCollection = 'appointments';
  static const String _slotsCollection = 'doctorSlots';
  static const String _usersCollection = 'users';

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _firebaseAuthOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _firebaseAuth =>
      _firebaseAuthOverride ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection(_appointmentsCollection);
  CollectionReference<Map<String, dynamic>> get _slots =>
      _firestore.collection(_slotsCollection);
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(_usersCollection);

  @override
  Future<bool> isSlotAvailable({
    required String doctorId,
    required String timeSlotId,
  }) async {
    _requireSignedInUser();
    try {
      final snapshot = await _slots.doc(timeSlotId).get();
      final data = snapshot.data();
      return snapshot.exists &&
          data != null &&
          data['doctorId'] == doctorId &&
          data['isBooked'] == false &&
          _slotHasNotStarted(data['startsAt']);
    } on FirebaseException catch (error) {
      throw AppointmentRepositoryException(_mapFirestoreError(error));
    }
  }

  @override
  Future<AppointmentModel> createAppointment(
      AppointmentModel appointment) async {
    final userId = _requireSignedInUser();
    if (appointment.userId != userId) {
      throw const AppointmentRepositoryException(
        'You cannot create an appointment for another user.',
      );
    }
    if (_isPastDate(appointment.date)) {
      throw const BookingConflictException(
        'Appointments cannot be booked in the past.',
      );
    }

    final appointmentReference = appointment.bookingId == null
        ? _appointments.doc()
        : _appointments.doc(appointment.bookingId);
    final bookingId = appointmentReference.id;
    final slotReference = _slots.doc(appointment.timeSlotId);

    try {
      await _firestore.runTransaction((transaction) async {
        final slotSnapshot = await transaction.get(slotReference);
        final slot = slotSnapshot.data();
        if (!slotSnapshot.exists || slot == null) {
          throw const BookingConflictException(
              'This time slot is unavailable.');
        }
        if (slot['doctorId'] != appointment.doctorId ||
            slot['isBooked'] != false ||
            !_slotHasNotStarted(slot['startsAt'])) {
          throw const BookingConflictException(
            'This time slot is no longer available.',
          );
        }
        if (slot['date'] != _dateKey(appointment.date) ||
            slot['startTime'] != appointment.startTime ||
            slot['endTime'] != appointment.endTime) {
          throw const BookingConflictException(
            'The selected slot no longer matches this appointment.',
          );
        }

        transaction.update(slotReference, {
          'isBooked': true,
          'bookedByUserId': userId,
          'appointmentId': bookingId,
        });
        transaction.set(
          appointmentReference,
          _appointmentData(appointment, bookingId),
        );
      });
      final confirmed = await appointmentReference.get();
      return _appointmentFromSnapshot(confirmed);
    } on BookingConflictException {
      rethrow;
    } on FirebaseException catch (error) {
      throw AppointmentRepositoryException(_mapFirestoreError(error));
    }
  }

  @override
  Future<void> cancelAppointment(String bookingId) async {
    final userId = _requireSignedInUser();
    final appointmentReference = _appointments.doc(bookingId);
    try {
      await _firestore.runTransaction((transaction) async {
        final appointmentSnapshot = await transaction.get(appointmentReference);
        final appointment = appointmentSnapshot.data();
        if (!appointmentSnapshot.exists || appointment == null) {
          throw const AppointmentRepositoryException('Appointment not found.');
        }
        if (appointment['userId'] != userId) {
          throw const AppointmentRepositoryException(
            'You cannot cancel another user\'s appointment.',
          );
        }
        if (appointment['status'] != AppointmentStatus.upcoming.name) {
          throw const BookingConflictException(
            'Only upcoming appointments can be cancelled.',
          );
        }

        final timeSlotId = appointment['timeSlotId'] as String?;
        if (timeSlotId == null || timeSlotId.isEmpty) {
          throw const AppointmentRepositoryException(
              'Appointment slot is missing.');
        }
        final slotReference = _slots.doc(timeSlotId);
        final slotSnapshot = await transaction.get(slotReference);
        final slot = slotSnapshot.data();
        if (!slotSnapshot.exists ||
            slot == null ||
            slot['appointmentId'] != bookingId ||
            slot['bookedByUserId'] != userId) {
          throw const BookingConflictException(
            'This appointment slot can no longer be cancelled.',
          );
        }

        transaction.update(appointmentReference, {
          'status': AppointmentStatus.cancelled.name,
        });
        transaction.update(slotReference, {
          'isBooked': false,
          'bookedByUserId': null,
          'appointmentId': null,
        });
      });
    } on BookingConflictException {
      rethrow;
    } on AppointmentRepositoryException {
      rethrow;
    } on FirebaseException catch (error) {
      throw AppointmentRepositoryException(_mapFirestoreError(error));
    }
  }

  @override
  Future<AppointmentModel> getAppointmentById(String bookingId) async {
    final userId = _requireSignedInUser();
    try {
      final snapshot = await _appointments.doc(bookingId).get();
      if (!snapshot.exists) {
        throw const AppointmentRepositoryException('Appointment not found.');
      }
      final appointment = _appointmentFromSnapshot(snapshot);
      if (appointment.userId != userId) {
        throw const AppointmentRepositoryException(
          'You cannot access another user\'s appointment.',
        );
      }
      return appointment;
    } on FirebaseException catch (error) {
      throw AppointmentRepositoryException(_mapFirestoreError(error));
    }
  }

  @override
  Future<List<AppointmentModel>> getAppointmentHistory(String userId) async {
    return _getUserAppointments(userId, history: true);
  }

  @override
  Future<List<AppointmentModel>> getUpcomingAppointments(String userId) async {
    return _getUserAppointments(userId, history: false);
  }

  @override
  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) async {
    await _requireDoctorId(expectedDoctorId: doctorId);
    try {
      final snapshot =
          await _appointments.where('doctorId', isEqualTo: doctorId).get();
      final appointments =
          snapshot.docs.map(_appointmentFromSnapshot).toList(growable: false);
      appointments.sort((first, second) => first.date.compareTo(second.date));
      return appointments;
    } on FirebaseException catch (error) {
      throw AppointmentRepositoryException(_mapFirestoreError(error));
    }
  }

  @override
  Future<void> updateDoctorAppointmentStatus({
    required String bookingId,
    required String doctorId,
    required AppointmentStatus status,
  }) async {
    if (status != AppointmentStatus.completed &&
        status != AppointmentStatus.cancelled) {
      throw const AppointmentRepositoryException(
        'Doctors can only complete or cancel appointments.',
      );
    }
    await _requireDoctorId(expectedDoctorId: doctorId);
    final appointmentReference = _appointments.doc(bookingId);
    try {
      await _firestore.runTransaction((transaction) async {
        final appointmentSnapshot = await transaction.get(appointmentReference);
        final appointment = appointmentSnapshot.data();
        if (!appointmentSnapshot.exists || appointment == null) {
          throw const AppointmentRepositoryException('Appointment not found.');
        }
        if (appointment['doctorId'] != doctorId) {
          throw const AppointmentRepositoryException(
            'You cannot manage another doctor\'s appointment.',
          );
        }
        if (appointment['status'] != AppointmentStatus.upcoming.name) {
          throw const BookingConflictException(
            'Only upcoming appointments can be updated.',
          );
        }

        final slotId = appointment['timeSlotId'] as String?;
        if (slotId == null || slotId.isEmpty) {
          throw const AppointmentRepositoryException(
            'Appointment slot is missing.',
          );
        }
        final slotReference = _slots.doc(slotId);
        final slotSnapshot = await transaction.get(slotReference);
        final slot = slotSnapshot.data();
        if (!slotSnapshot.exists ||
            slot == null ||
            slot['appointmentId'] != bookingId ||
            slot['doctorId'] != doctorId) {
          throw const BookingConflictException(
            'This appointment slot can no longer be updated.',
          );
        }
        if (status == AppointmentStatus.completed &&
            _slotHasNotStarted(slot['startsAt'])) {
          throw const BookingConflictException(
            'An appointment can only be completed after its scheduled time.',
          );
        }

        transaction.update(appointmentReference, {'status': status.name});
        if (status == AppointmentStatus.cancelled) {
          transaction.update(slotReference, {
            'isBooked': false,
            'bookedByUserId': null,
            'appointmentId': null,
          });
        }
      });
    } on BookingConflictException {
      rethrow;
    } on AppointmentRepositoryException {
      rethrow;
    } on FirebaseException catch (error) {
      throw AppointmentRepositoryException(_mapFirestoreError(error));
    }
  }

  Future<List<AppointmentModel>> _getUserAppointments(
    String userId, {
    required bool history,
  }) async {
    _ensureCurrentUser(userId);
    try {
      // The userId equality is required by Firestore rules. Status filtering
      // and ordering stay local to avoid requiring a composite Firestore index.
      final snapshot =
          await _appointments.where('userId', isEqualTo: userId).get();
      final today = DateTime.now();
      final appointments = snapshot.docs
          .map(_appointmentFromSnapshot)
          .where(
            (appointment) => history
                ? appointment.status == AppointmentStatus.completed ||
                    appointment.status == AppointmentStatus.cancelled
                : appointment.status == AppointmentStatus.upcoming &&
                    !_isPastDate(appointment.date, now: today),
          )
          .toList();
      appointments.sort(
        (first, second) => history
            ? second.date.compareTo(first.date)
            : first.date.compareTo(second.date),
      );
      return appointments;
    } on FirebaseException catch (error) {
      throw AppointmentRepositoryException(_mapFirestoreError(error));
    }
  }

  Map<String, dynamic> _appointmentData(
    AppointmentModel appointment,
    String bookingId,
  ) {
    return {
      'bookingId': bookingId,
      'userId': appointment.userId,
      'doctorId': appointment.doctorId,
      'doctorName': appointment.doctorName,
      'doctorImageUrl': appointment.doctorImageUrl,
      'date': _dateKey(appointment.date),
      'timeSlotId': appointment.timeSlotId,
      'startTime': appointment.startTime,
      'endTime': appointment.endTime,
      'patientName': appointment.patientName,
      'patientEmail': appointment.patientEmail,
      'patientAge': appointment.patientAge,
      'patientGender': appointment.patientGender.name,
      'patientPhone': appointment.patientPhone,
      'reason': appointment.reason,
      'fee': appointment.fee,
      'status': AppointmentStatus.upcoming.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  AppointmentModel _appointmentFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = Map<String, dynamic>.from(snapshot.data() ?? const {});
    data['bookingId'] ??= snapshot.id;
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      data['createdAt'] = createdAt.toDate().toIso8601String();
    }
    return AppointmentModel.fromJson(data);
  }

  String _requireSignedInUser() {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      throw const AppointmentRepositoryException(
        'You must be signed in to manage appointments.',
      );
    }
    return userId;
  }

  void _ensureCurrentUser(String userId) {
    if (_requireSignedInUser() != userId) {
      throw const AppointmentRepositoryException(
        'You cannot access another user\'s appointments.',
      );
    }
  }

  Future<String> _requireDoctorId({String? expectedDoctorId}) async {
    final userId = _requireSignedInUser();
    try {
      final profile = await _users.doc(userId).get();
      final doctorId = profile.data()?['doctorId'] as String?;
      if (!profile.exists ||
          profile.data()?['role'] != 'doctor' ||
          doctorId == null ||
          doctorId.isEmpty ||
          (expectedDoctorId != null && doctorId != expectedDoctorId)) {
        throw const AppointmentRepositoryException(
          'You do not have access to this doctor profile.',
        );
      }
      return doctorId;
    } on FirebaseException catch (error) {
      throw AppointmentRepositoryException(_mapFirestoreError(error));
    }
  }

  bool _slotHasNotStarted(Object? value) {
    if (value is! Timestamp) return false;
    return value.toDate().isAfter(DateTime.now());
  }

  bool _isPastDate(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return DateTime(date.year, date.month, date.day).isBefore(
      DateTime(today.year, today.month, today.day),
    );
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _mapFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to manage this appointment.';
      case 'unavailable':
        return 'Appointment service is temporarily unavailable.';
      case 'unauthenticated':
        return 'Please sign in again and retry.';
      default:
        return error.message ?? 'Unable to manage the appointment.';
    }
  }
}

class AppointmentRepositoryException implements Exception {
  const AppointmentRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
