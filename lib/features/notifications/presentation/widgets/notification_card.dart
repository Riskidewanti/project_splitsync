import 'package:flutter/material.dart';

import '../../data/models/app_notification_model.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.timestampLabel,
    required this.onTap,
  });

  final AppNotificationModel notification;
  final String timestampLabel;
  final VoidCallback onTap;

  static const Color primaryColor = Color(0xFFC70F1B);
  static const Color textDarkColor = Color(0xFF1F2933);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !notification.isRead;
    final Color accentColor = _accentColor(notification.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFFFF1F1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isUnread ? const Color(0xFFFFC7C7) : borderColor,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 20,
                backgroundColor: accentColor.withValues(alpha: 0.14),
                child: Icon(_iconFor(notification.type), color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textDarkColor,
                              fontSize: 13,
                              fontWeight: isUnread ? FontWeight.w900 : FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (isUnread) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timestampLabel,
                      style: const TextStyle(
                        color: Color(0xFF7A6D69),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.expense:
        return Icons.receipt_long_outlined;
      case AppNotificationType.invitation:
        return Icons.group_add_outlined;
      case AppNotificationType.bill:
        return Icons.request_quote_outlined;
      case AppNotificationType.payment:
        return Icons.payments_outlined;
    }
  }

  Color _accentColor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.expense:
        return primaryColor;
      case AppNotificationType.invitation:
        return const Color(0xFF2563EB);
      case AppNotificationType.bill:
        return const Color(0xFF7C3AED);
      case AppNotificationType.payment:
        return const Color(0xFF047857);
    }
  }
}
