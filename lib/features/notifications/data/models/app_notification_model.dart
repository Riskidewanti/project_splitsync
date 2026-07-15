import 'package:equatable/equatable.dart';

enum AppNotificationType {
  expense('expense'),
  invitation('invitation'),
  bill('bill'),
  payment('payment');

  const AppNotificationType(this.value);

  final String value;

  static AppNotificationType fromValue(String value) {
    return AppNotificationType.values.firstWhere(
      (AppNotificationType type) => type.value == value,
      orElse: () => AppNotificationType.expense,
    );
  }
}

class AppNotificationModel extends Equatable {
  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.groupId,
  });

  final String id;
  final String title;
  final String description;
  final AppNotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? groupId;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: _requiredString(json['id'], 'id'),
      title: _requiredString(json['title'], 'title'),
      description: _requiredString(json['description'], 'description'),
      type: AppNotificationType.fromValue(
        _requiredString(json['type'], 'type'),
      ),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      isRead: json['is_read'] as bool? ?? false,
      groupId: json['group_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'type': type.value,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'group_id': groupId,
    };
  }

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    AppNotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    Object? groupId = _sentinel,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      groupId: identical(groupId, _sentinel) ? this.groupId : groupId as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        description,
        type,
        createdAt,
        isRead,
        groupId,
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
  if (value is DateTime) {
    return value;
  }

  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }

  throw FormatException('Missing required DateTime field: $key');
}
