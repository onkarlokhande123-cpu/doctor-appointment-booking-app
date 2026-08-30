import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/data/models/notification_model.dart';
import 'package:appointment_booking_app/data/repositories/notification_repository.dart';

/// In-memory notification store scoped by the notification owner.
class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository({this.seedDefaults = true});

  final bool seedDefaults;
  final Map<String, NotificationModel> _notificationsById = {};

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    _seedForUser(userId);
    return _notificationsById.values
        .where((notification) => notification.userId == userId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    final notifications = await getNotifications(userId);
    return notifications.where((notification) => !notification.isRead).length;
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    for (final notification in _notificationsById.values
        .where((item) => item.userId == userId)
        .toList()) {
      _notificationsById[notification.id] = notification.copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final notification = _notificationsById[notificationId];
    if (notification == null) throw StateError('Notification not found.');
    _notificationsById[notificationId] = notification.copyWith(isRead: true);
  }

  void _seedForUser(String userId) {
    if (!seedDefaults ||
        _notificationsById.values.any((item) => item.userId == userId)) {
      return;
    }
    final now = DateTime.now();
    final notifications = [
      NotificationModel(
        id: '${userId}_welcome',
        userId: userId,
        type: NotificationType.general,
        title: 'Welcome to MediCare',
        message:
            'Find doctors, book appointments, and manage your care in one place.',
        timestamp: now,
      ),
      NotificationModel(
        id: '${userId}_tips',
        userId: userId,
        type: NotificationType.reminder,
        title: 'Keep your details up to date',
        message: 'Accurate contact information helps clinics reach you easily.',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
    for (final notification in notifications) {
      _notificationsById[notification.id] = notification;
    }
  }
}
