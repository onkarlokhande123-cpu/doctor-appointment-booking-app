import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/presentation/auth/widgets/auth_text_field.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_bloc.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_event.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_state.dart';

class PatientDetailsStep extends StatefulWidget {
  const PatientDetailsStep({super.key});

  @override
  State<PatientDetailsStep> createState() => _PatientDetailsStepState();
}

class _PatientDetailsStepState extends State<PatientDetailsStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    final state = context.read<BookingBloc>().state;
    _nameController = TextEditingController(text: state.patientName);
    _emailController = TextEditingController(text: state.patientEmail);
    _phoneController = TextEditingController(text: state.patientPhone);
    _reasonController = TextEditingController(text: state.reason);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Patient details',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              const Text('These details will be shared with the clinic.'),
              const SizedBox(height: AppSpacing.xl),
              AuthTextField(
                controller: _nameController,
                label: 'Full name',
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                errorText: state.fieldErrors['name'],
                onChanged: (value) => context.read<BookingBloc>().add(
                      BookingPatientDetailsUpdated(name: value),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                controller: _emailController,
                label: 'Email address',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: state.fieldErrors['email'],
                onChanged: (value) => context.read<BookingBloc>().add(
                      BookingPatientDetailsUpdated(email: value),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                controller: _phoneController,
                label: 'Mobile number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                errorText: state.fieldErrors['phone'],
                onChanged: (value) => context.read<BookingBloc>().add(
                      BookingPatientDetailsUpdated(phone: value),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _reasonController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.done,
                onChanged: (value) => context.read<BookingBloc>().add(
                      BookingPatientDetailsUpdated(reason: value),
                    ),
                decoration: InputDecoration(
                  labelText: 'Reason for visit',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 56),
                    child: Icon(Icons.notes_outlined),
                  ),
                  errorText: state.fieldErrors['reason'],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: () => context.read<BookingBloc>().add(
                      const BookingContinueRequested(),
                    ),
                child: const Text('Review booking'),
              ),
            ],
          ),
        );
      },
    );
  }
}
