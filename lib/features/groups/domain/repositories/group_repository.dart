import '../../data/models/group_member_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/group_expense_model.dart';

abstract class GroupRepository {
  Future<GroupModel> createGroup({required String name, String? description});

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
