import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/data/models/user_model.dart';
import 'package:appointment_booking_app/data/repositories/appointment_repository.dart';
import 'package:appointment_booking_app/data/repositories/doctor_repository.dart';
import 'package:appointment_booking_app/presentation/doctor_dashboard/cubit/doctor_dashboard_state.dart';

class DoctorDashboardCubit extends Cubit<DoctorDashboardState> {
  DoctorDashboardCubit({
    required DoctorRepository doctorRepository,
    required AppointmentRepository appointmentRepository,
    required UserModel user,
  })  : _doctorRepository = doctorRepository,
        _appointmentRepository = appointmentRepository,
        _doctorId = user.doctorId,
        super(const DoctorDashboardState()) {
    load();
  }

  final DoctorRepository _doctorRepository;
  final AppointmentRepository _appointmentRepository;
  final String? _doctorId;

  Future<void> load() async {
    final doctorId = _doctorId;
    if (doctorId == null || doctorId.isEmpty) {
      emit(
        const DoctorDashboardState(
          status: DoctorDashboardStatus.failure,
          errorMessage: 'Your doctor profile is not configured.',
        ),
      );
      return;
    }
    emit(const DoctorDashboardState());
    try {
      final doctorFuture = _doctorRepository.getDoctorById(doctorId);
      final appointmentsFuture =
          _appointmentRepository.getDoctorAppointments(doctorId);
      final doctor = await doctorFuture;
      final appointments = await appointmentsFuture;
      final today = DateTime.now();
      final todayAppointments = appointments
          .where(
            (appointment) =>
                appointment.status == AppointmentStatus.upcoming &&
                _isSameDay(appointment.date, today),
          )
          .toList(growable: false);
      final upcomingAppointments = appointments
          .where(
            (appointment) =>
                appointment.status == AppointmentStatus.upcoming &&
                appointment.date
                    .isAfter(DateTime(today.year, today.month, today.day)),
          )
          .toList(growable: false);
      emit(
        DoctorDashboardState(
          status: DoctorDashboardStatus.ready,
          doctor: doctor,
          todayAppointments: todayAppointments,
          upcomingAppointments: upcomingAppointments,
        ),
      );
    } catch (_) {
      emit(
        const DoctorDashboardState(
          status: DoctorDashboardStatus.failure,
          errorMessage:
              'Unable to load the doctor dashboard. Please try again.',
        ),
      );
    }
  }

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
