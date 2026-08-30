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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() {
    return context.read<AuthCubit>().register(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          confirmation: _confirmationController.text,
        );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) => _showError(context, state.errorMessage!),
      builder: (context, state) {
        return AuthPageScaffold(
          title: 'Create your account',
          subtitle: 'Book appointments with doctors you trust.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _nameController,
                  label: 'Full name',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  errorText: state.fieldErrors['name'],
                  onChanged: (_) =>
                      context.read<AuthCubit>().clearFieldError('name'),
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  controller: _emailController,
                  label: 'Email address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  errorText: state.fieldErrors['email'],
                  onChanged: (_) =>
                      context.read<AuthCubit>().clearFieldError('email'),
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  controller: _phoneController,
                  label: 'Mobile number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  errorText: state.fieldErrors['phone'],
                  onChanged: (_) =>
                      context.read<AuthCubit>().clearFieldError('phone'),
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  obscureText: _obscurePassword,
                  errorText: state.fieldErrors['password'],
                  onChanged: (_) =>
                      context.read<AuthCubit>().clearFieldError('password'),
                  suffixIcon: IconButton(
                    tooltip:
                        _obscurePassword ? 'Show password' : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  controller: _confirmationController,
                  label: 'Confirm password',
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.done,
                  obscureText: _obscureConfirmation,
                  errorText: state.fieldErrors['confirmation'],
                  onChanged: (_) =>
                      context.read<AuthCubit>().clearFieldError('confirmation'),
                  onFieldSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirmation
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () => setState(
                      () => _obscureConfirmation = !_obscureConfirmation,
                    ),
                    icon: Icon(
                      _obscureConfirmation
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AuthSubmitButton(
                  label: 'Create account',
                  isLoading: state.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () => context.go(AppRoutes.login),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
