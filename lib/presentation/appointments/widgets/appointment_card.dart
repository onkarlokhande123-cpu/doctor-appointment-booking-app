import 'package:flutter/material.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/core/theme/app_colors.dart';
import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/presentation/home/widgets/doctor_avatar.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onDetails,
    this.onCancel,
    this.isCancelling = false,
  });

  final AppointmentModel appointment;
  final VoidCallback onDetails;
  final VoidCallback? onCancel;
  final bool isCancelling;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final date = MaterialLocalizations.of(context).formatMediumDate(
      appointment.date,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DoctorAvatar(imageUrl: appointment.doctorImageUrl, radius: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.doctorName, style: textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      _StatusChip(status: appointment.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  _DetailLine(icon: Icons.calendar_today_outlined, text: date),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailLine(
                    icon: Icons.schedule_outlined,
                    text: '${appointment.startTime} – ${appointment.endTime}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailLine(
                    icon: Icons.currency_rupee,
                    text:
                        'Consultation fee: ₹${appointment.fee.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Booking reference · ${appointment.bookingId ?? 'Pending'}',
              style: textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                TextButton(onPressed: onDetails, child: const Text('Details')),
                const Spacer(),
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: isCancelling ? null : onCancel,
                    icon: isCancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      AppointmentStatus.upcoming => ('Upcoming', AppColors.upcomingStatus),
      AppointmentStatus.completed => ('Completed', AppColors.completedStatus),
      AppointmentStatus.cancelled => ('Cancelled', AppColors.cancelledStatus),
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      avatar: Icon(Icons.circle, color: color, size: 10),
      label: Text(label),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text)),
      ],
    );
  }
}
