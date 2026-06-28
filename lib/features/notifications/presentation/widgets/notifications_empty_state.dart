import 'package:flutter/material.dart';

class NotificationsEmptyState extends StatelessWidget {
  const NotificationsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 88, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFFFFE4E4),
            child: Icon(
              Icons.notifications_none,
              color: Color(0xFFC70F1B),
              size: 34,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Belum ada notifikasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1F2933),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Aktivitas grup, undangan, tagihan, dan pembayaran akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
