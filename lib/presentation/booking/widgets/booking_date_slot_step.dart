import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_bloc.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_event.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_state.dart';

class BookingDateSlotStep extends StatelessWidget {
  const BookingDateSlotStep({super.key});

  Future<void> _selectDate(BuildContext context, BookingState state) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate:
          state.selectedDate == null || state.selectedDate!.isBefore(now)
              ? now
              : state.selectedDate!,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
    );
    if (selected != null && context.mounted) {
      context.read<BookingBloc>().add(BookingDateSelected(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final doctor = state.doctor;
        if (doctor == null) return const SizedBox.shrink();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Choose a date and time',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Booking with ${doctor.name}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.calendar_today_outlined),
                  ),
                  title: const Text('Appointment date'),
                  subtitle: Text(
                    state.selectedDate == null
                        ? 'Choose a date to see availability'
                        : MaterialLocalizations.of(context).formatMediumDate(
                            state.selectedDate!,
                          ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectDate(context, state),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Text('Available time slots',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  if (state.selectedDate != null)
                    Text(
                      '${state.slots.where((slot) => !slot.isBooked).length} open',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.isSlotLoading)
                const Center(child: CircularProgressIndicator())
              else if (state.selectedDate == null || state.slots.isEmpty)
                const _NoSlots()
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: state.slots
                      .map(
                        (slot) => ChoiceChip(
                          avatar: Icon(
                            slot.isBooked
                                ? Icons.lock_outline
                                : state.selectedSlot?.id == slot.id
                                    ? Icons.check_circle_outline
                                    : Icons.schedule_outlined,
                            size: 16,
                          ),
                          label: Text(
                            slot.isBooked
                                ? '${slot.startTime} · Booked'
                                : '${slot.startTime} – ${slot.endTime}',
                          ),
                          selected: state.selectedSlot?.id == slot.id,
                          selectedColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          onSelected: slot.isBooked
                              ? null
                              : (_) => context.read<BookingBloc>().add(
                                    BookingSlotSelected(slot.id),
                                  ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: state.isSlotLoading
                    ? null
                    : () => context.read<BookingBloc>().add(
                          const BookingContinueRequested(),
                        ),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NoSlots extends StatelessWidget {
  const _NoSlots();

  @override
  Widget build(BuildContext context) => const Text(
        'No time slots are available on this date. Please choose another day.',
      );
}
