import 'package:supabase_flutter/supabase_flutter.dart';

class FriendProfile {
  const FriendProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatarUrl,
    this.sent = false,
  });

  final String id;
  final String name;
  final String handle;
  final String avatarUrl;
  final bool sent;

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'SS';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class FriendRequestService {
  FriendRequestService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<FriendProfile>> recommendations() async {
    final requesterId = await _currentProfileIdOrNull();
    try {
      final rows = await _client
          .from('profiles')
          .select('id,user_name,email,avatar_url')
          .limit(12);

      final sentIds = requesterId == null
          ? <String>{}
          : await _sentRequestReceiverIds(requesterId);

      return rows
          .map<FriendProfile>((row) => _profileFromRow(row, sentIds: sentIds))
          .where((profile) => profile.id.isNotEmpty)
          .where((profile) => requesterId == null || profile.id != requesterId)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<FriendProfile?> findFriend(String query) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return null;

    final sentIds = await _currentProfileIdOrNull().then((id) {
      if (id == null) return Future.value(<String>{});
      return _sentRequestReceiverIds(id);
    });

    final byId = await _findById(cleaned, sentIds);
    if (byId != null) return byId;

    return _findByUsername(cleaned, sentIds);
  }

  static Future<void> sendRequestToProfile(String receiverId) async {
    final requesterId = await _currentProfileId();
    if (receiverId.isEmpty) {
      throw const FriendRequestException('Pilih teman terlebih dahulu.');
    }
    if (requesterId == receiverId) {
      throw const FriendRequestException(
        'Tidak bisa menambahkan diri sendiri.',
      );
    }

    await _client.from('friend_requests').insert({
      'requester_id': requesterId,
      'addressee_id': receiverId,
      'status': 'pending',
    });
  }

  static Future<FriendProfile> sendRequest(String query) async {
    final friend = await findFriend(query);
    if (friend == null) {
      throw const FriendRequestException('User tidak ditemukan.');
    }
    await sendRequestToProfile(friend.id);
    return friend;
  }

  static Future<List<FriendProfile>> friends() async {
    final currentId = await _currentProfileId();
    try {
      final requestRows = await _client
          .from('friend_requests')
          .select('requester_id,addressee_id,status')
          .or('requester_id.eq.$currentId,addressee_id.eq.$currentId')
          .eq('status', 'accepted');

      final friendIds = <String>{};
      for (final row in requestRows) {
        final requesterId = (row['requester_id'] ?? '').toString();
        final addresseeId = (row['addressee_id'] ?? '').toString();
        if (requesterId == currentId && addresseeId.isNotEmpty) {
          friendIds.add(addresseeId);
        }
        if (addresseeId == currentId && requesterId.isNotEmpty) {
          friendIds.add(requesterId);
        }
      }

      if (friendIds.isEmpty) return const [];

      final profileRows = await _client
          .from('profiles')
          .select('id,user_name,email,avatar_url')
          .inFilter('id', friendIds.toList());

      return profileRows
          .map<FriendProfile>((row) => _profileFromRow(row, sentIds: const {}))
          .where((profile) => profile.id.isNotEmpty)
          .toList();
    } catch (error) {
      throw FriendRequestException('Daftar teman belum bisa dimuat: $error');
    }
  }

  static Future<void> removeFriend(String friendId) async {
    final currentId = await _currentProfileId();
    if (friendId.isEmpty) {
      throw const FriendRequestException('Teman tidak ditemukan.');
    }

    try {
      await _client
          .from('friend_requests')
          .delete()
          .eq('status', 'accepted')
          .or(
            'and(requester_id.eq.$currentId,addressee_id.eq.$friendId),'
            'and(requester_id.eq.$friendId,addressee_id.eq.$currentId)',
          );
    } catch (error) {
      throw FriendRequestException('Teman belum bisa dihapus: $error');
    }
  }

  static Future<String> _currentProfileId() async {
    final id = await _currentProfileIdOrNull();
    if (id == null || id.isEmpty) {
      throw const FriendRequestException(
        'Akun aktif belum ditemukan. Silakan login terlebih dahulu.',
      );
    }
    return id;
  }

  static Future<String?> _currentProfileIdOrNull() async {
    final authUser = _client.auth.currentUser;
    if (authUser != null) return authUser.id;

    try {
      final row = await _client.from('profiles').select('id').limit(1).single();
      return (row['id'] ?? '').toString();
    } catch (_) {
      return null;
    }
  }

  static Future<FriendProfile?> _findById(
    String query,
    Set<String> sentIds,
  ) async {
    if (!_looksLikeUuid(query)) return null;
    try {
      final row = await _client
          .from('profiles')
          .select('id,user_name,email,avatar_url')
          .eq('id', query)
          .maybeSingle();
      if (row == null) return null;
      return _profileFromRow(row, sentIds: sentIds);
    } catch (_) {
      return null;
    }
  }

  static Future<FriendProfile?> _findByUsername(
    String query,
    Set<String> sentIds,
  ) async {
    final username = query.startsWith('@') ? query.substring(1) : query;
    try {
      final rows = await _client
          .from('profiles')
          .select('id,user_name,email,avatar_url')
          .ilike('user_name', username)
          .limit(1);
      if (rows.isEmpty) return null;
      return _profileFromRow(rows.first, sentIds: sentIds);
    } catch (_) {
      return null;
    }
  }

  static FriendProfile _profileFromRow(
    Map<String, dynamic> row, {
    required Set<String> sentIds,
  }) {
    final email = (row['email'] ?? '').toString();
    final userName = (row['user_name'] ?? _nameFromEmail(email)).toString();
    return FriendProfile(
      id: (row['id'] ?? '').toString(),
      name: userName.isEmpty ? 'SplitSync User' : userName,
      handle: userName.isEmpty ? email : '@$userName',
      avatarUrl: (row['avatar_url'] ?? '').toString(),
      sent: sentIds.contains((row['id'] ?? '').toString()),
    );
  }

  static Future<Set<String>> _sentRequestReceiverIds(String requesterId) async {
    try {
      final rows = await _client
          .from('friend_requests')
          .select('addressee_id')
          .eq('requester_id', requesterId);
      return rows
          .map<String>((row) => (row['addressee_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static bool _looksLikeUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  static String _nameFromEmail(String email) {
    if (!email.contains('@')) return email;
    return email.split('@').first;
  }
}

class FriendRequestException implements Exception {
  const FriendRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
