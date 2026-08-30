import 'package:appointment_booking_app/data/models/appointment_model.dart';

enum AppointmentListStatus { initial, loading, success, failure }

class AppointmentListState {
  const AppointmentListState({
    this.status = AppointmentListStatus.initial,
    this.upcoming = const [],
    this.completed = const [],
    this.cancelled = const [],
    this.cancellingBookingId,
    this.errorMessage,
    this.successMessage,
  });

  final AppointmentListStatus status;
  final List<AppointmentModel> upcoming;
  final List<AppointmentModel> completed;
  final List<AppointmentModel> cancelled;
  final String? cancellingBookingId;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == AppointmentListStatus.loading;

  AppointmentListState copyWith({
    AppointmentListStatus? status,
    List<AppointmentModel>? upcoming,
    List<AppointmentModel>? completed,
    List<AppointmentModel>? cancelled,
    String? cancellingBookingId,
    String? errorMessage,
    String? successMessage,
    bool clearCancelling = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AppointmentListState(
      status: status ?? this.status,
      upcoming: upcoming ?? this.upcoming,
      completed: completed ?? this.completed,
      cancelled: cancelled ?? this.cancelled,
      cancellingBookingId: clearCancelling
          ? null
          : cancellingBookingId ?? this.cancellingBookingId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}
