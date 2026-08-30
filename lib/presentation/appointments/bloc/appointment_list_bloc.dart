import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/data/models/user_model.dart';
import 'package:appointment_booking_app/data/repositories/appointment_repository.dart';
import 'package:appointment_booking_app/presentation/appointments/bloc/appointment_list_event.dart';
import 'package:appointment_booking_app/presentation/appointments/bloc/appointment_list_state.dart';

class AppointmentListBloc
    extends Bloc<AppointmentListEvent, AppointmentListState> {
  AppointmentListBloc({
    required AppointmentRepository appointmentRepository,
    required UserModel user,
  })  : _appointmentRepository = appointmentRepository,
        _user = user,
        super(const AppointmentListState()) {
    on<AppointmentListStarted>(_onLoadRequested);
    on<AppointmentListRefreshRequested>(_onLoadRequested);
    on<AppointmentCancellationRequested>(_onCancellationRequested);
  }

  final AppointmentRepository _appointmentRepository;
  final UserModel _user;

  Future<void> _onLoadRequested(
    AppointmentListEvent event,
    Emitter<AppointmentListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AppointmentListStatus.loading,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      final results = await Future.wait<List<AppointmentModel>>([
        _appointmentRepository.getUpcomingAppointments(_user.id),
        _appointmentRepository.getAppointmentHistory(_user.id),
      ]);
      final upcoming = results[0];
      final history = results[1];
      emit(
        state.copyWith(
          status: AppointmentListStatus.success,
          upcoming: upcoming,
          completed: _onlyStatus(history, AppointmentStatus.completed),
          cancelled: _onlyStatus(history, AppointmentStatus.cancelled),
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AppointmentListStatus.failure,
          errorMessage: 'Unable to load appointments. Please try again.',
        ),
      );
    }
  }

  Future<void> _onCancellationRequested(
    AppointmentCancellationRequested event,
    Emitter<AppointmentListState> emit,
  ) async {
    final appointment = state.upcoming
        .where(
          (item) => item.bookingId == event.bookingId,
        )
        .firstOrNull;
    if (appointment == null) {
      emit(
        state.copyWith(
          errorMessage: 'Only upcoming appointments can be cancelled.',
        ),
      );
      return;
    }

    final bookingId = appointment.bookingId;
    if (bookingId == null) {
      emit(
        state.copyWith(
            errorMessage: 'This appointment has no valid booking ID.'),
      );
      return;
    }
    emit(
      state.copyWith(
        cancellingBookingId: bookingId,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      await _appointmentRepository.cancelAppointment(bookingId);
      final remainingUpcoming =
          state.upcoming.where((item) => item.bookingId != bookingId).toList();
      final cancelledAppointment = appointment.copyWith(
        status: AppointmentStatus.cancelled,
      );
      emit(
        state.copyWith(
          status: AppointmentListStatus.success,
          upcoming: remainingUpcoming,
          cancelled: [cancelledAppointment, ...state.cancelled],
          clearCancelling: true,
          successMessage:
              'Appointment cancelled. The time slot is available again.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          clearCancelling: true,
          errorMessage: 'Unable to cancel this appointment. Please try again.',
        ),
      );
    }
  }

  List<AppointmentModel> _onlyStatus(
    List<AppointmentModel> appointments,
    AppointmentStatus status,
  ) =>
      appointments
          .where((appointment) => appointment.status == status)
          .toList();
}
