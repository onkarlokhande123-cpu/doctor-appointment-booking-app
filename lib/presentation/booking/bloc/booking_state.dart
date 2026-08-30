import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/data/models/doctor_model.dart';
import 'package:appointment_booking_app/data/models/time_slot_model.dart';

enum BookingStatus { initial, loading, ready, submitting, success, failure }

enum BookingStep { dateAndSlot, patientDetails, summary, success }

class BookingState {
  const BookingState({
    this.status = BookingStatus.initial,
    this.step = BookingStep.dateAndSlot,
    this.doctor,
    this.selectedDate,
    this.slots = const [],
    this.selectedSlot,
    this.patientName = '',
    this.patientEmail = '',
    this.patientPhone = '',
    this.reason = '',
    this.fieldErrors = const {},
    this.errorMessage,
    this.confirmedAppointment,
    this.isSlotLoading = false,
  });

  final BookingStatus status;
  final BookingStep step;
  final DoctorModel? doctor;
  final DateTime? selectedDate;
  final List<TimeSlotModel> slots;
  final TimeSlotModel? selectedSlot;
  final String patientName;
  final String patientEmail;
  final String patientPhone;
  final String reason;
  final Map<String, String> fieldErrors;
  final String? errorMessage;
  final AppointmentModel? confirmedAppointment;
  final bool isSlotLoading;

  bool get isSubmitting => status == BookingStatus.submitting;

  BookingState copyWith({
    BookingStatus? status,
    BookingStep? step,
    DoctorModel? doctor,
    DateTime? selectedDate,
    List<TimeSlotModel>? slots,
    TimeSlotModel? selectedSlot,
    String? patientName,
    String? patientEmail,
    String? patientPhone,
    String? reason,
    Map<String, String>? fieldErrors,
    String? errorMessage,
    AppointmentModel? confirmedAppointment,
    bool? isSlotLoading,
    bool clearSelectedSlot = false,
    bool clearError = false,
  }) {
    return BookingState(
      status: status ?? this.status,
      step: step ?? this.step,
      doctor: doctor ?? this.doctor,
      selectedDate: selectedDate ?? this.selectedDate,
      slots: slots ?? this.slots,
      selectedSlot:
          clearSelectedSlot ? null : selectedSlot ?? this.selectedSlot,
      patientName: patientName ?? this.patientName,
      patientEmail: patientEmail ?? this.patientEmail,
      patientPhone: patientPhone ?? this.patientPhone,
      reason: reason ?? this.reason,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      confirmedAppointment: confirmedAppointment ?? this.confirmedAppointment,
      isSlotLoading: isSlotLoading ?? this.isSlotLoading,
    );
  }
}
