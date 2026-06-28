import 'package:equatable/equatable.dart';

class GroupUserModel extends Equatable {
  const GroupUserModel({
    required this.id,
    this.displayName,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String? displayName;
  final String? email;
  final String? avatarUrl;

  String get label {
    final String? name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final String? address = email?.trim();
    if (address != null && address.isNotEmpty) {
      return address;
    }

    return 'User ${id.substring(0, 8)}';
  }

  String get initial {
    final String value = label.trim();
    return value.isEmpty ? '?' : value.substring(0, 1).toUpperCase();
  }

  factory GroupUserModel.fromJson(Map<String, dynamic> json) {
    return GroupUserModel(
      id: _requiredString(json['id'], 'id'),
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, displayName, email, avatarUrl];
}

String _requiredString(Object? value, String key) {
  if (value is String && value.isNotEmpty) {
    return value;
  }

  throw FormatException('Missing required string field: $key');
}
