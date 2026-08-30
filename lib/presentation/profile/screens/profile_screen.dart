import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/data/models/user_model.dart';
import 'package:appointment_booking_app/presentation/auth/cubit/auth_cubit.dart';
import 'package:appointment_booking_app/presentation/auth/widgets/auth_text_field.dart';
import 'package:appointment_booking_app/presentation/profile/cubit/profile_cubit.dart';
import 'package:appointment_booking_app/presentation/profile/cubit/profile_state.dart';
import 'package:appointment_booking_app/presentation/profile/widgets/profile_avatar.dart';
import 'package:appointment_booking_app/presentation/profile/widgets/profile_info_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
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
        if (state.status == ProfileStatus.success) {
          setState(() => _isEditing = false);
        }
      },
      builder: (context, state) {
        final user = state.user;
        return Scaffold(
          appBar: AppBar(
            title: const Text('My profile'),
            actions: [
              if (user != null && !_isEditing)
                IconButton(
                  tooltip: 'Edit profile',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => setState(() => _isEditing = true),
                ),
            ],
          ),
          body: switch (state.status) {
            ProfileStatus.initial ||
            ProfileStatus.loading when user == null =>
              const Center(child: CircularProgressIndicator()),
            ProfileStatus.failure when user == null => _ProfileError(
                onRetry: context.read<ProfileCubit>().load,
              ),
            _ when user != null => _isEditing
                ? _ProfileEditor(user: user)
                : _ProfileDetails(
                    user: user,
                    onEdit: () => setState(() => _isEditing = true),
                  ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.user, required this.onEdit});

  final UserModel user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  ProfileAvatar(
                      imageUrl: user.profileImageUrl, name: user.name),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Contact details',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  ProfileInfoTile(
                    icon: Icons.person_outline,
                    label: 'Full name',
                    value: user.name,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Divider(),
                  ),
                  ProfileInfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email address',
                    value: user.email,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Divider(),
                  ),
                  ProfileInfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Mobile number',
                    value: user.phone,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit profile'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
            'You will need to sign in again to access your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && context.mounted) {
      await context.read<AuthCubit>().logout();
    }
  }
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({required this.user});

  final UserModel user;

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _imageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _imageController = TextEditingController(text: widget.user.profileImageUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit profile',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xl),
            AuthTextField(
              controller: _nameController,
              label: 'Full name',
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              errorText: state.fieldErrors['name'],
              onChanged: (_) {},
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: widget.user.email,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
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
              onChanged: (_) {},
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              controller: _imageController,
              label: 'Profile image URL (optional)',
              prefixIcon: Icons.image_outlined,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              errorText: state.fieldErrors['image'],
              onChanged: (_) {},
              onFieldSubmitted: (_) => _save(context),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: state.isSaving ? null : () => _save(context),
              child: state.isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    context.read<ProfileCubit>().save(
          name: _nameController.text,
          phone: _phoneController.text,
          profileImageUrl: _imageController.text,
        );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      );
}
