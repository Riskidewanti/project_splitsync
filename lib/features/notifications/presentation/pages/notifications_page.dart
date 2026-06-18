import 'package:flutter/material.dart';

import '../../../groups/presentation/pages/group_detail_page.dart';
import '../../data/datasources/notification_local_data_source.dart';
import '../../data/models/app_notification_model.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';
import '../widgets/notification_card.dart';
import '../widgets/notifications_empty_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, NotificationRepository? repository})
      : _repository = repository;

  final NotificationRepository? _repository;

  static const Color primaryColor = Color(0xFFC70F1B);
  static const Color backgroundColor = Color(0xFFFBF7F4);
  static const Color textDarkColor = Color(0xFF1F2933);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationRepository _repository =
      widget._repository ??
      NotificationRepositoryImpl(
        localDataSource: NotificationLocalDataSourceImpl(),
      );

  List<AppNotificationModel> _notifications = const <AppNotificationModel>[];
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<AppNotificationModel> notifications =
          await _repository.getNotifications();
      notifications.sort(
        (AppNotificationModel a, AppNotificationModel b) =>
            b.createdAt.compareTo(a.createdAt),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _openNotification(AppNotificationModel notification) async {
    if (!notification.isRead) {
      await _repository.markAsRead(notification.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = _notifications.map((AppNotificationModel item) {
          return item.id == notification.id ? item.copyWith(isRead: true) : item;
        }).toList(growable: false);
      });
    }

    final String? groupId = notification.groupId;
    if (groupId != null && groupId.trim().isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GroupDetailPage(groupId: groupId),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Notifikasi ini tidak membuka halaman grup.'),
        ),
      );
  }

  _NotificationSections get _sections {
    final DateTime now = DateTime.now();
    final List<AppNotificationModel> today = <AppNotificationModel>[];
    final List<AppNotificationModel> thisWeek = <AppNotificationModel>[];
    final List<AppNotificationModel> earlier = <AppNotificationModel>[];

    for (final AppNotificationModel notification in _notifications) {
      final DateTime createdAt = notification.createdAt.toLocal();
      if (_isSameDate(createdAt, now)) {
        today.add(notification);
      } else if (now.difference(createdAt).inDays < 7) {
        thisWeek.add(notification);
      } else {
        earlier.add(notification);
      }
    }

    return _NotificationSections(
      today: today,
      thisWeek: thisWeek,
      earlier: earlier,
    );
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _timestampLabel(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    final String time =
        '${local.hour.toString().padLeft(2, '0')}.${local.minute.toString().padLeft(2, '0')}';

    if (_isSameDate(local, DateTime.now())) {
      return 'Hari ini, $time';
    }

    final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (_isSameDate(local, yesterday)) {
      return 'Kemarin, $time';
    }

    return '${local.day}/${local.month}/${local.year}, $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NotificationsPage.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 86,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 8),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back,
              color: NotificationsPage.textDarkColor,
              size: 24,
            ),
          ),
        ),
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Notifikasi',
            style: TextStyle(
              color: NotificationsPage.textDarkColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: NotificationsPage.borderColor),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
                children: <Widget>[
                  if (_isLoading)
                    const _NotificationsLoadingState()
                  else if (_error != null)
                    _NotificationsErrorState(
                      error: _error!,
                      onRetry: _loadNotifications,
                    )
                  else if (_notifications.isEmpty)
                    const NotificationsEmptyState()
                  else
                    _NotificationSectionList(
                      sections: _sections,
                      timestampLabel: _timestampLabel,
                      onNotificationTap: _openNotification,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationSections {
  const _NotificationSections({
    required this.today,
    required this.thisWeek,
    required this.earlier,
  });

  final List<AppNotificationModel> today;
  final List<AppNotificationModel> thisWeek;
  final List<AppNotificationModel> earlier;
}

class _NotificationSectionList extends StatelessWidget {
  const _NotificationSectionList({
    required this.sections,
    required this.timestampLabel,
    required this.onNotificationTap,
  });

  final _NotificationSections sections;
  final String Function(DateTime dateTime) timestampLabel;
  final ValueChanged<AppNotificationModel> onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _NotificationSection(
          title: 'Today',
          notifications: sections.today,
          timestampLabel: timestampLabel,
          onNotificationTap: onNotificationTap,
        ),
        const SizedBox(height: 24),
        _NotificationSection(
          title: 'This Week',
          notifications: sections.thisWeek,
          timestampLabel: timestampLabel,
          onNotificationTap: onNotificationTap,
        ),
        const SizedBox(height: 24),
        _NotificationSection(
          title: 'Earlier',
          notifications: sections.earlier,
          timestampLabel: timestampLabel,
          onNotificationTap: onNotificationTap,
        ),
      ],
    );
  }
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({
    required this.title,
    required this.notifications,
    required this.timestampLabel,
    required this.onNotificationTap,
  });

  final String title;
  final List<AppNotificationModel> notifications;
  final String Function(DateTime dateTime) timestampLabel;
  final ValueChanged<AppNotificationModel> onNotificationTap;

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: NotificationsPage.textDarkColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        for (int index = 0; index < notifications.length; index++) ...<Widget>[
          NotificationCard(
            notification: notifications[index],
            timestampLabel: timestampLabel(notifications[index].createdAt),
            onTap: () => onNotificationTap(notifications[index]),
          ),
          if (index != notifications.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _NotificationsLoadingState extends StatelessWidget {
  const _NotificationsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 72),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _NotificationsErrorState extends StatelessWidget {
  const _NotificationsErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Column(
        children: <Widget>[
          Text(
            'Gagal memuat notifikasi: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
