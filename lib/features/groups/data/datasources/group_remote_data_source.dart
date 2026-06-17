import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_expense_model.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../models/group_user_model.dart';

abstract class GroupRemoteDataSource {
  Future<String?> getCurrentUserId();

  Future<GroupModel> createGroup({
    required String name,
    String? description,
    String? photoUrl,
    List<String> memberUserIds = const <String>[],
  });

  Future<String> uploadGroupPhoto({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  });

  Future<List<GroupUserModel>> searchUsers(String query);

  Future<List<GroupModel>> getGroups();

  Future<List<GroupModel>> getUserGroups(String userId);

  Future<GroupModel?> getGroupById(String groupId);

  Future<List<GroupMemberModel>> getGroupMembers(String groupId);

  Future<List<GroupExpenseModel>> getGroupExpenses(String groupId);

  Future<GroupMemberModel> addMember({
    required String groupId,
    required String userId,
    String? invitedBy,
    GroupMemberRole role = GroupMemberRole.member,
  });

  Future<void> removeMember({required String groupId, required String userId});

  Future<void> deleteGroup(String groupId);
}

class GroupRemoteDataSourceImpl implements GroupRemoteDataSource {
  static const String _groupPhotosBucket = 'group-photos';

  GroupRemoteDataSourceImpl({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<String?> getCurrentUserId() async {
    return _client.auth.currentUser?.id;
  }

  @override
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    String? photoUrl,
    List<String> memberUserIds = const <String>[],
  }) async {
    final String currentUserId = _requireCurrentUserId();
    final Set<String> invitedUserIds = memberUserIds
        .where((String userId) => userId != currentUserId)
        .toSet();

    final Map<String, dynamic> groupRow = await _client
        .from('groups')
        .insert(<String, dynamic>{
          'name': name.trim(),
          'description': description?.trim(),
          'photo_url': photoUrl,
          'created_by': currentUserId,
        })
        .select()
        .single();

    final GroupModel group = GroupModel.fromJson(groupRow);

    await _client.from('group_members').insert(<String, dynamic>{
      'group_id': group.id,
      'user_id': currentUserId,
      'invited_by': currentUserId,
      'role': GroupMemberRole.owner.value,
      'status': GroupMemberStatus.active.value,
      'joined_at': DateTime.now().toUtc().toIso8601String(),
    });

    if (invitedUserIds.isNotEmpty) {
      final String joinedAt = DateTime.now().toUtc().toIso8601String();
      await _client.from('group_members').insert(
        invitedUserIds.map((String userId) {
          return <String, dynamic>{
            'group_id': group.id,
            'user_id': userId,
            'invited_by': currentUserId,
            'role': GroupMemberRole.member.value,
            'status': GroupMemberStatus.active.value,
            'joined_at': joinedAt,
          };
        }).toList(),
      );
    }

    return group;
  }

  @override
  Future<String> uploadGroupPhoto({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final String currentUserId = _requireCurrentUserId();
    final String sanitizedFileName = fileName.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );
    final String path = '$currentUserId/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';

    await _client.storage
        .from(_groupPhotosBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return _client.storage.from(_groupPhotosBucket).getPublicUrl(path);
  }

  @override
  Future<List<GroupUserModel>> searchUsers(String query) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return <GroupUserModel>[];
    }

    final String currentUserId = _requireCurrentUserId();
    final String escapedQuery = trimmedQuery.replaceAll(',', ' ');
    final List<dynamic> rows = await _client
        .from('profiles')
        .select('id, display_name, email, avatar_url')
        .or('display_name.ilike.%$escapedQuery%,email.ilike.%$escapedQuery%')
        .neq('id', currentUserId)
        .limit(12);

    return rows
        .map((dynamic row) => row as Map<String, dynamic>)
        .map(GroupUserModel.fromJson)
        .toList();
  }

  @override
  Future<List<GroupModel>> getGroups() {
    return getUserGroups(_requireCurrentUserId());
  }

  @override
  Future<List<GroupModel>> getUserGroups(String userId) async {
    final List<dynamic> membershipRows = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId)
        .eq('status', GroupMemberStatus.active.value);

    final List<String> groupIds = membershipRows
        .map((dynamic row) => row as Map<String, dynamic>)
        .map((Map<String, dynamic> row) => row['group_id'] as String)
        .toList();

    if (groupIds.isEmpty) {
      return <GroupModel>[];
    }

    final List<dynamic> groupRows = await _client
        .from('groups')
        .select()
        .inFilter('id', groupIds)
        .filter('archived_at', 'is', null)
        .order('created_at', ascending: false);

    return groupRows
        .map((dynamic row) => row as Map<String, dynamic>)
        .map(GroupModel.fromJson)
        .toList();
  }

  @override
  Future<GroupModel?> getGroupById(String groupId) async {
    final Map<String, dynamic>? row = await _client
        .from('groups')
        .select()
        .eq('id', groupId)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return GroupModel.fromJson(row);
  }

  @override
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    final List<dynamic> rows = await _client
        .from('group_members')
        .select('''
          *,
          profiles (
            display_name,
            email,
            avatar_url
          )
        ''')
        .eq('group_id', groupId)
        .eq('status', GroupMemberStatus.active.value)
        .order('joined_at')
        .order('created_at');

    return rows
        .map((dynamic row) => row as Map<String, dynamic>)
        .map(GroupMemberModel.fromJson)
        .toList();
  }

  @override
  Future<List<GroupExpenseModel>> getGroupExpenses(String groupId) async {
    final List<dynamic> rows = await _client
        .from('expenses')
        .select('''
          id,
          group_id,
          payer_id,
          title,
          merchant_name,
          expense_date,
          total_amount,
          currency,
          status,
          created_at
        ''')
        .eq('group_id', groupId)
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);

    return rows
        .map((dynamic row) => row as Map<String, dynamic>)
        .map(GroupExpenseModel.fromJson)
        .toList();
  }

  @override
  Future<GroupMemberModel> addMember({
    required String groupId,
    required String userId,
    String? invitedBy,
    GroupMemberRole role = GroupMemberRole.member,
  }) async {
    final Map<String, dynamic> row = await _client
        .from('group_members')
        .insert(<String, dynamic>{
          'group_id': groupId,
          'user_id': userId,
          'invited_by': invitedBy,
          'role': role.value,
          'status': GroupMemberStatus.active.value,
          'joined_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    return GroupMemberModel.fromJson(row);
  }

  @override
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _client
        .from('groups')
        .update(<String, dynamic>{
          'archived_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', groupId);
  }

  String _requireCurrentUserId() {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('User must be logged in to create a group.');
    }

    return userId;
  }
}
