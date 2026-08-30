import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/core/routes/app_routes.dart';
import 'package:appointment_booking_app/data/models/doctor_model.dart';
import 'package:appointment_booking_app/presentation/doctor_details/cubit/doctor_details_cubit.dart';
import 'package:appointment_booking_app/presentation/doctor_details/cubit/doctor_details_state.dart';
import 'package:appointment_booking_app/presentation/home/widgets/doctor_avatar.dart';

class DoctorDetailsScreen extends StatelessWidget {
  const DoctorDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor details')),
      body: BlocBuilder<DoctorDetailsCubit, DoctorDetailsState>(
        builder: (context, state) {
          if (state.status == DoctorDetailsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == DoctorDetailsStatus.failure ||
              state.doctor == null) {
            return _DetailsError(
                onRetry: context.read<DoctorDetailsCubit>().load);
          }
          return _DoctorDetailsContent(state: state);
        },
      ),
    );
  }
}

class _DoctorDetailsContent extends StatelessWidget {
  const _DoctorDetailsContent({required this.state});

  final DoctorDetailsState state;

  @override
  Widget build(BuildContext context) {
    final doctor = state.doctor!;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        DoctorAvatar(imageUrl: doctor.imageUrl, radius: 56),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          doctor.name,
                          style: textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Chip(
                          avatar: const Icon(Icons.verified_outlined, size: 16),
                          label: Text(doctor.specialtyName),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _StatsRow(doctor: doctor),
                const SizedBox(height: AppSpacing.lg),
                const _SectionTitle(title: 'About doctor'),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(doctor.bio, style: textTheme.bodyLarge),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _SectionTitle(title: 'Clinic location'),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _DetailLine(
                      icon: Icons.location_on_outlined,
                      text: doctor.clinicAddress,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _SectionTitle(title: 'Available days'),
                const SizedBox(height: AppSpacing.sm),
                if (doctor.availableDays.isEmpty)
                  const Text('No upcoming availability is listed.')
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: doctor.availableDays
                        .map((day) => Chip(label: Text(day)))
                        .toList(),
                  ),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(
                  title: state.slotDate == null
                      ? 'Available time slots'
                      : 'Time slots · ${MaterialLocalizations.of(context).formatMediumDate(state.slotDate!)}',
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state.slots.isEmpty)
                  const Text(
                      'No time slots are available for the next clinic day.')
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: state.slots
                        .map(
                          (slot) => Chip(
                            backgroundColor: slot.isBooked
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                : Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                            avatar: Icon(
                              slot.isBooked
                                  ? Icons.lock_outline
                                  : Icons.schedule,
                              size: 16,
                            ),
                            label: Text(
                              '${slot.startTime} – ${slot.endTime}${slot.isBooked ? ' · Booked' : ''}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.bookingPath(doctor.id)),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              'Book appointment · ₹${doctor.consultationFee.toStringAsFixed(0)}',
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Stat(
            icon: Icons.star_rounded,
            value: doctor.rating.toStringAsFixed(1),
            label: 'Rating',
          ),
        ),
        Expanded(
          child: _Stat(
            icon: Icons.work_outline,
            value: '${doctor.experienceYears}',
            label: 'Years experience',
          ),
        ),
        Expanded(
          child: _Stat(
            icon: Icons.currency_rupee,
            value: doctor.consultationFee.toStringAsFixed(0),
            label: 'Consultation',
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleLarge);
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: AppSpacing.md),
          const Text('Unable to load doctor details.'),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
