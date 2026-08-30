import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/data/models/doctor_model.dart';
import 'package:appointment_booking_app/data/models/time_slot_model.dart';
import 'package:appointment_booking_app/data/repositories/doctor_repository.dart';
import 'package:appointment_booking_app/presentation/doctor_details/cubit/doctor_details_state.dart';

class DoctorDetailsCubit extends Cubit<DoctorDetailsState> {
  DoctorDetailsCubit({
    required DoctorRepository doctorRepository,
    required this.doctorId,
  })  : _doctorRepository = doctorRepository,
        super(const DoctorDetailsState());

  final DoctorRepository _doctorRepository;
  final String doctorId;

  Future<void> load() async {
    emit(const DoctorDetailsState());
    try {
      final doctor = await _doctorRepository.getDoctorById(doctorId);
      final slotDate = _nextAvailableDate(doctor);
      final List<TimeSlotModel> slots = slotDate == null
          ? const <TimeSlotModel>[]
          : await _doctorRepository.getAvailableSlots(
              doctorId: doctor.id,
              date: slotDate,
            );
      emit(
        DoctorDetailsState(
          status: DoctorDetailsStatus.success,
          doctor: doctor,
          slots: slots,
          slotDate: slotDate,
        ),
      );
    } catch (_) {
      emit(
        const DoctorDetailsState(
          status: DoctorDetailsStatus.failure,
          errorMessage: 'Unable to load doctor details. Please try again.',
        ),
      );
    }
  }

  DateTime? _nextAvailableDate(DoctorModel doctor) {
    for (var offset = 0; offset < 7; offset++) {
      final date = DateTime.now().add(Duration(days: offset));
      if (doctor.availableDays.contains(_weekdayName(date))) return date;
    }
    return null;
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
}
