import '../../data/models/app_notification_model.dart';

abstract class NotificationRepository {
  Future<List<AppNotificationModel>> getNotifications();

  Future<void> markAsRead(String notificationId);
}
