import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../authentication/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../friend_request_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  static const Color primaryColor = Color(0xFF8F0010);
  static const Color backgroundColor = Color(0xFFFBF8FF);
  static const Color textColor = Color(0xFF1B1115);
  static const Color mutedColor = Color(0xFF655A60);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final SupabaseClient _client = Supabase.instance.client;

  List<_FriendRequestNotification> _notifications =
      const <_FriendRequestNotification>[];
  List<_DebtNotification> _debtNotifications = const <_DebtNotification>[];
  bool _isLoading = true;
  bool _processingRequest = false;
  Object? _error;
  String? _currentProfileId;

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
      final SessionProfile? session = await AuthService.currentSession();
      final String? currentId = session?.id;
      if (currentId == null || currentId.isEmpty) {
        throw const AuthException('Akun aktif belum ditemukan.');
      }

      final List<dynamic> requestRows = await _client
          .from('friend_requests')
          .select('id,requester_id,addressee_id,status,created_at')
          .eq('status', 'pending')
          .or('requester_id.eq.$currentId,addressee_id.eq.$currentId')
          .order('created_at', ascending: false);

      final Set<String> profileIds = <String>{};
      for (final dynamic row in requestRows) {
        final Map<String, dynamic> request = Map<String, dynamic>.from(
          row as Map,
        );
        final String requesterId = (request['requester_id'] ?? '').toString();
        final String addresseeId = (request['addressee_id'] ?? '').toString();
        if (requesterId.isNotEmpty) profileIds.add(requesterId);
        if (addresseeId.isNotEmpty) profileIds.add(addresseeId);
      }

      final Map<String, _NotificationProfile> profiles = await _loadProfiles(
        profileIds,
      );

      final List<_FriendRequestNotification> notifications = requestRows
          .map((dynamic row) => Map<String, dynamic>.from(row as Map))
          .map(
            (Map<String, dynamic> row) => _FriendRequestNotification.fromRow(
              row,
              currentProfileId: currentId,
              profiles: profiles,
            ),
          )
          .where((_FriendRequestNotification item) => item.otherProfile != null)
          .toList(growable: false);
      final List<_DebtNotification> debtNotifications =
          await _loadDebtNotifications(currentId);

      if (!mounted) return;
      setState(() {
        _currentProfileId = currentId;
        _notifications = notifications;
        _debtNotifications = debtNotifications;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<List<_DebtNotification>> _loadDebtNotifications(
    String currentProfileId,
  ) async {
    try {
      final List<dynamic> rows = await _client
          .from('split_bill')
          .select(
            'id,user_id,exact_amount,category,currency,created_at,is_paid',
          )
          .eq('user_id', currentProfileId)
          .eq('is_paid', false)
          .gt('exact_amount', 0)
          .order('created_at', ascending: false)
          .limit(20);

      return rows
          .map((dynamic row) => Map<String, dynamic>.from(row as Map))
          .map(_DebtNotification.fromRow)
          .where((_DebtNotification debt) => debt.amount > 0)
          .toList(growable: false);
    } catch (error) {
      final String message = error.toString();
      if (!message.contains('is_paid')) rethrow;

      final List<dynamic> rows = await _client
          .from('split_bill')
          .select('id,user_id,exact_amount,category,currency,created_at')
          .eq('user_id', currentProfileId)
          .gt('exact_amount', 0)
          .order('created_at', ascending: false)
          .limit(20);

      return rows
          .map((dynamic row) => Map<String, dynamic>.from(row as Map))
          .map(_DebtNotification.fromRow)
          .where((_DebtNotification debt) => debt.amount > 0)
          .toList(growable: false);
    }
  }

  Future<Map<String, _NotificationProfile>> _loadProfiles(
    Set<String> profileIds,
  ) async {
    if (profileIds.isEmpty) return <String, _NotificationProfile>{};

    final List<dynamic> rows = await _client
        .from('profiles')
        .select('id,user_name,email,avatar_url')
        .inFilter('id', profileIds.toList());

    return <String, _NotificationProfile>{
      for (final dynamic row in rows)
        _NotificationProfile.fromRow(Map<String, dynamic>.from(row as Map)).id:
            _NotificationProfile.fromRow(Map<String, dynamic>.from(row)),
    };
  }

  Future<void> _respondToRequest(
    _FriendRequestNotification notification,
    String status,
  ) async {
    if (_processingRequest) return;

    setState(() {
      _processingRequest = true;
    });

    try {
      debugPrint("KLIK TOMBOL TERIMA");

      if (status == 'accepted') {
        await FriendRequestService.acceptRequest(
          requestId: notification.id,
          requesterId: notification.requesterId,
          addresseeId: notification.addresseeId,
        );
      } else {
        await FriendRequestService.rejectRequest(notification.id);
      }

      debugPrint("REQUEST BERHASIL");

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? 'Permintaan pertemanan diterima.'
                  : 'Permintaan ditolak.',
            ),
          ),
        );

      await _loadNotifications();
    } catch (e, s) {
      debugPrint("======================");
      debugPrint(e.toString());
      debugPrint(s.toString());
      debugPrint("======================");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _processingRequest = false;
        });
      }
    }
  }

  Future<void> _payDebt(_DebtNotification debt) async {
    try {
      final String now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('split_bill')
          .update(<String, dynamic>{
            'is_paid': true,
            'paid_at': now,
            'updated_at': now,
          })
          .eq('id', debt.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${debt.title} berhasil dibayar.'),
            backgroundColor: NotificationsPage.primaryColor,
          ),
        );
      await _loadNotifications();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Gagal membayar hutang: $error'),
            backgroundColor: const Color(0xFF9A0010),
          ),
        );
      debugPrint("NOTIFICATION RELOAD");
    }
  }

  int get _pendingIncomingCount => _notifications
      .where(
        (_FriendRequestNotification item) =>
            item.isIncoming && item.status == 'pending',
      )
      .length;

  int get _pendingActivityCount =>
      _pendingIncomingCount + _debtNotifications.length;

  List<_NotificationFeedItem> get _feedItems {
    final List<_NotificationFeedItem> items = <_NotificationFeedItem>[
      for (final _FriendRequestNotification notification in _notifications)
        _NotificationFeedItem.friendRequest(notification),
      for (final _DebtNotification debt in _debtNotifications)
        _NotificationFeedItem.debt(debt),
    ];
    items.sort(
      (_NotificationFeedItem first, _NotificationFeedItem second) =>
          second.createdAt.compareTo(first.createdAt),
    );
    return items;
  }

  List<_NotificationProfile> get _summaryProfiles => _notifications
      .where((_FriendRequestNotification item) => item.status == 'pending')
      .map((_FriendRequestNotification item) => item.otherProfile)
      .whereType<_NotificationProfile>()
      .take(3)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NotificationsPage.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const _NotificationsHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadNotifications,
                color: NotificationsPage.primaryColor,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: <Widget>[
                    if (_isLoading)
                      const _NotificationsLoadingState()
                    else if (_error != null)
                      _NotificationsErrorState(
                        error: _error!,
                        onRetry: _loadNotifications,
                      )
                    else ...<Widget>[
                      _ActivitySummaryCard(
                        pendingCount: _pendingActivityCount,
                        profiles: _summaryProfiles,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_feedItems.isEmpty)
                        const _NotificationsEmptyState()
                      else
                        for (final _NotificationFeedItem item
                            in _feedItems) ...<Widget>[
                          if (item.friendRequest != null)
                            _FriendRequestCard(
                              notification: item.friendRequest!,
                              currentProfileId: _currentProfileId,
                              onAccept: () => _respondToRequest(
                                item.friendRequest!,
                                'accepted',
                              ),
                              onReject: () => _respondToRequest(
                                item.friendRequest!,
                                'rejected',
                              ),
                            )
                          else
                            _DebtNotificationCard(
                              debt: item.debt!,
                              onPay: () => _payDebt(item.debt!),
                              onLater: () {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Pengingat pembayaran tetap tersimpan.',
                                      ),
                                    ),
                                  );
                              },
                            ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _NotificationsBottomNav(),
    );
  }
}

class _NotificationProfile {
  const _NotificationProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  String get handle => email.isNotEmpty ? email : '@$name';

  String get initials {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final List<String> parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory _NotificationProfile.fromRow(Map<String, dynamic> row) {
    final String email = (row['email'] ?? '').toString();
    final String userName = (row['user_name'] ?? '').toString();
    final String fallbackName = email.contains('@')
        ? email.split('@').first
        : email;
    return _NotificationProfile(
      id: (row['id'] ?? '').toString(),
      name: userName.isEmpty ? fallbackName : userName,
      email: email,
      avatarUrl: (row['avatar_url'] ?? '').toString(),
    );
  }
}

class _FriendRequestNotification {
  const _FriendRequestNotification({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    required this.isIncoming,
    required this.otherProfile,
  });

  final String id;
  final String requesterId;
  final String addresseeId;
  final String status;
  final DateTime createdAt;
  final bool isIncoming;
  final _NotificationProfile? otherProfile;

  factory _FriendRequestNotification.fromRow(
    Map<String, dynamic> row, {
    required String currentProfileId,
    required Map<String, _NotificationProfile> profiles,
  }) {
    final String requesterId = (row['requester_id'] ?? '').toString();
    final String addresseeId = (row['addressee_id'] ?? '').toString();
    final bool isIncoming = addresseeId == currentProfileId;
    final String otherId = isIncoming ? requesterId : addresseeId;

    return _FriendRequestNotification(
      id: (row['id'] ?? '').toString(),
      requesterId: requesterId,
      addresseeId: addresseeId,
      status: (row['status'] ?? 'pending').toString(),
      createdAt: _parseDate(row['created_at']),
      isIncoming: isIncoming,
      otherProfile: profiles[otherId],
    );
  }

  static DateTime _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.parse(value);
    return DateTime.now();
  }
}

class _DebtNotification {
  const _DebtNotification({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String title;
  final double amount;
  final String currency;
  final DateTime createdAt;

  factory _DebtNotification.fromRow(Map<String, dynamic> row) {
    final String category = (row['category'] ?? '').toString().trim();
    return _DebtNotification(
      id: (row['id'] ?? '').toString(),
      title: category.isEmpty ? 'Pembayaran' : category,
      amount: _toDouble(row['exact_amount']),
      currency: (row['currency'] ?? 'IDR').toString(),
      createdAt: _parseDate(row['created_at']),
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  static DateTime _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.parse(value);
    return DateTime.now();
  }
}

class _NotificationFeedItem {
  const _NotificationFeedItem._({this.friendRequest, this.debt});

  factory _NotificationFeedItem.friendRequest(
    _FriendRequestNotification notification,
  ) {
    return _NotificationFeedItem._(friendRequest: notification);
  }

  factory _NotificationFeedItem.debt(_DebtNotification debt) {
    return _NotificationFeedItem._(debt: debt);
  }

  final _FriendRequestNotification? friendRequest;
  final _DebtNotification? debt;

  DateTime get createdAt => friendRequest?.createdAt ?? debt!.createdAt;
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: NotificationsPage.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Notifikasi',
              style: TextStyle(
                color: NotificationsPage.primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert_rounded,
              color: NotificationsPage.primaryColor,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySummaryCard extends StatelessWidget {
  const _ActivitySummaryCard({
    required this.pendingCount,
    required this.profiles,
  });

  final int pendingCount;
  final List<_NotificationProfile> profiles;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 26, 24, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Aktivitas Terbaru',
                  style: TextStyle(
                    color: NotificationsPage.primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pendingCount == 0
                      ? 'Tidak ada permintaan tertunda.'
                      : 'Anda memiliki $pendingCount permintaan tertunda.',
                  style: const TextStyle(
                    color: NotificationsPage.mutedColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (profiles.isNotEmpty)
            SizedBox(
              width: 88,
              height: 44,
              child: Stack(
                children: <Widget>[
                  for (int index = 0; index < profiles.length; index++)
                    Positioned(
                      left: index * 24,
                      child: _ProfileAvatar(
                        profile: profiles[index],
                        radius: 22,
                        borderWidth: 2,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FriendRequestCard extends StatelessWidget {
  const _FriendRequestCard({
    required this.notification,
    required this.currentProfileId,
    required this.onAccept,
    required this.onReject,
  });

  final _FriendRequestNotification notification;
  final String? currentProfileId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final _NotificationProfile profile = notification.otherProfile!;
    final bool canRespond =
        notification.isIncoming && notification.status == 'pending';
    final bool isPending = notification.status == 'pending';

    return Container(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: canRespond
            ? Border.all(color: const Color(0x35A60012), width: 1.2)
            : null,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ProfileAvatar(profile: profile, radius: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        notification.isIncoming
                            ? 'Permintaan Pertemanan'
                            : 'Permintaan Dikirim',
                        style: const TextStyle(
                          color: NotificationsPage.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _relativeTime(notification.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF4E454A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NotificationsPage.mutedColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                if (canRespond)
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 4,
                        child: _NotificationActionButton(
                          label: 'Terima',
                          filled: true,
                          onPressed: onAccept,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _NotificationSubtleButton(
                        label: 'Tolak',
                        onPressed: onReject,
                      ),
                    ],
                  )
                else
                  _StatusPill(
                    label: _statusLabel(notification, isPending: isPending),
                    status: notification.status,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(
    _FriendRequestNotification notification, {
    required bool isPending,
  }) {
    if (isPending && !notification.isIncoming) return 'Menunggu konfirmasi';
    if (notification.status == 'accepted') return 'Diterima';
    if (notification.status == 'rejected') return 'Ditolak';
    return notification.status;
  }

  String _relativeTime(DateTime createdAt) {
    final Duration difference = DateTime.now().difference(createdAt.toLocal());
    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes} mnt lalu';
    if (difference.inHours < 24) return '${difference.inHours} jam lalu';
    if (difference.inDays == 1) return 'Kemarin';
    return '${difference.inDays} hari lalu';
  }
}

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: NotificationsPage.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: NotificationsPage.primaryColor,
                side: const BorderSide(color: Color(0xFF7B5B61)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}

class _NotificationSubtleButton extends StatelessWidget {
  const _NotificationSubtleButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: NotificationsPage.mutedColor,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(56, AppSpacing.buttonHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DebtNotificationCard extends StatelessWidget {
  const _DebtNotificationCard({
    required this.debt,
    required this.onPay,
    required this.onLater,
  });

  final _DebtNotification debt;
  final VoidCallback onPay;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD6D9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: NotificationsPage.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Permintaan Pelunasan',
                        style: TextStyle(
                          color: NotificationsPage.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _relativeTime(debt.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF4E454A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      const TextSpan(text: 'Anda perlu membayar '),
                      TextSpan(
                        text: _formatDebtAmount(debt),
                        style: const TextStyle(
                          color: NotificationsPage.primaryColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(text: ' untuk "${debt.title}".'),
                    ],
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.32,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: _NotificationActionButton(
                        label: 'Bayar Sekarang',
                        filled: true,
                        onPressed: onPay,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _NotificationActionButton(
                        label: 'Nanti',
                        onPressed: onLater,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime createdAt) {
    final Duration difference = DateTime.now().difference(createdAt.toLocal());
    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes} mnt lalu';
    if (difference.inHours < 24) return '${difference.inHours} jam lalu';
    if (difference.inDays == 1) return 'Kemarin';
    return '${difference.inDays} hari lalu';
  }

  String _formatDebtAmount(_DebtNotification debt) {
    if (debt.currency.toUpperCase() == 'IDR') {
      return _formatRupiah(debt.amount);
    }
    return '${debt.currency.toUpperCase()} ${debt.amount.toStringAsFixed(2)}';
  }

  String _formatRupiah(double value) {
    final bool hasDecimals = value % 1 != 0;
    final String fixed = hasDecimals
        ? value.toStringAsFixed(2)
        : value.round().toString();
    final List<String> parts = fixed.split('.');
    final String digits = parts.first;
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final int reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    if (parts.length > 1) return 'Rp ${buffer.toString()},${parts.last}';
    return 'Rp ${buffer.toString()}';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final bool accepted = status == 'accepted';
    final Color color = accepted
        ? const Color(0xFF087A3A)
        : status == 'rejected'
        ? const Color(0xFF9A0010)
        : NotificationsPage.primaryColor;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
    required this.radius,
    this.borderWidth = 0,
  });

  final _NotificationProfile profile;
  final double radius;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEEE),
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(color: Colors.white, width: borderWidth)
            : null,
        image: profile.avatarUrl.isEmpty
            ? null
            : DecorationImage(
                image: NetworkImage(profile.avatarUrl),
                fit: BoxFit.cover,
              ),
      ),
      child: profile.avatarUrl.isEmpty
          ? Center(
              child: Text(
                profile.initials,
                style: const TextStyle(
                  color: NotificationsPage.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : null,
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Column(
        children: <Widget>[
          CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFFFD6D9),
            child: Icon(
              Icons.notifications_none_rounded,
              color: NotificationsPage.primaryColor,
              size: 32,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(
              color: NotificationsPage.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Permintaan pertemanan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: NotificationsPage.mutedColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsLoadingState extends StatelessWidget {
  const _NotificationsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 90),
      child: Center(
        child: CircularProgressIndicator(color: NotificationsPage.primaryColor),
      ),
    );
  }
}

class _NotificationsErrorState extends StatelessWidget {
  const _NotificationsErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: <Widget>[
          Text(
            'Gagal memuat notifikasi: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: NotificationsPage.mutedColor,
              fontSize: 13,
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

class _NotificationsBottomNav extends StatelessWidget {
  const _NotificationsBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.bottomNavHeight,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _BottomItem(
            icon: Icons.home,
            label: 'Beranda',
            onTap: () => Navigator.of(context).pushReplacementNamed('/home'),
          ),
          _BottomItem(
            icon: Icons.groups_outlined,
            label: 'Grup',
            onTap: () => Navigator.of(context).pushReplacementNamed('/groups'),
          ),
          _CenterAddButton(
            onTap: () => Navigator.of(context).pushReplacementNamed('/scan'),
          ),
          _BottomItem(
            icon: Icons.bar_chart,
            label: 'Laporan',
            onTap: () => Navigator.of(context).pushReplacementNamed('/reports'),
          ),
          _BottomItem(
            icon: Icons.person_outline,
            label: 'Profil',
            onTap: () => Navigator.of(context).pushReplacementNamed('/profile'),
          ),
        ],
      ),
    );
  }
}

class _CenterAddButton extends StatelessWidget {
  const _CenterAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Center(
        child: SizedBox(
          width: 56,
          height: 56,
          child: FloatingActionButton(
            elevation: 4,
            backgroundColor: const Color(0xFFC70F1B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            onPressed: onTap,
            child: const Icon(Icons.add, size: 34),
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: const Color(0xFF4B4548), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF4B4548),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
