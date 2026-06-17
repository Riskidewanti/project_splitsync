import 'package:equatable/equatable.dart';

class GroupModel extends Equatable {
  const GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.archivedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: _requiredString(json['id'], 'id'),
      name: _requiredString(json['name'], 'name'),
      description: json['description'] as String?,
      createdBy: _requiredString(json['created_by'], 'created_by'),
      archivedAt: _nullableDateTime(json['archived_at']),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      updatedAt: _requiredDateTime(json['updated_at'], 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'archived_at': archivedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    Object? description = _sentinel,
    String? createdBy,
    Object? archivedAt = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: identical(description, _sentinel)
          ? this.description
          : description as String?,
      createdBy: createdBy ?? this.createdBy,
      archivedAt: identical(archivedAt, _sentinel)
          ? this.archivedAt
          : archivedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    description,
    createdBy,
    archivedAt,
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
