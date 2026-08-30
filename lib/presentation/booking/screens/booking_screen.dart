import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:appointment_booking_app/presentation/booking/bloc/booking_bloc.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_event.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_state.dart';
import 'package:appointment_booking_app/presentation/booking/widgets/booking_date_slot_step.dart';
import 'package:appointment_booking_app/presentation/booking/widgets/booking_success_screen.dart';
import 'package:appointment_booking_app/presentation/booking/widgets/booking_summary_step.dart';
import 'package:appointment_booking_app/presentation/booking/widgets/patient_details_step.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingBloc, BookingState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        final isFirstStep = state.step == BookingStep.dateAndSlot;
        final isSuccess = state.step == BookingStep.success;
        return Scaffold(
          appBar: AppBar(
            title: Text(isSuccess ? 'Booking confirmed' : 'Book appointment'),
            leading: isSuccess
                ? null
                : IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (isFirstStep) {
                        context.pop();
                      } else {
                        context
                            .read<BookingBloc>()
                            .add(const BookingBackRequested());
                      }
                    },
                  ),
          ),
          body: switch (state.status) {
            BookingStatus.initial ||
            BookingStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            BookingStatus.failure when state.doctor == null => _BookingFailure(
                onRetry: () =>
                    context.read<BookingBloc>().add(const BookingStarted()),
              ),
            _ => switch (state.step) {
                BookingStep.dateAndSlot => const BookingDateSlotStep(),
                BookingStep.patientDetails => const PatientDetailsStep(),
                BookingStep.summary => const BookingSummaryStep(),
                BookingStep.success => const BookingSuccessScreen(),
              },
          },
        );
      },
    );
  }
}

class _BookingFailure extends StatelessWidget {
  const _BookingFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Try again'),
      ),
    );
  }
}
