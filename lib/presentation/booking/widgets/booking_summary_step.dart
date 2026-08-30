import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_bloc.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_event.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_state.dart';

class BookingSummaryStep extends StatelessWidget {
  const BookingSummaryStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final doctor = state.doctor;
        final date = state.selectedDate;
        final slot = state.selectedSlot;
        if (doctor == null || date == null || slot == null) {
          return const SizedBox.shrink();
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Review your booking',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              const Text('Please check the details before confirming.'),
              const SizedBox(height: AppSpacing.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Appointment details',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.md),
                      _SummaryLine(label: 'Doctor', value: doctor.name),
                      _SummaryLine(
                          label: 'Specialty', value: doctor.specialtyName),
                      _SummaryLine(
                        label: 'Date',
                        value: MaterialLocalizations.of(context)
                            .formatMediumDate(date),
                      ),
                      _SummaryLine(
                        label: 'Time',
                        value: '${slot.startTime} – ${slot.endTime}',
                      ),
                      _SummaryLine(label: 'Patient', value: state.patientName),
                      _SummaryLine(label: 'Email', value: state.patientEmail),
                      _SummaryLine(label: 'Mobile', value: state.patientPhone),
                      _SummaryLine(label: 'Reason', value: state.reason),
                      _SummaryLine(
                        label: 'Consultation fee',
                        value: '₹${doctor.consultationFee.toStringAsFixed(0)}',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Your selected slot will be checked again before confirmation.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () => context.read<BookingBloc>().add(
                          const BookingConfirmationRequested(),
                        ),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Confirm booking'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
