import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../authentication/auth_service.dart';
import '../../widgets/responsive.dart';

enum _NotificationKind {
  friendRequest,
  settlementRequest,
  groupActivity,
  paymentReceived,
  reminder,
  general,
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.createdAt,
    this.actorName = '',
    this.actorUsername = '',
    this.actorAvatarUrl = '',
    this.amount,
    this.groupName = '',
    this.status = '',
  });

  final String id;
  final _NotificationKind kind;
  final String title;
  final String message;
  final String timeLabel;
  final DateTime createdAt;
  final String actorName;
  final String actorUsername;
  final String actorAvatarUrl;
  final num? amount;
  final String groupName;
  final String status;
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Future<List<NotificationItem>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _NotificationRepository.fetchNotifications();
  }

  Future<void> _reload() async {
    setState(() {
      _notificationsFuture = _NotificationRepository.fetchNotifications();
    });
    await _notificationsFuture;
  }

  Future<void> _respondToFriendRequest(
    NotificationItem item,
    String status,
  ) async {
    try {
      await _NotificationRepository.respondToFriendRequest(item.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'Permintaan teman diterima.'
                : 'Permintaan teman ditolak.',
          ),
          backgroundColor: const Color(0xFFC8152B),
        ),
      );
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFF9A0010),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NotificationAppBar(responsive: responsive),
            Expanded(
              child: FutureBuilder<List<NotificationItem>>(
                future: _notificationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFC8152B),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _NotificationErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _reload,
                    );
                  }

                  final items = snapshot.data ?? const <NotificationItem>[];
                  if (items.isEmpty) {
                    return _EmptyNotificationState(onRefresh: _reload);
                  }

                  return RefreshIndicator(
                    color: const Color(0xFFC8152B),
                    onRefresh: _reload,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        responsive.clamp(32, 22, 36),
                        responsive.space(30),
                        responsive.clamp(32, 22, 36),
                        responsive.space(30),
                      ),
                      child: ResponsivePage(
                        maxWidth: 430,
                        child: Column(
                          children: [
                            for (final item in items) ...[
                              _NotificationCard(
                                item: item,
                                onAccept: item.kind == _NotificationKind.friendRequest
                                    ? () => _respondToFriendRequest(
                                          item,
                                          'accepted',
                                        )
                                    : null,
                                onReject: item.kind == _NotificationKind.friendRequest
                                    ? () => _respondToFriendRequest(
                                          item,
                                          'rejected',
                                        )
                                    : null,
                              ),
                              SizedBox(height: responsive.space(22)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRepository {
  const _NotificationRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<NotificationItem>> fetchNotifications() async {
    final session = await AuthService.currentSession();
    if (session == null) {
      throw const AuthException('Session tidak ditemukan. Silakan login ulang.');
    }

    final items = <NotificationItem>[
      ...await _fetchFriendRequests(session.id),
      ...await _fetchActivityNotifications(session.id),
      ...await _fetchExpenseNotifications(session.id),
    ];

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(30).toList();
  }

  static Future<void> respondToFriendRequest(
    String requestId,
    String status,
  ) async {
    try {
      await _client
          .from('friend_requests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } on PostgrestException catch (error) {
      throw AuthException(
        'Permintaan teman belum bisa diperbarui. Detail: ${error.message}',
      );
    }
  }

  static Future<List<NotificationItem>> _fetchFriendRequests(
    String profileId,
  ) async {
    final rows = await _selectRowsSafely(
      table: 'friend_requests',
      orderColumn: 'created_at',
    );
    if (rows.isEmpty) return const [];

    final incoming = rows.where((row) {
      final status = _string(row['status']).toLowerCase();
      if (status.isNotEmpty && status != 'pending') return false;
      final receiver = _firstValue(row, const [
        'receiver_id',
        'recipient_id',
        'to_user_id',
        'requested_id',
        'friend_id',
      ]);
      return receiver == profileId;
    }).toList();

    final requesterIds = incoming
        .map(
          (row) => _firstValue(row, const [
            'requester_id',
            'sender_id',
            'from_user_id',
            'user_id',
            'profile_id',
          ]),
        )
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final profiles = await _fetchProfilesByIds(requesterIds);

    return incoming.map((row) {
      final requesterId = _firstValue(row, const [
        'requester_id',
        'sender_id',
        'from_user_id',
        'user_id',
        'profile_id',
      ]);
      final profile = profiles[requesterId] ?? const <String, dynamic>{};
      final email = _string(profile['email']);
      final name = _nameFromProfile(profile, fallback: 'Pengguna SplitSync');
      return NotificationItem(
        id: _string(row['id']),
        kind: _NotificationKind.friendRequest,
        title: 'Permintaan Pertemanan',
        message: name,
        actorName: name,
        actorUsername: _usernameFromProfile(profile, email),
        actorAvatarUrl: _string(profile['avatar_url']),
        timeLabel: _timeLabel(_date(row['created_at'])),
        createdAt: _date(row['created_at']),
        status: 'pending',
      );
    }).toList();
  }

  static Future<List<NotificationItem>> _fetchActivityNotifications(
    String profileId,
  ) async {
    final rows = await _selectRowsSafely(
      table: 'notifications',
      orderColumn: 'created_at',
    );
    if (rows.isEmpty) return const [];

    return rows.where((row) {
      final owner = _firstValue(row, const [
        'user_id',
        'profile_id',
        'recipient_id',
        'receiver_id',
      ]);
      return owner.isEmpty || owner == profileId;
    }).map((row) {
      final type = _string(row['type']).toLowerCase();
      final title = _string(row['title']);
      final message = _string(row['message']);
      final createdAt = _date(row['created_at']);
      return NotificationItem(
        id: _string(row['id']),
        kind: _kindFromType(type),
        title: title.isEmpty ? _titleFromType(type) : title,
        message: message.isEmpty ? 'Ada aktivitas baru di SplitSync.' : message,
        timeLabel: _timeLabel(createdAt),
        createdAt: createdAt,
        amount: _number(row['amount']),
        groupName: _string(row['group_name']),
      );
    }).toList();
  }

  static Future<List<NotificationItem>> _fetchExpenseNotifications(
    String profileId,
  ) async {
    final groupIds = await _fetchJoinedGroupIds(profileId);
    if (groupIds.isEmpty) return const [];

    final rows = await _selectRowsSafely(table: 'expenses', orderColumn: 'created_at');
    if (rows.isEmpty) return const [];

    return rows.where((row) {
      final groupId = _string(row['group_id']);
      return groupId.isNotEmpty && groupIds.contains(groupId);
    }).map((row) {
      final createdAt = _date(row['created_at']);
      final title = _string(row['title']).isEmpty
          ? _string(row['description'])
          : _string(row['title']);
      final amount = _number(row['total_amount']) ?? _number(row['amount']);
      return NotificationItem(
        id: _string(row['id']),
        kind: _NotificationKind.groupActivity,
        title: _string(row['group_name']).isEmpty
            ? 'Aktivitas Grup'
            : _string(row['group_name']),
        message:
            'Pengeluaran baru: "${title.isEmpty ? 'Tagihan' : title}" ${_formatRupiah(amount ?? 0)}',
        timeLabel: _timeLabel(createdAt),
        createdAt: createdAt,
        amount: amount,
      );
    }).toList();
  }

  static Future<List<String>> _fetchJoinedGroupIds(String profileId) async {
    try {
      final rows = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', profileId);
      return rows
          .map((row) => _string(row['group_id']))
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<Map<String, dynamic>>> _selectRowsSafely({
    required String table,
    required String orderColumn,
  }) async {
    try {
      final rows = await _client.from(table).select().order(orderColumn);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return const [];
    }
  }

  static Future<Map<String, Map<String, dynamic>>> _fetchProfilesByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const {};
    try {
      final rows = await _client
          .from('profiles')
          .select('id,user_name,email,avatar_url')
          .inFilter('id', ids);
      return {
        for (final row in rows) _string(row['id']): Map<String, dynamic>.from(row),
      };
    } catch (_) {
      return const {};
    }
  }

  static String _firstValue(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = _string(row[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _string(Object? value) => (value ?? '').toString();

  static num? _number(Object? value) {
    if (value is num) return value;
    if (value == null) return null;
    return num.tryParse(value.toString());
  }

  static DateTime _date(Object? value) {
    return DateTime.tryParse(_string(value)) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _nameFromProfile(
    Map<String, dynamic> profile, {
    required String fallback,
  }) {
    final name = _string(profile['user_name']);
    if (name.isNotEmpty) return name;
    final email = _string(profile['email']);
    if (email.contains('@')) return email.split('@').first;
    return fallback;
  }

  static String _usernameFromProfile(Map<String, dynamic> profile, String email) {
    final name = _string(profile['user_name']);
    if (name.isNotEmpty) return '@${name.replaceAll(' ', '_').toLowerCase()}';
    if (email.contains('@')) return '@${email.split('@').first}';
    return '@splitsync_user';
  }

  static _NotificationKind _kindFromType(String type) {
    if (type.contains('friend')) return _NotificationKind.friendRequest;
    if (type.contains('payment')) return _NotificationKind.paymentReceived;
    if (type.contains('settlement') || type.contains('request')) {
      return _NotificationKind.settlementRequest;
    }
    if (type.contains('reminder')) return _NotificationKind.reminder;
    if (type.contains('group') || type.contains('expense')) {
      return _NotificationKind.groupActivity;
    }
    return _NotificationKind.general;
  }

  static String _titleFromType(String type) {
    switch (_kindFromType(type)) {
      case _NotificationKind.friendRequest:
        return 'Permintaan Pertemanan';
      case _NotificationKind.settlementRequest:
        return 'Penyelesaian Request';
      case _NotificationKind.groupActivity:
        return 'Aktivitas Grup';
      case _NotificationKind.paymentReceived:
        return 'Pembayaran Diterima';
      case _NotificationKind.reminder:
        return 'Gentle Reminder';
      case _NotificationKind.general:
        return 'Notifikasi';
    }
  }

  static String _timeLabel(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return 'Baru saja';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }

  static String _formatRupiah(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString()}';
  }
}

class _NotificationAppBar extends StatelessWidget {
  const _NotificationAppBar({required this.responsive});

  final Responsive responsive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: responsive.clamp(126, 104, 132),
      padding: EdgeInsets.symmetric(horizontal: responsive.clamp(38, 26, 42)),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: const Color(0xFF0D1B2E),
              size: responsive.clamp(34, 28, 36),
            ),
          ),
          Expanded(
            child: Text(
              'Notifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF0D1B2E),
                fontSize: responsive.font(34),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: responsive.clamp(48, 40, 48)),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, this.onAccept, this.onReject});

  final NotificationItem item;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final isFriendRequest = item.kind == _NotificationKind.friendRequest;
    final isReminder = item.kind == _NotificationKind.reminder;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        responsive.clamp(24, 18, 26),
        responsive.clamp(26, 22, 28),
        responsive.clamp(24, 18, 26),
        responsive.clamp(26, 22, 28),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFriendRequest ? const Color(0xFFE6BFC0) : Colors.white,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isReminder)
              Container(
                width: 5,
                margin: EdgeInsets.only(right: responsive.space(18)),
                decoration: const BoxDecoration(
                  color: Color(0xFF8C0010),
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
              ),
            _NotificationLeading(item: item),
            SizedBox(width: responsive.space(20)),
            Expanded(child: _NotificationContent(item: item)),
            SizedBox(width: responsive.space(10)),
            Text(
              item.timeLabel,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: const Color(0xFF68605F),
                fontSize: responsive.font(16),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationContent extends StatelessWidget {
  const _NotificationContent({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final titleColor = item.kind == _NotificationKind.paymentReceived
        ? const Color(0xFF68605F)
        : const Color(0xFF7A0010);
    final isFriendRequest = item.kind == _NotificationKind.friendRequest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: titleColor,
            fontSize: responsive.font(22),
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        SizedBox(height: responsive.space(6)),
        Text(
          isFriendRequest ? item.actorName : item.message,
          style: TextStyle(
            color: const Color(0xFF172033),
            fontSize: responsive.font(isFriendRequest ? 22 : 20),
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
        if (isFriendRequest) ...[
          SizedBox(height: responsive.space(4)),
          Text(
            item.actorUsername,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF68605F),
              fontSize: responsive.font(19),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: responsive.space(24)),
          Row(
            children: [
              Expanded(
                child: _ActionButton(label: 'Terima', filled: true, onTap: () {}),
              ),
              SizedBox(width: responsive.space(12)),
              Expanded(
                child: _ActionButton(label: 'Tolak', filled: false, onTap: () {}),
              ),
            ],
          ),
        ] else if (item.kind == _NotificationKind.groupActivity) ...[
          SizedBox(height: responsive.space(18)),
          _Tag(label: 'Pengeluaran baru'),
        ] else if (item.kind == _NotificationKind.settlementRequest) ...[
          SizedBox(height: responsive.space(18)),
          Row(
            children: [
              _CompactButton(label: 'Bayar', filled: true),
              SizedBox(width: responsive.space(12)),
              _CompactButton(label: 'Tolak', filled: false),
            ],
          ),
        ],
      ],
    );
  }
}

class _NotificationLeading extends StatelessWidget {
  const _NotificationLeading({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final size = responsive.clamp(64, 54, 68);
    if (item.actorAvatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFFF9DCDD),
        backgroundImage: NetworkImage(item.actorAvatarUrl),
      );
    }

    final color = switch (item.kind) {
      _NotificationKind.groupActivity => const Color(0xFFE4EAFF),
      _NotificationKind.paymentReceived => const Color(0xFFE9F8EE),
      _NotificationKind.reminder => const Color(0xFFFFD8D8),
      _ => const Color(0xFFF7E4E4),
    };
    final icon = switch (item.kind) {
      _NotificationKind.groupActivity => Icons.groups_rounded,
      _NotificationKind.paymentReceived => Icons.check_circle_rounded,
      _NotificationKind.reminder => Icons.notifications_active_rounded,
      _NotificationKind.settlementRequest => Icons.person_rounded,
      _NotificationKind.friendRequest => Icons.person_add_alt_1_rounded,
      _NotificationKind.general => Icons.notifications_none_rounded,
    };
    final iconColor = item.kind == _NotificationKind.paymentReceived
        ? const Color(0xFF188F48)
        : const Color(0xFF8C0010);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: responsive.clamp(34, 28, 36)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return SizedBox(
      height: responsive.clamp(52, 46, 54),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: filled ? const Color(0xFF8C0010) : Colors.white,
          foregroundColor: filled ? Colors.white : const Color(0xFF8C0010),
          side: BorderSide(
            color: filled ? const Color(0xFF8C0010) : const Color(0xFF9A7777),
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: responsive.font(19),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  const _CompactButton({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      height: responsive.clamp(46, 42, 48),
      padding: EdgeInsets.symmetric(horizontal: responsive.clamp(24, 20, 28)),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF8C0010) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: filled ? const Color(0xFF8C0010) : const Color(0xFFE5BFC0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : const Color(0xFF68605F),
          fontSize: responsive.font(18),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.clamp(16, 14, 18),
        vertical: responsive.clamp(6, 5, 7),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE5EAFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF8C0010),
          fontSize: responsive.font(16),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NotificationErrorState extends StatelessWidget {
  const _NotificationErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.space(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFC8152B),
              size: 42,
            ),
            SizedBox(height: responsive.space(14)),
            Text(
              'Notifikasi belum bisa dimuat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF111B2C),
                fontSize: responsive.font(20),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: responsive.space(8)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF68605F),
                fontSize: responsive.font(14),
              ),
            ),
            SizedBox(height: responsive.space(18)),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8152B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return RefreshIndicator(
      color: const Color(0xFFC8152B),
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(responsive.space(28)),
        children: [
          SizedBox(height: responsive.space(180)),
          const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFFC8152B),
            size: 54,
          ),
          SizedBox(height: responsive.space(18)),
          Text(
            'Belum ada notifikasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF111B2C),
              fontSize: responsive.font(24),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: responsive.space(8)),
          Text(
            'Aktivitas grup dan request teman akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF68605F),
              fontSize: responsive.font(16),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
