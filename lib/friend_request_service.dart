import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'authentication/auth_service.dart';

class FriendProfile {
  const FriendProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatarUrl,
    this.email = '',
    this.sent = false,
  });

  final String id;
  final String name;
  final String handle;
  final String avatarUrl;
  final String email;
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

    if (requesterId == null) {
      return const [];
    }

    try {
      final rows = await _client
          .from('profiles')
          .select('id,user_name,email,avatar_url')
          .neq('id', requesterId)
          .limit(12);

      final sentIds = await _pendingPeerIds(requesterId);

      // Ambil daftar teman yang sudah diterima
      final friends = await FriendRequestService.friends();

      final friendIds = friends.map((e) => e.id).toSet();

      return rows
          .map<FriendProfile>((row) => _profileFromRow(row, sentIds: sentIds))
          // jangan tampilkan profile kosong
          .where((profile) => profile.id.isNotEmpty)
          // jangan tampilkan diri sendiri
          .where((profile) => profile.id != requesterId)
          // jangan tampilkan yang sudah jadi teman
          .where((profile) => !friendIds.contains(profile.id))
          .toList();
    } catch (e) {
      debugPrint("Recommendations Error : $e");
      return const [];
    }
  }

  static Future<FriendProfile?> findFriend(String query) async {
    final cleaned = query.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    final result = await searchFriends(cleaned);

    if (result.isEmpty) {
      return null;
    }

    return result.first;
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

    debugPrint("REQUESTER : $requesterId");
    debugPrint("RECEIVER  : $receiverId");

    final existing = await _client
        .from('friend_requests')
        .select('id,status')
        .or(
          'and(requester_id.eq.$requesterId,addressee_id.eq.$receiverId),'
          'and(requester_id.eq.$receiverId,addressee_id.eq.$requesterId)',
        )
        .maybeSingle();

    if (existing != null) {
      final status = (existing['status'] ?? '').toString();
      if (_acceptedStatuses.contains(status)) {
        throw const FriendRequestException('User ini sudah menjadi teman.');
      }
      throw const FriendRequestException('Permintaan pertemanan sudah ada.');
    }

    await _client.from('friend_requests').insert({
      'requester_id': requesterId,
      'addressee_id': receiverId,
      'status': 'pending',
    });

    debugPrint("REQUEST BERHASIL");
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

    debugPrint("=========================");
    debugPrint("CURRENT USER : $currentId");

    try {
      final friendRows = await _client
          .from('friends')
          .select('*')
          .eq('user_id', currentId);

      debugPrint("FRIEND ROWS = $friendRows");

      final ids = <String>{};

      for (final row in friendRows) {
        final id = (row['friend_id'] ?? '').toString();

        if (id.isNotEmpty) {
          ids.add(id);
        }
      }

      debugPrint("FRIEND IDS = $ids");

      if (ids.isEmpty) {
        return const [];
      }

      final profileRows = await _client
          .from('profiles')
          .select('id,user_name,email,avatar_url')
          .inFilter('id', ids.toList());

      debugPrint("PROFILE ROWS = $profileRows");

      final profiles = profileRows
          .map<FriendProfile>((row) => _profileFromRow(row, sentIds: const {}))
          .toList();

      debugPrint("PROFILE COUNT = ${profiles.length}");

      return profiles;
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
      return const [];
    }
  }

  static Future<bool> saveAcceptedFriendship({
    required String requesterId,
    required String addresseeId,
    String? requestId,
  }) async {
    if (requesterId.isEmpty || addresseeId.isEmpty) {
      throw const FriendRequestException(
        'Data permintaan pertemanan tidak lengkap.',
      );
    }

    if (requesterId == addresseeId) {
      throw const FriendRequestException(
        'Tidak bisa berteman dengan diri sendiri.',
      );
    }

    try {
      await _client.from('friends').upsert(<Map<String, dynamic>>[
        <String, dynamic>{
          'user_id': requesterId,
          'friend_id': addresseeId,
          'friend_request_id': requestId,
        },
        <String, dynamic>{
          'user_id': addresseeId,
          'friend_id': requesterId,
          'friend_request_id': requestId,
        },
      ], onConflict: 'user_id,friend_id');

      return true;
    } catch (error) {
      if (_isMissingFriendsTable(error)) {
        return false;
      }

      throw FriendRequestException('Pertemanan belum bisa disimpan: $error');
    }
  }

  static Future<void> acceptRequest({
    required String requestId,
    required String requesterId,
    required String addresseeId,
  }) async {
    debugPrint("================================");
    debugPrint("ACCEPT REQUEST DIPANGGIL");
    debugPrint("Request ID : $requestId");
    debugPrint("Requester  : $requesterId");
    debugPrint("Addressee  : $addresseeId");
    debugPrint("================================");

    final updated = await _updateFriendRequestStatus(
      requestId: requestId,
      requesterId: requesterId,
      addresseeId: addresseeId,
      status: 'accepted',
    );

    debugPrint("UPDATED ROWS : $updated");

    if (updated.isEmpty) {
      throw const FriendRequestException(
        'Friend request tidak berhasil diupdate.',
      );
    }

    debugPrint("STATUS BERHASIL DIUPDATE");

    final cek = await _client
        .from('friend_requests')
        .select('status')
        .eq('id', requestId)
        .single();

    debugPrint("STATUS DATABASE : ${cek['status']}");

    final saved = await saveAcceptedFriendship(
      requesterId: requesterId,
      addresseeId: addresseeId,
      requestId: requestId,
    );

    debugPrint("SAVE FRIEND RESULT : $saved");

    debugPrint("FRIEND BERHASIL DISIMPAN");
  }

  static Future<void> rejectRequest(String requestId) async {
    final updatedRows = await _client
        .from('friend_requests')
        .update({
          'status': 'rejected',
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .select();

    debugPrint("========== UPDATE RESULT ==========");
    debugPrint(updatedRows.toString());
    debugPrint("===================================");

    if (updatedRows.isEmpty) {
      throw FriendRequestException('Friend request tidak berhasil diupdate.');
    }
  }

  static Future<List<FriendProfile>> _friendsFromAcceptedRequests(
    String currentId,
  ) async {
    try {
      final requestRows = await _client
          .from('friend_requests')
          .select('id,requester_id,addressee_id,status')
          .or('requester_id.eq.$currentId,addressee_id.eq.$currentId')
          .inFilter('status', _acceptedStatuses.toList());

      final friendIds = <String>{};
      for (final row in requestRows) {
        final requestId = (row['id'] ?? '').toString();
        final requesterId = (row['requester_id'] ?? '').toString();
        final addresseeId = (row['addressee_id'] ?? '').toString();
        if (requesterId == currentId && addresseeId.isNotEmpty) {
          friendIds.add(addresseeId);
        }
        if (addresseeId == currentId && requesterId.isNotEmpty) {
          friendIds.add(requesterId);
        }

        if (requesterId.isNotEmpty && addresseeId.isNotEmpty) {
          try {
            await saveAcceptedFriendship(
              requesterId: requesterId,
              addresseeId: addresseeId,
              requestId: requestId.isEmpty ? null : requestId,
            );
          } catch (error) {
            debugPrint('Backfill friends gagal: $error');
          }
        }
      }

      if (friendIds.isEmpty) return const [];

      return _profilesByIds(friendIds);
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
      try {
        await _client
            .from('friends')
            .delete()
            .or(
              'and(user_id.eq.$currentId,friend_id.eq.$friendId),'
              'and(user_id.eq.$friendId,friend_id.eq.$currentId)',
            );
      } catch (error) {
        if (!_isMissingFriendsTable(error)) rethrow;
      }

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

  static Future<List<FriendProfile>> _profilesByIds(
    Set<String> profileIds,
  ) async {
    final profileRows = await _client
        .from('profiles')
        .select('id,user_name,email,avatar_url')
        .inFilter('id', profileIds.toList());

    return profileRows
        .map<FriendProfile>((row) => _profileFromRow(row, sentIds: const {}))
        .where((profile) => profile.id.isNotEmpty)
        .toList();
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
    final profile = await AuthService.currentSession();
    if (profile == null) {
      return null;
    }

    final sessionId = profile.id.trim();
    if (_looksLikeUuid(sessionId)) {
      return sessionId;
    }

    final email = profile.email.trim().toLowerCase();
    if (email.isEmpty) {
      return null;
    }

    try {
      final row = await _client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      final resolvedId = (row?['id'] ?? '').toString();
      return resolvedId.isEmpty ? null : resolvedId;
    } catch (error) {
      debugPrint('Failed to resolve current profile id: $error');
      return null;
    }
  }

  static Future<List<FriendProfile>> searchFriends(String query) async {
    final currentId = await _currentProfileId();

    final sentIds = await _pendingPeerIds(currentId);

    final friends = await FriendRequestService.friends();

    final friendIds = friends.map((e) => e.id).toSet();

    final rows = await _client
        .from('profiles')
        .select('id,user_name,email,avatar_url')
        .or('user_name.ilike.%$query%,email.ilike.%$query%')
        .order('user_name');

    return rows
        .map<FriendProfile>(
          (e) => FriendProfile(
            id: e['id'].toString(),
            name: e['user_name'] ?? '',
            handle: '@${e['user_name']}',
            avatarUrl: e['avatar_url'] ?? '',
            email: e['email'] ?? '',
            sent: sentIds.contains(e['id']),
          ),
        )
        .where((e) => e.id != currentId)
        .where((e) => !friendIds.contains(e.id))
        .toList();
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
      email: email,
      sent: sentIds.contains((row['id'] ?? '').toString()),
    );
  }

  static Future<List<Map<String, dynamic>>> _updateFriendRequestStatus({
    required String requestId,
    required String requesterId,
    required String addresseeId,
    required String status,
  }) async {
    try {
      final rows = await _client
          .from('friend_requests')
          .update({
            'status': status,
            'responded_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', requestId)
          .select();

      debugPrint("UPDATE RESULT = $rows");

      return rows.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e, s) {
      debugPrint("======================");
      debugPrint("UPDATE ERROR");
      debugPrint(e.toString());
      debugPrint(s.toString());
      debugPrint("======================");

      rethrow;
    }
  }

  static const Set<String> _acceptedStatuses = <String>{'accepted'};

  static Future<Set<String>> _pendingPeerIds(String requesterId) async {
    try {
      final rows = await _client
          .from('friend_requests')
          .select('requester_id,addressee_id')
          .or('requester_id.eq.$requesterId,addressee_id.eq.$requesterId')
          .eq('status', 'pending');

      final ids = <String>{};
      for (final row in rows) {
        final requester = (row['requester_id'] ?? '').toString();
        final addressee = (row['addressee_id'] ?? '').toString();
        if (requester == requesterId && addressee.isNotEmpty) {
          ids.add(addressee);
        }
        if (addressee == requesterId && requester.isNotEmpty) {
          ids.add(requester);
        }
      }
      return ids;
    } catch (_) {
      return {};
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

  static bool _isMissingFriendsTable(Object error) {
    final message = error.toString();
    return message.contains("public.friends") ||
        message.contains('PGRST205') ||
        message.contains("Could not find the table 'friends'");
  }
}

class FriendRequestException implements Exception {
  const FriendRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
