import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:appointment_booking_app/data/models/doctor_model.dart';
import 'package:appointment_booking_app/data/models/specialty_model.dart';
import 'package:appointment_booking_app/data/models/time_slot_model.dart';
import 'package:appointment_booking_app/data/repositories/doctor_repository.dart';

/// Firestore-backed doctor catalogue implementation.
///
/// Doctor, specialty, and appointment-slot data are loaded from Firestore.
class FirestoreDoctorRepository implements DoctorRepository {
  FirestoreDoctorRepository({
    FirebaseFirestore? firestore,
  }) : _firestoreOverride = firestore;

  static const String _doctorsCollection = 'doctors';
  static const String _specialtiesCollection = 'specialties';
  static const String _slotsCollection = 'doctorSlots';

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _doctors =>
      _firestore.collection(_doctorsCollection);

  CollectionReference<Map<String, dynamic>> get _specialties =>
      _firestore.collection(_specialtiesCollection);

  CollectionReference<Map<String, dynamic>> get _slots =>
      _firestore.collection(_slotsCollection);

  @override
  Future<List<DoctorModel>> getAllDoctors() async {
    try {
      final snapshot = await _doctors.orderBy('name').get();
      return snapshot.docs.map(_doctorFromSnapshot).toList(growable: false);
    } on FirebaseException catch (error) {
      throw DoctorRepositoryException(_mapFirestoreError(error));
    }
  }

  @override
  Future<DoctorModel> getDoctorById(String doctorId) async {
    try {
      final snapshot = await _doctors.doc(doctorId).get();
      if (!snapshot.exists) {
        throw const DoctorRepositoryException('Doctor not found.');
      }
      return _doctorFromSnapshot(snapshot);
    } on FirebaseException catch (error) {
      throw DoctorRepositoryException(_mapFirestoreError(error));
    }
  }

  @override
  Future<List<DoctorModel>> searchDoctors(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    final doctors = await getAllDoctors();
    if (normalizedQuery.isEmpty) return doctors;

    // Firestore remains the source of truth. Filtering locally preserves the
    // existing contract's case-insensitive substring behaviour without an
    // external search service or a duplicated search index.
    return doctors
        .where(
          (doctor) =>
              doctor.name.toLowerCase().contains(normalizedQuery) ||
              doctor.specialtyName.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }

  @override
  Future<List<DoctorModel>> filterDoctors({
    String? specialtyId,
    double? minRating,
  }) async {
    final doctors = await getAllDoctors();
    return doctors
        .where(
          (doctor) =>
              (specialtyId == null || doctor.specialtyId == specialtyId) &&
              (minRating == null || doctor.rating >= minRating),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SpecialtyModel>> getAllSpecialties() async {
    try {
      final snapshot = await _specialties.orderBy('name').get();
      return snapshot.docs.map(_specialtyFromSnapshot).toList(growable: false);
    } on FirebaseException catch (error) {
      throw DoctorRepositoryException(_mapFirestoreError(error));
    }
  }

  @override
  Future<List<TimeSlotModel>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final prefix = '${doctorId}_${_dateKey(normalizedDate)}_';
    try {
      final snapshot = await _slots
          .orderBy(FieldPath.documentId)
          .startAt([prefix]).endAt(['$prefix\uf8ff']).get();
      return snapshot.docs.map(_slotFromSnapshot).toList(growable: false);
    } on FirebaseException catch (error) {
      throw DoctorRepositoryException(_mapFirestoreError(error));
    }
  }

  DoctorModel _doctorFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = Map<String, dynamic>.from(snapshot.data() ?? const {});
    if ((data['id'] as String?)?.isNotEmpty != true) data['id'] = snapshot.id;
    return DoctorModel.fromJson(data);
  }

  SpecialtyModel _specialtyFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = Map<String, dynamic>.from(snapshot.data() ?? const {});
    if ((data['id'] as String?)?.isNotEmpty != true) data['id'] = snapshot.id;
    return SpecialtyModel.fromJson(data);
  }

  TimeSlotModel _slotFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final date = DateTime.tryParse(data['date'] as String? ?? '');
    if (date == null) {
      throw const DoctorRepositoryException(
          'A doctor slot has an invalid date.');
    }
    return TimeSlotModel(
      id: data['id'] as String? ?? snapshot.id,
      doctorId: data['doctorId'] as String? ?? '',
      date: DateTime(date.year, date.month, date.day),
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      isBooked: data['isBooked'] as bool? ?? false,
      bookedByUserId: data['bookedByUserId'] as String?,
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
        return 'You do not have permission to view doctors.';
      case 'unavailable':
        return 'Doctor information is temporarily unavailable.';
      case 'unauthenticated':
        return 'Please sign in again to view doctors.';
      default:
        return error.message ?? 'Unable to load doctor information.';
    }
  }
}

class DoctorRepositoryException implements Exception {
  const DoctorRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
