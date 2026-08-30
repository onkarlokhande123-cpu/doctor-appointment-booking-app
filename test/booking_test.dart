import 'package:flutter_test/flutter_test.dart';

import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/data/mock/mock_booking_store.dart';
import 'package:appointment_booking_app/data/mock/mock_doctor_data.dart';
import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/data/models/user_model.dart';
import 'package:appointment_booking_app/data/repositories/mock_appointment_repository.dart';
import 'package:appointment_booking_app/data/repositories/mock_doctor_repository.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_bloc.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_event.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_state.dart';

void main() {
  late MockBookingStore store;
  late MockAppointmentRepository appointmentRepository;
  final doctor = mockDoctors.first;

  setUp(() {
    store = MockBookingStore();
    appointmentRepository = MockAppointmentRepository(bookingStore: store);
  });

  test('repository rejects a booking in the past', () async {
    final date = DateTime.now().subtract(const Duration(days: 1));
    final slot = store
        .slotsFor(
          doctorId: doctor.id,
          date: date,
          doctorIsAvailable: true,
        )
        .first;

    expect(
      appointmentRepository
          .createAppointment(_request(date: date, slotId: slot.id)),
      throwsA(isA<BookingConflictException>()),
    );
  });

  test('repository rejects an already booked slot', () async {
    final date = _futureDate();
    final bookedSlot = store
        .slotsFor(doctorId: doctor.id, date: date, doctorIsAvailable: true)
        .firstWhere((slot) => slot.isBooked);

    expect(
      appointmentRepository.createAppointment(
        _request(date: date, slotId: bookedSlot.id),
      ),
      throwsA(isA<BookingConflictException>()),
    );
  });

  test('successful bookings receive unique IDs and reserve slots', () async {
    final date = _futureDate();
    final slots = store
        .slotsFor(doctorId: doctor.id, date: date, doctorIsAvailable: true)
        .where((slot) => !slot.isBooked)
        .toList();

    final first = await appointmentRepository.createAppointment(
      _request(date: date, slotId: slots[0].id),
    );
    final second = await appointmentRepository.createAppointment(
      _request(date: date, slotId: slots[1].id),
    );

    expect(first.bookingId, isNotNull);
    expect(second.bookingId, isNotNull);
    expect(first.bookingId, isNot(second.bookingId));
    expect(
      await appointmentRepository.isSlotAvailable(
        doctorId: doctor.id,
        timeSlotId: slots[0].id,
      ),
      isFalse,
    );
  });

  test('repository prevents double booking of the same slot', () async {
    final date = _futureDate();
    final slot = store
        .slotsFor(doctorId: doctor.id, date: date, doctorIsAvailable: true)
        .firstWhere((slot) => !slot.isBooked);

    await appointmentRepository
        .createAppointment(_request(date: date, slotId: slot.id));

    expect(
      appointmentRepository
          .createAppointment(_request(date: date, slotId: slot.id)),
      throwsA(isA<BookingConflictException>()),
    );
  });

  test('BookingBloc validates every required patient field', () async {
    final doctorRepository = MockDoctorRepository(bookingStore: store);
    final bloc = BookingBloc(
      doctorRepository: doctorRepository,
      appointmentRepository: appointmentRepository,
      user: _user,
      doctorId: doctor.id,
    )..add(const BookingStarted());
    final date = _futureAvailableDate();

    await Future<void>.delayed(const Duration(milliseconds: 600));
    bloc.add(BookingDateSelected(date));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final slot = bloc.state.slots.firstWhere((slot) => !slot.isBooked);
    bloc
      ..add(BookingSlotSelected(slot.id))
      ..add(const BookingContinueRequested())
      ..add(
        const BookingPatientDetailsUpdated(
          name: '',
          email: 'invalid',
          phone: '123',
          reason: '',
        ),
      )
      ..add(const BookingContinueRequested());

    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.step, BookingStep.patientDetails);
    expect(
      bloc.state.fieldErrors.keys,
      containsAll(<String>['name', 'email', 'phone', 'reason']),
    );

    await bloc.close();
  });
}

final _user = UserModel(
  id: 'patient-1',
  name: 'Alex Patient',
  email: 'alex@example.com',
  phone: '9876543210',
  createdAt: DateTime(2026),
);

AppointmentModel _request({required DateTime date, required String slotId}) {
  return AppointmentModel(
    userId: _user.id,
    doctorId: mockDoctors.first.id,
    doctorName: mockDoctors.first.name,
    date: date,
    timeSlotId: slotId,
    startTime: '9:00 AM',
    endTime: '9:30 AM',
    patientName: _user.name,
    patientEmail: _user.email,
    patientAge: 0,
    patientGender: Gender.other,
    patientPhone: _user.phone,
    reason: 'Routine consultation',
    fee: mockDoctors.first.consultationFee,
    status: AppointmentStatus.upcoming,
    createdAt: DateTime.now(),
  );
}

DateTime _futureDate() => DateTime.now().add(const Duration(days: 1));

DateTime _futureAvailableDate() {
  for (var daysAhead = 0; daysAhead < 8; daysAhead++) {
    final date = DateTime.now().add(Duration(days: daysAhead));
    if (mockDoctors.first.availableDays.contains(_weekdayName(date))) {
      return date;
    }
  }
  throw StateError('Mock doctor should have an available day.');
}

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
