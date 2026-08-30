import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/data/models/user_model.dart';
import 'package:appointment_booking_app/data/repositories/appointment_repository.dart';
import 'package:appointment_booking_app/presentation/doctor_appointments/cubit/doctor_appointments_state.dart';

class DoctorAppointmentsCubit extends Cubit<DoctorAppointmentsState> {
  DoctorAppointmentsCubit({
    required AppointmentRepository appointmentRepository,
    required UserModel user,
  })  : _appointmentRepository = appointmentRepository,
        _doctorId = user.doctorId,
        super(const DoctorAppointmentsState()) {
    load();
  }

  final AppointmentRepository _appointmentRepository;
  final String? _doctorId;

  Future<void> load() async {
    final doctorId = _doctorId;
    if (doctorId == null || doctorId.isEmpty) {
      emit(
        const DoctorAppointmentsState(
          status: DoctorAppointmentsStatus.failure,
          errorMessage: 'Your doctor profile is not configured.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: DoctorAppointmentsStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      final appointments =
          await _appointmentRepository.getDoctorAppointments(doctorId);
      final now = DateTime.now();
      final today = appointments
          .where(
            (item) =>
                item.status == AppointmentStatus.upcoming &&
                _isSameDay(item.date, now),
          )
          .toList(growable: false);
      final upcoming = appointments
          .where(
            (item) =>
                item.status == AppointmentStatus.upcoming &&
                item.date.isAfter(DateTime(now.year, now.month, now.day)),
          )
          .toList(growable: false);
      emit(
        state.copyWith(
          status: DoctorAppointmentsStatus.ready,
          today: today,
          upcoming: upcoming,
          completed: appointments
              .where((item) => item.status == AppointmentStatus.completed)
              .toList(growable: false),
          cancelled: appointments
              .where((item) => item.status == AppointmentStatus.cancelled)
              .toList(growable: false),
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DoctorAppointmentsStatus.failure,
          errorMessage: 'Unable to load appointments. Please try again.',
        ),
      );
    }
  }

  Future<void> complete(AppointmentModel appointment) =>
      _update(appointment, AppointmentStatus.completed);

  Future<void> cancel(AppointmentModel appointment) =>
      _update(appointment, AppointmentStatus.cancelled);

  Future<void> _update(
    AppointmentModel appointment,
    AppointmentStatus status,
  ) async {
    final doctorId = _doctorId;
    final bookingId = appointment.bookingId;
    if (doctorId == null || bookingId == null) return;
    emit(
      state.copyWith(
        updatingBookingId: bookingId,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      await _appointmentRepository.updateDoctorAppointmentStatus(
        bookingId: bookingId,
        doctorId: doctorId,
        status: status,
      );
      await load();
      if (!isClosed) {
        emit(
          state.copyWith(
            clearUpdating: true,
            successMessage: status == AppointmentStatus.completed
                ? 'Appointment marked as completed.'
                : 'Appointment cancelled and the slot released.',
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          clearUpdating: true,
          errorMessage: 'Unable to update this appointment. Please try again.',
        ),
      );
    }
  }

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
