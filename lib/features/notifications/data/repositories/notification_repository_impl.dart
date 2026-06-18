import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_data_source.dart';
import '../models/app_notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({
    required NotificationLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final NotificationLocalDataSource _localDataSource;

  @override
  Future<List<AppNotificationModel>> getNotifications() {
    return _localDataSource.getNotifications();
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _localDataSource.markAsRead(notificationId);
  }
}
