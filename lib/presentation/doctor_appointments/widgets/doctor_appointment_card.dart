import 'package:flutter/material.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/core/theme/app_colors.dart';
import 'package:appointment_booking_app/data/models/appointment_model.dart';

class DoctorAppointmentCard extends StatelessWidget {
  const DoctorAppointmentCard({
    super.key,
    required this.appointment,
    this.onComplete,
    this.onCancel,
    this.isUpdating = false,
  });

  final AppointmentModel appointment;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context).formatMediumDate(
      appointment.date,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    appointment.patientName.isEmpty
                        ? '?'
                        : appointment.patientName[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(appointment.patientPhone),
                    ],
                  ),
                ),
                _StatusChip(status: appointment.status),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('$date · ${appointment.startTime} – ${appointment.endTime}'),
            const SizedBox(height: AppSpacing.sm),
            Text('Reason: ${appointment.reason}'),
            if (onComplete != null || onCancel != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (onComplete != null)
                    TextButton.icon(
                      onPressed: isUpdating ? null : onComplete,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Complete'),
                    ),
                  const Spacer(),
                  if (onCancel != null)
                    TextButton.icon(
                      onPressed: isUpdating ? null : onCancel,
                      icon: isUpdating
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel'),
                    ),
                ],
              ),
            ],
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
      avatar: Icon(Icons.circle, color: color, size: 10),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}
