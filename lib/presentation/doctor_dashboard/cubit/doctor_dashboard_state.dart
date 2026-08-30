import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/data/models/doctor_model.dart';

enum DoctorDashboardStatus { loading, ready, failure }

class DoctorDashboardState {
  const DoctorDashboardState({
    this.status = DoctorDashboardStatus.loading,
    this.doctor,
    this.todayAppointments = const [],
    this.upcomingAppointments = const [],
    this.errorMessage,
  });

  final DoctorDashboardStatus status;
  final DoctorModel? doctor;
  final List<AppointmentModel> todayAppointments;
  final List<AppointmentModel> upcomingAppointments;
  final String? errorMessage;

  int get todayCount => todayAppointments.length;
  int get upcomingCount => upcomingAppointments.length;
}
