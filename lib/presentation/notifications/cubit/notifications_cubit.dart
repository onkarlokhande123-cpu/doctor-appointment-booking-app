import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/data/models/notification_model.dart';
import 'package:appointment_booking_app/data/models/user_model.dart';
import 'package:appointment_booking_app/data/repositories/notification_repository.dart';
import 'package:appointment_booking_app/presentation/notifications/cubit/notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required NotificationRepository notificationRepository,
    required UserModel user,
  })  : _notificationRepository = notificationRepository,
        _user = user,
        super(const NotificationsState()) {
    load();
  }

  final NotificationRepository _notificationRepository;
  final UserModel _user;

  Future<void> load() async {
    emit(
      state.copyWith(status: NotificationsStatus.loading, clearError: true),
    );
    try {
      final notifications = await _notificationRepository.getNotifications(
        _user.id,
      );
      emit(
        state.copyWith(
          status: NotificationsStatus.success,
          notifications: notifications,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          errorMessage: 'Unable to load notifications. Please try again.',
        ),
      );
    }
  }

  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead || notification.userId != _user.id) return;
    try {
      await _notificationRepository.markAsRead(notification.id);
      _replaceNotification(notification.copyWith(isRead: true));
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage: 'Unable to update this notification. Please try again.',
        ),
      );
    }
  }

  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0) return;
    try {
      await _notificationRepository.markAllAsRead(_user.id);
      emit(
        state.copyWith(
          notifications: state.notifications
              .map((notification) => notification.copyWith(isRead: true))
              .toList(),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage: 'Unable to update notifications. Please try again.',
        ),
      );
    }
  }

  void _replaceNotification(NotificationModel updated) {
    emit(
      state.copyWith(
        notifications: state.notifications
            .map(
              (notification) =>
                  notification.id == updated.id ? updated : notification,
            )
            .toList(),
      ),
    );
  }
}
