import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/data/models/user_model.dart';
import 'package:appointment_booking_app/data/repositories/appointment_repository.dart';
import 'package:appointment_booking_app/data/repositories/doctor_repository.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_event.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc({
    required DoctorRepository doctorRepository,
    required AppointmentRepository appointmentRepository,
    required UserModel user,
    required this.doctorId,
  })  : _doctorRepository = doctorRepository,
        _appointmentRepository = appointmentRepository,
        _user = user,
        super(const BookingState()) {
    on<BookingStarted>(_onStarted);
    on<BookingDateSelected>(_onDateSelected);
    on<BookingSlotSelected>(_onSlotSelected);
    on<BookingPatientDetailsUpdated>(_onPatientDetailsUpdated);
    on<BookingContinueRequested>(_onContinueRequested);
    on<BookingBackRequested>(_onBackRequested);
    on<BookingConfirmationRequested>(_onConfirmationRequested);
  }

  final DoctorRepository _doctorRepository;
  final AppointmentRepository _appointmentRepository;
  final UserModel _user;
  final String doctorId;

  Future<void> _onStarted(
    BookingStarted event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingState(status: BookingStatus.loading));
    try {
      final doctor = await _doctorRepository.getDoctorById(doctorId);
      emit(
        BookingState(
          status: BookingStatus.ready,
          doctor: doctor,
          patientName: _user.name,
          patientEmail: _user.email,
          patientPhone: _user.phone,
        ),
      );
      add(BookingDateSelected(DateTime.now()));
    } catch (_) {
      emit(
        const BookingState(
          status: BookingStatus.failure,
          errorMessage: 'Unable to start the booking. Please try again.',
        ),
      );
    }
  }

  Future<void> _onDateSelected(
    BookingDateSelected event,
    Emitter<BookingState> emit,
  ) async {
    final date = DateTime(event.date.year, event.date.month, event.date.day);
    if (_isPastDate(date)) {
      emit(
        state.copyWith(
          status: BookingStatus.ready,
          errorMessage: 'Please choose today or a future date.',
          clearSelectedSlot: true,
        ),
      );
      return;
    }
    final doctor = state.doctor;
    if (doctor == null) return;

    emit(
      state.copyWith(
        status: BookingStatus.ready,
        selectedDate: date,
        slots: const [],
        clearSelectedSlot: true,
        clearError: true,
        isSlotLoading: true,
      ),
    );
    try {
      final slots = await _doctorRepository.getAvailableSlots(
        doctorId: doctor.id,
        date: date,
      );
      emit(
        state.copyWith(
          slots: slots,
          isSlotLoading: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSlotLoading: false,
          errorMessage: 'Unable to load time slots. Please try another date.',
        ),
      );
    }
  }

  void _onSlotSelected(BookingSlotSelected event, Emitter<BookingState> emit) {
    final slot =
        state.slots.where((slot) => slot.id == event.slotId).firstOrNull;
    if (slot == null || slot.isBooked) {
      emit(
        state.copyWith(
          errorMessage: 'This time slot is no longer available.',
          clearSelectedSlot: true,
        ),
      );
      return;
    }
    emit(state.copyWith(selectedSlot: slot, clearError: true));
  }

  void _onPatientDetailsUpdated(
    BookingPatientDetailsUpdated event,
    Emitter<BookingState> emit,
  ) {
    final errors = Map<String, String>.from(state.fieldErrors);
    if (event.name != null) errors.remove('name');
    if (event.email != null) errors.remove('email');
    if (event.phone != null) errors.remove('phone');
    if (event.reason != null) errors.remove('reason');
    emit(
      state.copyWith(
        patientName: event.name,
        patientEmail: event.email,
        patientPhone: event.phone,
        reason: event.reason,
        fieldErrors: errors,
        clearError: true,
      ),
    );
  }

  void _onContinueRequested(
    BookingContinueRequested event,
    Emitter<BookingState> emit,
  ) {
    if (state.step == BookingStep.dateAndSlot) {
      if (state.selectedSlot == null || state.selectedSlot!.isBooked) {
        emit(state.copyWith(
            errorMessage: 'Please select an available time slot.'));
        return;
      }
      emit(state.copyWith(step: BookingStep.patientDetails, clearError: true));
      return;
    }
    if (state.step == BookingStep.patientDetails) {
      final errors = _patientValidationErrors();
      if (errors.isNotEmpty) {
        emit(state.copyWith(fieldErrors: errors));
        return;
      }
      emit(
        state.copyWith(
          step: BookingStep.summary,
          fieldErrors: const {},
          clearError: true,
        ),
      );
    }
  }

  void _onBackRequested(
      BookingBackRequested event, Emitter<BookingState> emit) {
    switch (state.step) {
      case BookingStep.patientDetails:
        emit(state.copyWith(step: BookingStep.dateAndSlot, clearError: true));
        return;
      case BookingStep.summary:
        emit(
            state.copyWith(step: BookingStep.patientDetails, clearError: true));
        return;
      case BookingStep.dateAndSlot:
      case BookingStep.success:
        return;
    }
  }

  Future<void> _onConfirmationRequested(
    BookingConfirmationRequested event,
    Emitter<BookingState> emit,
  ) async {
    final doctor = state.doctor;
    final date = state.selectedDate;
    final slot = state.selectedSlot;
    final errors = _patientValidationErrors();
    if (doctor == null || date == null || slot == null) {
      emit(
        state.copyWith(
          step: BookingStep.dateAndSlot,
          errorMessage: 'Please select an available date and time slot.',
          clearSelectedSlot: true,
        ),
      );
      return;
    }
    if (errors.isNotEmpty) {
      emit(
        state.copyWith(
          step: BookingStep.patientDetails,
          fieldErrors: errors,
        ),
      );
      return;
    }

    emit(state.copyWith(status: BookingStatus.submitting, clearError: true));
    try {
      final available = await _appointmentRepository.isSlotAvailable(
        doctorId: doctor.id,
        timeSlotId: slot.id,
      );
      if (!available) {
        emit(
          state.copyWith(
            status: BookingStatus.ready,
            step: BookingStep.dateAndSlot,
            errorMessage:
                'That slot has just been booked. Please choose another.',
            clearSelectedSlot: true,
          ),
        );
        return;
      }

      final appointment = await _appointmentRepository.createAppointment(
        AppointmentModel(
          userId: _user.id,
          doctorId: doctor.id,
          doctorName: doctor.name,
          doctorImageUrl: doctor.imageUrl,
          date: date,
          timeSlotId: slot.id,
          startTime: slot.startTime,
          endTime: slot.endTime,
          patientName: state.patientName.trim(),
          patientEmail: state.patientEmail.trim(),
          patientAge: 0,
          patientGender: Gender.other,
          patientPhone: state.patientPhone.trim(),
          reason: state.reason.trim(),
          fee: doctor.consultationFee,
          status: AppointmentStatus.upcoming,
          createdAt: DateTime.now(),
        ),
      );
      emit(
        state.copyWith(
          status: BookingStatus.success,
          step: BookingStep.success,
          confirmedAppointment: appointment,
        ),
      );
    } on BookingConflictException catch (error) {
      emit(
        state.copyWith(
          status: BookingStatus.ready,
          step: BookingStep.dateAndSlot,
          errorMessage: error.message,
          clearSelectedSlot: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          errorMessage: 'We could not confirm your booking. Please try again.',
        ),
      );
    }
  }

  Map<String, String> _patientValidationErrors() {
    final errors = <String, String>{};
    if (state.patientName.trim().length < 2) {
      errors['name'] = 'Enter your full name.';
    }
    final email = state.patientEmail.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      errors['email'] = 'Enter a valid email address.';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(state.patientPhone.trim())) {
      errors['phone'] = 'Enter a valid 10-digit mobile number.';
    }
    if (state.reason.trim().isEmpty) {
      errors['reason'] = 'Tell us the reason for your visit.';
    }
    return errors;
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }
}
