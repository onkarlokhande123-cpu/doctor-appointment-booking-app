import 'package:appointment_booking_app/data/models/appointment_model.dart';

enum DoctorAppointmentsStatus { loading, ready, failure }

class DoctorAppointmentsState {
  const DoctorAppointmentsState({
    this.status = DoctorAppointmentsStatus.loading,
    this.today = const [],
    this.upcoming = const [],
    this.completed = const [],
    this.cancelled = const [],
    this.updatingBookingId,
    this.errorMessage,
    this.successMessage,
  });

  final DoctorAppointmentsStatus status;
  final List<AppointmentModel> today;
  final List<AppointmentModel> upcoming;
  final List<AppointmentModel> completed;
  final List<AppointmentModel> cancelled;
  final String? updatingBookingId;
  final String? errorMessage;
  final String? successMessage;

  DoctorAppointmentsState copyWith({
    DoctorAppointmentsStatus? status,
    List<AppointmentModel>? today,
    List<AppointmentModel>? upcoming,
    List<AppointmentModel>? completed,
    List<AppointmentModel>? cancelled,
    String? updatingBookingId,
    String? errorMessage,
    String? successMessage,
    bool clearUpdating = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return DoctorAppointmentsState(
      status: status ?? this.status,
      today: today ?? this.today,
      upcoming: upcoming ?? this.upcoming,
      completed: completed ?? this.completed,
      cancelled: cancelled ?? this.cancelled,
      updatingBookingId:
          clearUpdating ? null : updatingBookingId ?? this.updatingBookingId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}
