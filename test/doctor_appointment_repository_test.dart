import 'package:flutter_test/flutter_test.dart';

import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/data/mock/mock_booking_store.dart';
import 'package:appointment_booking_app/data/mock/mock_doctor_data.dart';
import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/data/repositories/mock_appointment_repository.dart';

void main() {
  test('doctor appointment retrieval is scoped to the doctor ID', () async {
    final repository = MockAppointmentRepository(
      bookingStore: MockBookingStore(),
      initialAppointments: [
        _appointment(
          bookingId: 'doctor-a',
          doctorId: 'dr-meera-shah',
          status: AppointmentStatus.upcoming,
          date: DateTime.now().add(const Duration(days: 1)),
        ),
        _appointment(
          bookingId: 'doctor-b',
          doctorId: 'dr-arjun-verma',
          status: AppointmentStatus.upcoming,
          date: DateTime.now().add(const Duration(days: 1)),
        ),
      ],
    );

    final appointments =
        await repository.getDoctorAppointments('dr-meera-shah');

    expect(appointments, hasLength(1));
    expect(appointments.single.bookingId, 'doctor-a');
  });

  test('doctor can complete only an already-started appointment', () async {
    final repository = MockAppointmentRepository(
      bookingStore: MockBookingStore(),
      initialAppointments: [
        _appointment(
          bookingId: 'started',
          doctorId: 'dr-meera-shah',
          status: AppointmentStatus.upcoming,
          date: DateTime.now().subtract(const Duration(days: 1)),
        ),
        _appointment(
          bookingId: 'future',
          doctorId: 'dr-meera-shah',
          status: AppointmentStatus.upcoming,
          date: DateTime.now().add(const Duration(days: 1)),
        ),
      ],
    );

    await repository.updateDoctorAppointmentStatus(
      bookingId: 'started',
      doctorId: 'dr-meera-shah',
      status: AppointmentStatus.completed,
    );
    final completed = await repository.getAppointmentById('started');
    expect(completed.status, AppointmentStatus.completed);

    await expectLater(
      repository.updateDoctorAppointmentStatus(
        bookingId: 'future',
        doctorId: 'dr-meera-shah',
        status: AppointmentStatus.completed,
      ),
      throwsA(isA<BookingConflictException>()),
    );
  });

  test('doctor cancellation releases the reserved slot', () async {
    final store = MockBookingStore();
    final repository = MockAppointmentRepository(bookingStore: store);
    final date = DateTime.now().add(const Duration(days: 1));
    final slot = store
        .slotsFor(
          doctorId: mockDoctors.first.id,
          date: date,
          doctorIsAvailable: true,
        )
        .first;
    final confirmed = await repository.createAppointment(
      _appointment(
        doctorId: mockDoctors.first.id,
        date: date,
        timeSlotId: slot.id,
        status: AppointmentStatus.upcoming,
      ),
    );

    await repository.updateDoctorAppointmentStatus(
      bookingId: confirmed.bookingId!,
      doctorId: mockDoctors.first.id,
      status: AppointmentStatus.cancelled,
    );

    expect(
      await repository.isSlotAvailable(
        doctorId: mockDoctors.first.id,
        timeSlotId: slot.id,
      ),
      isTrue,
    );
  });
}

AppointmentModel _appointment({
  String? bookingId,
  required String doctorId,
  required DateTime date,
  String? timeSlotId,
  required AppointmentStatus status,
}) =>
    AppointmentModel(
      bookingId: bookingId,
      userId: 'patient-1',
      doctorId: doctorId,
      doctorName: 'Doctor',
      date: date,
      timeSlotId: timeSlotId ?? '${doctorId}_slot',
      startTime: '9:00 AM',
      endTime: '9:30 AM',
      patientName: 'Patient One',
      patientEmail: 'patient@example.com',
      patientAge: 30,
      patientGender: Gender.other,
      patientPhone: '9876543210',
      reason: 'Consultation',
      fee: 500,
      status: status,
      createdAt: DateTime.now(),
    );
