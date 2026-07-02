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
      id: _safeString(json['id'], ''),
      groupId: _safeString(json['group_id'], ''),
      userId: _safeString(json['user_id'], ''),

      displayName: _nullableStringCoerce(
        profile?['display_name'] ?? profile?['user_name'],
      ),
      email: _nullableStringCoerce(profile?['email']),
      avatarUrl: _nullableStringCoerce(profile?['avatar_url']),

      invitedBy: _nullableStringCoerce(json['invited_by']),
      role: _safeRole(json['role']),
      status: _safeStatus(json['status']),
      joinedAt: _safeDateTime(json['joined_at']),
      leftAt: _safeDateTime(json['left_at']),
      createdAt: _safeDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _safeDateTime(json['updated_at']) ?? DateTime.now(),
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

String _safeString(Object? value, String fallback) {
  if (value == null) return fallback;
  final String str = value.toString().trim();
  return str.isEmpty ? fallback : str;
}

String? _nullableStringCoerce(Object? value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

GroupMemberRole _safeRole(Object? value) {
  if (value == null) return GroupMemberRole.member;
  final String valStr = value.toString().trim().toLowerCase();
  for (final role in GroupMemberRole.values) {
    if (role.value.toLowerCase() == valStr) {
      return role;
    }
  }
  return GroupMemberRole.member;
}

GroupMemberStatus _safeStatus(Object? value) {
  if (value == null) return GroupMemberStatus.active;
  final String valStr = value.toString().trim().toLowerCase();
  for (final status in GroupMemberStatus.values) {
    if (status.value.toLowerCase() == valStr) {
      return status;
    }
  }
  return GroupMemberStatus.active;
}

DateTime? _safeDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  try {
    final String str = value.toString().trim();
    if (str.isEmpty) return null;
    return DateTime.parse(str);
  } catch (_) {
    return null;
  }
}

