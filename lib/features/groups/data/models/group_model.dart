import 'package:equatable/equatable.dart';

class GroupModel extends Equatable {
  const GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.photoUrl,
    this.archivedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final String createdBy;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: _safeString(json['id'], ''),
      name: _safeString(json['name'], 'Grup Tanpa Nama'),
      description: _nullableStringCoerce(json['description']),
      photoUrl: _nullableStringCoerce(json['photo_url']),
      createdBy: _safeString(json['created_by'], ''),
      archivedAt: _safeDateTime(json['archived_at']),
      createdAt: _safeDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _safeDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'photo_url': photoUrl,
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
    Object? photoUrl = _sentinel,
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
      photoUrl: identical(photoUrl, _sentinel)
          ? this.photoUrl
          : photoUrl as String?,
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
    photoUrl,
    createdBy,
    archivedAt,
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

