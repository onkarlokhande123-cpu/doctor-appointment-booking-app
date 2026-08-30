import 'package:appointment_booking_app/data/models/doctor_model.dart';
import 'package:appointment_booking_app/data/models/time_slot_model.dart';

enum DoctorDetailsStatus { loading, success, failure }

class DoctorDetailsState {
  const DoctorDetailsState({
    this.status = DoctorDetailsStatus.loading,
    this.doctor,
    this.slots = const [],
    this.slotDate,
    this.errorMessage,
  });

  final DoctorDetailsStatus status;
  final DoctorModel? doctor;
  final List<TimeSlotModel> slots;
  final DateTime? slotDate;
  final String? errorMessage;
}
