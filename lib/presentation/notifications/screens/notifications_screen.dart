import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/presentation/notifications/cubit/notifications_cubit.dart';
import 'package:appointment_booking_app/presentation/notifications/cubit/notifications_state.dart';
import 'package:appointment_booking_app/presentation/notifications/widgets/notification_item.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationsCubit, NotificationsState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      ),
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            if (state.unreadCount > 0)
              TextButton(
                onPressed: context.read<NotificationsCubit>().markAllAsRead,
                child: const Text('Mark all read'),
              ),
          ],
        ),
        body: _NotificationsBody(state: state),
      ),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody({required this.state});

  final NotificationsState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == NotificationsStatus.loading &&
        state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == NotificationsStatus.failure &&
        state.notifications.isEmpty) {
      return _NotificationError(
        onRetry: context.read<NotificationsCubit>().load,
      );
    }
    return RefreshIndicator(
      onRefresh: context.read<NotificationsCubit>().load,
      child: state.notifications.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 52),
                      SizedBox(height: AppSpacing.md),
                      Text('No notifications yet'),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return NotificationItem(
                  notification: notification,
                  onTap: () => context
                      .read<NotificationsCubit>()
                      .markAsRead(notification),
                );
              },
            ),
    );
  }
}

class _NotificationError extends StatelessWidget {
  const _NotificationError({required this.onRetry});

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
