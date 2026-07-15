import 'dart:typed_data';

import '../../data/models/group_member_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/group_expense_model.dart';
import '../../data/models/group_user_model.dart';

abstract class GroupRepository {
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
