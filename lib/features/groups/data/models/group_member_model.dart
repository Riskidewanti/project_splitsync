import 'package:equatable/equatable.dart';

enum GroupMemberRole {
  owner('owner'),
  admin('admin'),
  member('member');

  const GroupMemberRole(this.value);

  final String value;

  static GroupMemberRole fromValue(String value) {
    return GroupMemberRole.values.firstWhere(
      (GroupMemberRole role) => role.value == value,
      orElse: () => throw FormatException('Unknown group member role: $value'),
    );
  }
}

enum GroupMemberStatus {
  invited('invited'),
  active('active'),
  left('left'),
  removed('removed');

  const GroupMemberStatus(this.value);

  final String value;

  static GroupMemberStatus fromValue(String value) {
    return GroupMemberStatus.values.firstWhere(
      (GroupMemberStatus status) => status.value == value,
      orElse: () =>
          throw FormatException('Unknown group member status: $value'),
    );
  }
}

class GroupMemberModel extends Equatable {
  const GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.userId,

    this.displayName,
    this.email,
    this.avatarUrl,

    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.invitedBy,
    this.joinedAt,
    this.leftAt,
  });

  final String id;
  final String groupId;
  final String userId;

  final String? displayName;
  final String? email;
  final String? avatarUrl;

  final String? invitedBy;
  final GroupMemberRole role;
  final GroupMemberStatus status;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? profile = json['profiles'] is Map
        ? Map<String, dynamic>.from(json['profiles'] as Map)
        : null;

    return GroupMemberModel(
      id: _requiredString(json['id'], 'id'),
      groupId: _requiredString(json['group_id'], 'group_id'),
      userId: _requiredString(json['user_id'], 'user_id'),

      displayName: profile?['display_name'] as String?,
      email: profile?['email'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,

      invitedBy: json['invited_by'] as String?,
      role: GroupMemberRole.fromValue(_requiredString(json['role'], 'role')),
      status: GroupMemberStatus.fromValue(
        _requiredString(json['status'], 'status'),
      ),
      joinedAt: _nullableDateTime(json['joined_at']),
      leftAt: _nullableDateTime(json['left_at']),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      updatedAt: _requiredDateTime(json['updated_at'], 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'display_name': displayName,
      'email': email,
      'avatar_url': avatarUrl,
      'invited_by': invitedBy,
      'role': role.value,
      'status': status.value,
      'joined_at': joinedAt?.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GroupMemberModel copyWith({
    String? id,
    String? groupId,
    String? userId,
    Object? invitedBy = _sentinel,
    Object? displayName = _sentinel,
    Object? email = _sentinel,
    Object? avatarUrl = _sentinel,
    GroupMemberRole? role,
    GroupMemberStatus? status,
    Object? joinedAt = _sentinel,
    Object? leftAt = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupMemberModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      displayName: identical(displayName, _sentinel)
          ? this.displayName
          : displayName as String?,
      email: identical(email, _sentinel) ? this.email : email as String?,
      avatarUrl: identical(avatarUrl, _sentinel)
          ? this.avatarUrl
          : avatarUrl as String?,
      invitedBy: identical(invitedBy, _sentinel)
          ? this.invitedBy
          : invitedBy as String?,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: identical(joinedAt, _sentinel)
          ? this.joinedAt
          : joinedAt as DateTime?,
      leftAt: identical(leftAt, _sentinel) ? this.leftAt : leftAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    groupId,
    userId,
    displayName,
    email,
    avatarUrl,
    invitedBy,
    role,
    status,
    joinedAt,
    leftAt,
    createdAt,
    updatedAt,
  ];
}

const Object _sentinel = Object();

String _requiredString(Object? value, String key) {
  if (value is String && value.isNotEmpty) {
    return value;
  }

  throw FormatException('Missing required string field: $key');
}

DateTime _requiredDateTime(Object? value, String key) {
  final DateTime? dateTime = _nullableDateTime(value);
  if (dateTime != null) {
    return dateTime;
  }

  throw FormatException('Missing required DateTime field: $key');
}

DateTime? _nullableDateTime(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }

  throw FormatException('Invalid DateTime value: $value');
}
