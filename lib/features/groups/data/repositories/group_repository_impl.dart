import '../../domain/repositories/group_repository.dart';
import '../datasources/group_remote_data_source.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';

class GroupRepositoryImpl implements GroupRepository {
  const GroupRepositoryImpl({required GroupRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final GroupRemoteDataSource _remoteDataSource;

  @override
  Future<GroupModel> createGroup({required String name, String? description}) {
    return _remoteDataSource.createGroup(name: name, description: description);
  }

  @override
  Future<List<GroupModel>> getUserGroups(String userId) {
    return _remoteDataSource.getUserGroups(userId);
  }

  @override
  Future<GroupModel?> getGroupById(String groupId) {
    return _remoteDataSource.getGroupById(groupId);
  }

  @override
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) {
    return _remoteDataSource.getGroupMembers(groupId);
  }

  @override
  Future<GroupMemberModel> addMember({
    required String groupId,
    required String userId,
    String? invitedBy,
    GroupMemberRole role = GroupMemberRole.member,
  }) {
    return _remoteDataSource.addMember(
      groupId: groupId,
      userId: userId,
      invitedBy: invitedBy,
      role: role,
    );
  }

  @override
  Future<void> removeMember({required String groupId, required String userId}) {
    return _remoteDataSource.removeMember(groupId: groupId, userId: userId);
  }
}
