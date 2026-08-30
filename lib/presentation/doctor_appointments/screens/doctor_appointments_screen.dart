import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/data/models/appointment_model.dart';
import 'package:appointment_booking_app/presentation/doctor_appointments/cubit/doctor_appointments_cubit.dart';
import 'package:appointment_booking_app/presentation/doctor_appointments/cubit/doctor_appointments_state.dart';
import 'package:appointment_booking_app/presentation/doctor_appointments/widgets/doctor_appointment_card.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: BlocConsumer<DoctorAppointmentsCubit, DoctorAppointmentsState>(
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
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Patient appointments'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Today'),
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          body: _DoctorAppointmentsBody(state: state),
        ),
      ),
    );
  }
}

class _DoctorAppointmentsBody extends StatelessWidget {
  const _DoctorAppointmentsBody({required this.state});

  final DoctorAppointmentsState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == DoctorAppointmentsStatus.loading &&
        state.today.isEmpty &&
        state.upcoming.isEmpty &&
        state.completed.isEmpty &&
        state.cancelled.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == DoctorAppointmentsStatus.failure &&
        state.today.isEmpty &&
        state.upcoming.isEmpty &&
        state.completed.isEmpty &&
        state.cancelled.isEmpty) {
      return Center(
        child: ElevatedButton(
          onPressed: context.read<DoctorAppointmentsCubit>().load,
          child: const Text('Try again'),
        ),
      );
    }
    return TabBarView(
      children: [
        _AppointmentList(
          appointments: state.today,
          emptyMessage: 'No appointments today',
          state: state,
        ),
        _AppointmentList(
          appointments: state.upcoming,
          emptyMessage: 'No upcoming appointments',
          state: state,
        ),
        _AppointmentList(
          appointments: state.completed,
          emptyMessage: 'No completed appointments',
          state: state,
        ),
        _AppointmentList(
          appointments: state.cancelled,
          emptyMessage: 'No cancelled appointments',
          state: state,
        ),
      ],
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({
    required this.appointments,
    required this.emptyMessage,
    required this.state,
  });

  final List<AppointmentModel> appointments;
  final String emptyMessage;
  final DoctorAppointmentsState state;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<DoctorAppointmentsCubit>().load,
      child: appointments.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: Text(emptyMessage)),
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
                final canComplete =
                    appointment.status == AppointmentStatus.upcoming;
                final canCancel =
                    appointment.status == AppointmentStatus.upcoming;
                return DoctorAppointmentCard(
                  appointment: appointment,
                  isUpdating: state.updatingBookingId == appointment.bookingId,
                  onComplete: canComplete
                      ? () => context
                          .read<DoctorAppointmentsCubit>()
                          .complete(appointment)
                      : null,
                  onCancel: canCancel
                      ? () => _confirmCancellation(context, appointment)
                      : null,
                );
              },
            ),
    );
  }

  Future<void> _confirmCancellation(
    BuildContext context,
    AppointmentModel appointment,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content:
            Text('Cancel the appointment with ${appointment.patientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (approved == true && context.mounted) {
      await context.read<DoctorAppointmentsCubit>().cancel(appointment);
    }
  }
}
