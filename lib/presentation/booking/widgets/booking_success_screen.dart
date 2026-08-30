import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/core/routes/app_routes.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_bloc.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointment = context.select<BookingBloc, dynamic>(
      (bloc) => bloc.state.confirmedAppointment,
    );
    if (appointment == null) return const SizedBox.shrink();
    final date = MaterialLocalizations.of(context).formatMediumDate(
      appointment.date,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          CircleAvatar(
            radius: 44,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.check_rounded,
              size: 54,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Appointment confirmed',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your appointment has been reserved successfully.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appointment.doctorName,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  _ConfirmationLine(Icons.calendar_today_outlined, date),
                  const SizedBox(height: AppSpacing.sm),
                  _ConfirmationLine(
                    Icons.schedule_outlined,
                    '${appointment.startTime} – ${appointment.endTime}',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Divider(),
                  ),
                  Text('Booking reference',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  SelectableText(
                    appointment.bookingId ?? 'Pending',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () => context.pushReplacement(AppRoutes.appointments),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('View my appointments'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationLine extends StatelessWidget {
  const _ConfirmationLine(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label)),
        ],
      );
}
