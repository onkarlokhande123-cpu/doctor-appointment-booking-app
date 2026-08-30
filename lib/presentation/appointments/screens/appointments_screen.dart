import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/presentation/appointments/bloc/appointment_list_bloc.dart';
import 'package:appointment_booking_app/presentation/appointments/bloc/appointment_list_event.dart';
import 'package:appointment_booking_app/presentation/appointments/bloc/appointment_list_state.dart';
import 'package:appointment_booking_app/presentation/appointments/widgets/appointment_card.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: BlocConsumer<AppointmentListBloc, AppointmentListState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage ||
            previous.successMessage != current.successMessage,
        listener: (context, state) {
          final message = state.errorMessage ?? state.successMessage;
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My appointments'),
              titleTextStyle: Theme.of(context).textTheme.titleLarge,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
            body: _AppointmentBody(state: state),
          );
        },
      ),
    );
  }
}

class _AppointmentBody extends StatelessWidget {
  const _AppointmentBody({required this.state});

  final AppointmentListState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == AppointmentListStatus.loading &&
        state.upcoming.isEmpty &&
        state.completed.isEmpty &&
        state.cancelled.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == AppointmentListStatus.failure &&
        state.upcoming.isEmpty &&
        state.completed.isEmpty &&
        state.cancelled.isEmpty) {
      return _LoadError(
        onRetry: () => context.read<AppointmentListBloc>().add(
              const AppointmentListRefreshRequested(),
            ),
      );
    }
    return TabBarView(
      children: [
        _AppointmentList(
          appointments: state.upcoming,
          emptyMessage: 'No upcoming appointments',
          isCancelling: (appointment) =>
              state.cancellingBookingId == appointment.bookingId,
          onCancel: (appointment) => _confirmCancellation(context, appointment),
        ),
        _AppointmentList(
          appointments: state.completed,
          emptyMessage: 'No completed appointments yet',
        ),
        _AppointmentList(
          appointments: state.cancelled,
          emptyMessage: 'No cancelled appointments',
        ),
      ],
    );
  }

  Future<void> _confirmCancellation(
    BuildContext context,
    AppointmentModel appointment,
  ) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text(
          'This will cancel your appointment with ${appointment.doctorName} and release the selected time slot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep appointment'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (shouldCancel == true &&
        context.mounted &&
        appointment.bookingId != null) {
      context.read<AppointmentListBloc>().add(
            AppointmentCancellationRequested(appointment.bookingId!),
          );
    }
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({
    required this.appointments,
    required this.emptyMessage,
    this.onCancel,
    this.isCancelling,
  });

  final List<AppointmentModel> appointments;
  final String emptyMessage;
  final ValueChanged<AppointmentModel>? onCancel;
  final bool Function(AppointmentModel)? isCancelling;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => context.read<AppointmentListBloc>().add(
            const AppointmentListRefreshRequested(),
          ),
      child: appointments.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 52),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        emptyMessage,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('Pull down to refresh your appointments.'),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: appointments.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return AppointmentCard(
                  appointment: appointment,
                  onDetails: () => _showDetails(context, appointment),
                  onCancel:
                      onCancel == null ? null : () => onCancel!(appointment),
                  isCancelling: isCancelling?.call(appointment) ?? false,
                );
              },
            ),
    );
  }

  void _showDetails(BuildContext context, AppointmentModel appointment) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appointment.doctorName,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Text('Reason for visit: ${appointment.reason}'),
            const SizedBox(height: AppSpacing.sm),
            Text('Patient: ${appointment.patientName}'),
            const SizedBox(height: AppSpacing.sm),
            Text('Booking ID: ${appointment.bookingId ?? 'Pending'}'),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 52),
            const SizedBox(height: AppSpacing.md),
            Text('Could not load appointments',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
