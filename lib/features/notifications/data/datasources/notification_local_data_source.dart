import '../models/app_notification_model.dart';

abstract class NotificationLocalDataSource {
  Future<List<AppNotificationModel>> getNotifications();

  Future<void> markAsRead(String notificationId);
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  NotificationLocalDataSourceImpl({DateTime? seedDate})
      : _seedDate = seedDate ?? DateTime.now();

  final DateTime _seedDate;
  List<AppNotificationModel>? _notifications;

  @override
  Future<List<AppNotificationModel>> getNotifications() async {
    _notifications ??= _buildInitialNotifications(_seedDate);
    return List<AppNotificationModel>.unmodifiable(_notifications!);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final List<AppNotificationModel> current = await getNotifications();
    _notifications = current.map((AppNotificationModel notification) {
      if (notification.id != notificationId || notification.isRead) {
        return notification;
      }

      return notification.copyWith(isRead: true);
    }).toList(growable: false);
  }

  List<AppNotificationModel> _buildInitialNotifications(DateTime now) {
    return <AppNotificationModel>[
      AppNotificationModel(
        id: 'notification-expense-alex',
        title: 'Alex menambahkan pengeluaran baru',
        description: 'Makan malam sudah ditambahkan ke grup Weekend Dinner.',
        type: AppNotificationType.expense,
        createdAt: now.subtract(const Duration(hours: 2, minutes: 15)),
        isRead: false,
      ),
      AppNotificationModel(
        id: 'notification-invite-apartment',
        title: 'Kamu diundang ke grup Apartment 4B',
        description: 'Lihat anggota grup dan mulai mencatat tagihan bersama.',
        type: AppNotificationType.invitation,
        createdAt: now.subtract(const Duration(hours: 5, minutes: 40)),
        isRead: false,
      ),
      AppNotificationModel(
        id: 'notification-bill-euro-trip',
        title: 'Euro Trip 2024 memiliki tagihan baru',
        description: 'Tagihan hotel sudah siap untuk dibagi dengan anggota.',
        type: AppNotificationType.bill,
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
        isRead: true,
      ),
      AppNotificationModel(
        id: 'notification-payment-jordan',
        title: 'Jordan membayar hutang',
        description: 'Pembayaran dicatat dan saldo grup diperbarui.',
        type: AppNotificationType.payment,
        createdAt: now.subtract(const Duration(days: 9, hours: 1)),
        isRead: true,
      ),
    ];
  }
}
