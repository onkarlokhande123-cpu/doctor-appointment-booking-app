import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/core/routes/app_routes.dart';
import 'package:appointment_booking_app/presentation/auth/cubit/auth_cubit.dart';
import 'package:appointment_booking_app/presentation/doctor_dashboard/cubit/doctor_dashboard_cubit.dart';
import 'package:appointment_booking_app/presentation/doctor_dashboard/cubit/doctor_dashboard_state.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = context.select<AuthCubit, String?>(
      (cubit) => cubit.state.user?.name,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor dashboard'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push(AppRoutes.profile),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: BlocBuilder<DoctorDashboardCubit, DoctorDashboardState>(
        builder: (context, state) {
          if (state.status == DoctorDashboardStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == DoctorDashboardStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 52),
                    const SizedBox(height: AppSpacing.md),
                    Text(state.errorMessage ?? 'Unable to load dashboard.'),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: context.read<DoctorDashboardCubit>().load,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          final doctor = state.doctor;
          return RefreshIndicator(
            onRefresh: context.read<DoctorDashboardCubit>().load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Hello${userName == null ? '' : ', ${userName.split(' ').first}'}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  doctor == null
                      ? 'Manage your appointments.'
                      : '${doctor.specialtyName} · ${doctor.clinicAddress}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Today',
                        value: state.todayCount.toString(),
                        icon: Icons.today_outlined,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _MetricCard(
                        label: 'Upcoming',
                        value: state.upcomingCount.toString(),
                        icon: Icons.calendar_month_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s appointments',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          state.todayCount == 0
                              ? 'You have no appointments scheduled today.'
                              : '${state.todayCount} appointment${state.todayCount == 1 ? '' : 's'} scheduled today.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: () => context.push(
                            AppRoutes.doctorAppointments,
                          ),
                          icon: const Icon(Icons.list_alt_outlined),
                          label: const Text('View appointments'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
