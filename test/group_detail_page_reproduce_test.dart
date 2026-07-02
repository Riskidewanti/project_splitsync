import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:splitsync/core/theme/app_theme.dart';
import 'package:splitsync/features/groups/domain/repositories/group_repository.dart';
import 'package:splitsync/features/groups/data/models/group_model.dart';
import 'package:splitsync/features/groups/data/models/group_member_model.dart';
import 'package:splitsync/features/groups/data/models/group_expense_model.dart';
import 'package:splitsync/features/groups/data/models/group_user_model.dart';
import 'package:splitsync/features/groups/presentation/pages/group_detail_page.dart';
import 'dart:typed_data';

class MockGroupRepository implements GroupRepository {
  @override
  Future<String?> getCurrentUserId() async => '468efe40-2059-4164-9d39-5dba61998248';

  @override
  Future<List<GroupModel>> getGroups() async {
    return [
      GroupModel.fromJson({
        "id": "9b0dc442-03c4-4a2b-ad3c-f72fae6673fc",
        "name": "Z",
        "description": null,
        "created_by": "468efe40-2059-4164-9d39-5dba61998248",
        "archived_at": null,
        "created_at": "2026-07-01T04:34:33.432432+00:00",
        "updated_at": "2026-07-01T04:34:33.432432+00:00",
        "photo_url": null
      })
    ];
  }

  @override
  Future<GroupModel?> getGroupById(String groupId) async {
    return GroupModel.fromJson({
      "id": "9b0dc442-03c4-4a2b-ad3c-f72fae6673fc",
      "name": "Z",
      "description": null,
      "created_by": "468efe40-2059-4164-9d39-5dba61998248",
      "archived_at": null,
      "created_at": "2026-07-01T04:34:33.432432+00:00",
      "updated_at": "2026-07-01T04:34:33.432432+00:00",
      "photo_url": null
    });
  }

  @override
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    return [
      GroupMemberModel.fromJson({
        "id": "79102fbd-9630-472e-b3f8-a51a0ea9777b",
        "group_id": "9b0dc442-03c4-4a2b-ad3c-f72fae6673fc",
        "user_id": "ee95d504-14da-43ad-a2c4-82199b9b19eb",
        "invited_by": "468efe40-2059-4164-9d39-5dba61998248",
        "role": "member",
        "status": "active",
        "joined_at": "2026-07-01T04:34:33.744+00:00",
        "left_at": null,
        "created_at": "2026-07-01T04:34:33.954166+00:00",
        "updated_at": "2026-07-01T04:34:33.954166+00:00",
        "profiles": {
          "email": "kiki@gmail.com",
          "user_name": "ki",
          "avatar_url": null
        }
      }),
      GroupMemberModel.fromJson({
        "id": "0d0626a8-8526-4bd6-bf56-6bd02a12c710",
        "group_id": "9b0dc442-03c4-4a2b-ad3c-f72fae6673fc",
        "user_id": "468efe40-2059-4164-9d39-5dba61998248",
        "invited_by": "468efe40-2059-4164-9d39-5dba61998248",
        "role": "owner",
        "status": "active",
        "joined_at": "2026-07-01T04:34:33.53+00:00",
        "left_at": null,
        "created_at": "2026-07-01T04:34:33.741476+00:00",
        "updated_at": "2026-07-01T04:34:33.741476+00:00",
        "profiles": {
          "email": "sa@gmail.com",
          "user_name": "sa1",
          "avatar_url": "https://mkdacnbbvjgekosdhevw.supabase.co/storage/v1/object/public/avatars/468efe40-2059-4164-9d39-5dba61998248/profile_1782256747199.jpg"
        }
      })
    ];
  }

  @override
  Future<List<GroupExpenseModel>> getGroupExpenses(String groupId) async => [];

  @override
  Future<GroupModel> createGroup({required String name, String? description, String? photoUrl, List<String> memberUserIds = const <String>[]}) async {
    throw UnimplementedError();
  }
  @override
  Future<String> uploadGroupPhoto({required Uint8List bytes, required String fileName, required String contentType}) async {
    throw UnimplementedError();
  }
  @override
  Future<List<GroupUserModel>> searchUsers(String query) async => [];
  @override
  Future<List<GroupModel>> getUserGroups(String userId) async => [];
  @override
  Future<GroupMemberModel> addMember({required String groupId, required String userId, String? invitedBy, GroupMemberRole role = GroupMemberRole.member}) async {
    throw UnimplementedError();
  }
  @override
  Future<void> removeMember({required String groupId, required String userId}) async {}
  @override
  Future<void> deleteGroup(String groupId) async {}
}

void main() {
  testWidgets('Reproduce GroupDetailPage exception with user data', (tester) async {
    SharedPreferences.setMockInitialValues({
      'splitsync_session_id': 'test-user-id',
      'splitsync_session_email': 'test@example.com',
      'splitsync_session_username': 'testuser',
      'splitsync_session_pin_created': true,
    });

    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      publishableKey: 'sb_publishable_placeholder',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
      ),
    );

    // Note: We need GroupDetailPage to accept repository injection or mock Supabase.
    // Let's check group_detail_page.dart:
    // It constructs GroupRepositoryImpl inline inside _GroupDetailPageState:
    // final GroupRepositoryImpl _groupRepository = GroupRepositoryImpl(
    //   remoteDataSource: GroupRemoteDataSourceImpl(),
    // );
  });
}
