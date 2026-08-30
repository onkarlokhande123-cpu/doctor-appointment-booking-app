import 'package:flutter_test/flutter_test.dart';

import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/data/mock/mock_booking_store.dart';
import 'package:appointment_booking_app/data/mock/mock_doctor_data.dart';
import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/data/models/user_model.dart';
import 'package:appointment_booking_app/data/repositories/appointment_repository.dart';
import 'package:appointment_booking_app/data/repositories/mock_appointment_repository.dart';
import 'package:appointment_booking_app/presentation/appointments/bloc/appointment_list_bloc.dart';
import 'package:appointment_booking_app/presentation/appointments/bloc/appointment_list_event.dart';
import 'package:appointment_booking_app/presentation/appointments/bloc/appointment_list_state.dart';

void main() {
  final user = _user('user-a');
  final otherUser = _user('user-b');

  test('appointment lists are user-scoped and separated by status', () async {
    final store = MockBookingStore();
    final repository = MockAppointmentRepository(
      bookingStore: store,
      initialAppointments: [
        _appointment(
          bookingId: 'completed-a',
          user: user,
          status: AppointmentStatus.completed,
        ),
        _appointment(
          bookingId: 'cancelled-a',
          user: user,
          status: AppointmentStatus.cancelled,
        ),
        _appointment(
          bookingId: 'completed-b',
          user: otherUser,
          status: AppointmentStatus.completed,
        ),
      ],
    );
    final slot = store
        .slotsFor(
          doctorId: mockDoctors.first.id,
          date: _futureDate(),
          doctorIsAvailable: true,
        )
        .firstWhere((item) => !item.isBooked);
    await repository.createAppointment(
      _appointment(
          user: user, slotId: slot.id, status: AppointmentStatus.upcoming),
    );

    final bloc = AppointmentListBloc(
      appointmentRepository: repository,
      user: user,
    )..add(const AppointmentListStarted());
    await _flush();

    expect(bloc.state.status, AppointmentListStatus.success);
    expect(bloc.state.upcoming, hasLength(1));
    expect(bloc.state.completed.map((item) => item.bookingId), ['completed-a']);
    expect(bloc.state.cancelled.map((item) => item.bookingId), ['cancelled-a']);
    expect(
      [...bloc.state.upcoming, ...bloc.state.completed, ...bloc.state.cancelled]
          .every((appointment) => appointment.userId == user.id),
      isTrue,
    );

    await bloc.close();
  });

  test('cancelling an upcoming appointment releases its slot immediately',
      () async {
    final store = MockBookingStore();
    final repository = MockAppointmentRepository(bookingStore: store);
    final slot = store
        .slotsFor(
          doctorId: mockDoctors.first.id,
          date: _futureDate(),
          doctorIsAvailable: true,
        )
        .firstWhere((item) => !item.isBooked);
    final appointment = await repository.createAppointment(
      _appointment(
          user: user, slotId: slot.id, status: AppointmentStatus.upcoming),
    );
    final bloc = AppointmentListBloc(
      appointmentRepository: repository,
      user: user,
    )..add(const AppointmentListStarted());
    await _flush();

    bloc.add(AppointmentCancellationRequested(appointment.bookingId!));
    await _flush();

    expect(bloc.state.upcoming, isEmpty);
    expect(bloc.state.cancelled.single.bookingId, appointment.bookingId);
    expect(
      await repository.isSlotAvailable(
        doctorId: appointment.doctorId,
        timeSlotId: appointment.timeSlotId,
      ),
      isTrue,
    );

    await bloc.close();
  });

  test('completed and cancelled appointments cannot be cancelled', () async {
    final store = MockBookingStore();
    final repository = MockAppointmentRepository(
      bookingStore: store,
      initialAppointments: [
        _appointment(
          bookingId: 'completed',
          user: user,
          status: AppointmentStatus.completed,
        ),
        _appointment(
          bookingId: 'cancelled',
          user: user,
          status: AppointmentStatus.cancelled,
        ),
      ],
    );

    expect(
      repository.cancelAppointment('completed'),
      throwsA(isA<BookingConflictException>()),
    );
    expect(
      repository.cancelAppointment('cancelled'),
      throwsA(isA<BookingConflictException>()),
    );
  });

  test('list BLoC exposes an error state when refresh fails', () async {
    final bloc = AppointmentListBloc(
      appointmentRepository: _FailingAppointmentRepository(),
      user: user,
    )..add(const AppointmentListRefreshRequested());
    await _flush();

    expect(bloc.state.status, AppointmentListStatus.failure);
    expect(bloc.state.errorMessage, isNotNull);
    await bloc.close();
  });
}

Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 10));

UserModel _user(String id) => UserModel(
      id: id,
      name: 'Patient $id',
      email: '$id@example.com',
      phone: '9876543210',
      createdAt: DateTime(2026),
    );

AppointmentModel _appointment({
  String? bookingId,
  required UserModel user,
  required AppointmentStatus status,
  String? slotId,
}) =>
    AppointmentModel(
      bookingId: bookingId,
      userId: user.id,
      doctorId: mockDoctors.first.id,
      doctorName: mockDoctors.first.name,
      date: _futureDate(),
      timeSlotId: slotId ?? 'seed-${bookingId ?? user.id}',
      startTime: '9:00 AM',
      endTime: '9:30 AM',
      patientName: user.name,
      patientEmail: user.email,
      patientAge: 0,
      patientGender: Gender.other,
      patientPhone: user.phone,
      reason: 'Routine consultation',
      fee: mockDoctors.first.consultationFee,
      status: status,
      createdAt: DateTime.now(),
    );

DateTime _futureDate() => DateTime.now().add(const Duration(days: 2));

class _FailingAppointmentRepository implements AppointmentRepository {
  @override
  Future<void> cancelAppointment(String bookingId) =>
      throw UnimplementedError();

  @override
  Future<AppointmentModel> createAppointment(AppointmentModel appointment) =>
      throw UnimplementedError();

  @override
  Future<AppointmentModel> getAppointmentById(String bookingId) =>
      throw UnimplementedError();

  @override
  Future<List<AppointmentModel>> getAppointmentHistory(String userId) =>
      Future<List<AppointmentModel>>.error(StateError('Repository failure'));

  @override
  Future<List<AppointmentModel>> getUpcomingAppointments(String userId) =>
      Future<List<AppointmentModel>>.error(StateError('Repository failure'));

  @override
  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) =>
      Future<List<AppointmentModel>>.error(StateError('Repository failure'));

  @override
  Future<bool> isSlotAvailable({
    required String doctorId,
    required String timeSlotId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateDoctorAppointmentStatus({
    required String bookingId,
    required String doctorId,
    required AppointmentStatus status,
  }) =>
      throw UnimplementedError();
}
