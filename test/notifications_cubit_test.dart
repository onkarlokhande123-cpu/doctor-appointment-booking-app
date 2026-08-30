import 'package:flutter_test/flutter_test.dart';

import 'package:appointment_booking_app/data/models/notification_model.dart';
import 'package:appointment_booking_app/data/models/user_model.dart';
import 'package:appointment_booking_app/data/repositories/mock_notification_repository.dart';
import 'package:appointment_booking_app/data/repositories/notification_repository.dart';
import 'package:appointment_booking_app/presentation/notifications/cubit/notifications_cubit.dart';
import 'package:appointment_booking_app/presentation/notifications/cubit/notifications_state.dart';

void main() {
  final user = _user('user-a');

  test(
      'NotificationsCubit loads notifications scoped to the user and marks read',
      () async {
    final repository = MockNotificationRepository();
    final cubit = NotificationsCubit(
      notificationRepository: repository,
      user: user,
    );
    await _flush();

    expect(cubit.state.status, NotificationsStatus.success);
    expect(cubit.state.notifications, isNotEmpty);
    expect(
      cubit.state.notifications
          .every((notification) => notification.userId == user.id),
      isTrue,
    );
    final unread = cubit.state.notifications.firstWhere(
      (notification) => !notification.isRead,
    );

    await cubit.markAsRead(unread);

    expect(
      cubit.state.notifications
          .firstWhere((notification) => notification.id == unread.id)
          .isRead,
      isTrue,
    );
    await cubit.close();
  });

  test('NotificationsCubit supports empty and error states', () async {
    final emptyCubit = NotificationsCubit(
      notificationRepository: MockNotificationRepository(seedDefaults: false),
      user: user,
    );
    await _flush();
    expect(emptyCubit.state.status, NotificationsStatus.success);
    expect(emptyCubit.state.notifications, isEmpty);
    await emptyCubit.close();

    final failingCubit = NotificationsCubit(
      notificationRepository: _FailingNotificationRepository(),
      user: user,
    );
    await _flush();
    expect(failingCubit.state.status, NotificationsStatus.failure);
    expect(failingCubit.state.errorMessage, isNotNull);
    await failingCubit.close();
  });
}

UserModel _user(String id) => UserModel(
      id: id,
      name: 'Patient',
      email: '$id@example.com',
      phone: '9876543210',
      createdAt: DateTime(2026),
    );

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _FailingNotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationModel>> getNotifications(String userId) =>
      Future<List<NotificationModel>>.error(StateError('Repository failure'));

  @override
  Future<int> getUnreadCount(String userId) => throw UnimplementedError();

  @override
  Future<void> markAllAsRead(String userId) => throw UnimplementedError();

  @override
  Future<void> markAsRead(String notificationId) => throw UnimplementedError();
}
