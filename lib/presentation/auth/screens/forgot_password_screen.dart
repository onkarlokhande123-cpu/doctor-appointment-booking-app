import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/core/routes/app_routes.dart';
import 'package:appointment_booking_app/presentation/auth/cubit/auth_cubit.dart';
import 'package:appointment_booking_app/presentation/auth/cubit/auth_state.dart';
import 'package:appointment_booking_app/presentation/auth/widgets/auth_page_scaffold.dart';
import 'package:appointment_booking_app/presentation/auth/widgets/auth_submit_button.dart';
import 'package:appointment_booking_app/presentation/auth/widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() =>
      context.read<AuthCubit>().sendPasswordResetEmail(_emailController.text);

  void _showMessage(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message != null) {
          _showMessage(
            context,
            message,
            isError: state.errorMessage != null,
          );
        }
      },
      builder: (context, state) {
        return AuthPageScaffold(
          title: 'Reset your password',
          subtitle:
              'Enter your account email and we will prepare reset instructions.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _emailController,
                  label: 'Email address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  errorText: state.fieldErrors['email'],
                  onChanged: (_) =>
                      context.read<AuthCubit>().clearFieldError('email'),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                AuthSubmitButton(
                  label: 'Send reset instructions',
                  isLoading: state.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => context.go(AppRoutes.login),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
