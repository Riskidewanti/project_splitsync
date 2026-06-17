import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_member_model.dart';
import '../models/group_model.dart';

abstract class GroupRemoteDataSource {
  Future<GroupModel> createGroup({required String name, String? description});

  Future<List<GroupModel>> getUserGroups(String userId);

  Future<GroupModel?> getGroupById(String groupId);

  Future<List<GroupMemberModel>> getGroupMembers(String groupId);

  Future<GroupMemberModel> addMember({
    required String groupId,
    required String userId,
    String? invitedBy,
    GroupMemberRole role = GroupMemberRole.member,
  });

  Future<void> removeMember({required String groupId, required String userId});
}

class GroupRemoteDataSourceImpl implements GroupRemoteDataSource {
  GroupRemoteDataSourceImpl({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<GroupModel> createGroup({
    required String name,
    String? description,
  }) async {
    final String currentUserId = _requireCurrentUserId();

    final Map<String, dynamic> groupRow = await _client
        .from('groups')
        .insert(<String, dynamic>{
          'name': name.trim(),
          'description': description?.trim(),
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

    return group;
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
        .update(<String, dynamic>{
          'status': GroupMemberStatus.removed.value,
          'left_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  String _requireCurrentUserId() {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('User must be logged in to create a group.');
    }

    return userId;
  }
}
