import 'package:appointment_booking_app/data/models/notification_model.dart';

/// Contract for reading and updating a user's notifications.
abstract class NotificationRepository {
  /// Returns [userId]'s notifications, most recent first.
  Future<List<NotificationModel>> getNotifications(String userId);

  /// Marks a single notification as read.
  Future<void> markAsRead(String notificationId);

  /// Marks every notification belonging to [userId] as read
  /// (used by a "mark all as read" action).
  Future<void> markAllAsRead(String userId);

  /// Returns the count of unread notifications for [userId],
  /// used for a badge on the notifications icon.
  Future<int> getUnreadCount(String userId);
}
