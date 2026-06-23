import 'package:equatable/equatable.dart';

enum ExpenseCategory {
  food('food'),
  transport('transport'),
  entertainment('entertainment'),
  utilities('utilities'),
  shopping('shopping'),
  other('other');

  const ExpenseCategory(this.value);

  final String value;

  static ExpenseCategory fromValue(String value) {
    return ExpenseCategory.values.firstWhere(
      (ExpenseCategory category) => category.value == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

class ExpenseModel extends Equatable {
  const ExpenseModel({
    required this.id,
    required this.groupId,
    required this.paidBy,
    required this.amount,
    required this.category,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.itemCount,
    this.tags = const <String>[],
    this.note,
    this.receipt,
    this.ocrJobId,
  });

  final String id;
  final String groupId;
  final String paidBy;
  final double amount;
  final ExpenseCategory category;
  final String description;
  final int? itemCount;
  final List<String> tags;
  final String? note;
  final String? receipt;
  final String? ocrJobId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: _requiredString(json['id'], 'id'),
      groupId: _optionalString(json['group_id'], fallback: ''),
      paidBy: _requiredString(
        json['paid_by'] ?? json['payer_id'],
        'paid_by/payer_id',
      ),
      amount: _requiredDouble(
        json['amount'] ?? json['total_amount'],
        'amount/total_amount',
      ),
      category: ExpenseCategory.fromValue(
        _optionalString(json['category'], fallback: 'other'),
      ),
      description: _requiredString(
        json['description'] ?? json['title'],
        'description/title',
      ),
      itemCount: json['item_count'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      note: json['note'] as String?,
      receipt: json['receipt'] as String?,
      ocrJobId: json['ocr_job_id'] as String?,
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      updatedAt: _requiredDateTime(json['updated_at'], 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'group_id': groupId,
      'payer_id': paidBy,
      'total_amount': amount,
      'category': category.value,
      'title': description,

      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? groupId,
    String? paidBy,
    double? amount,
    ExpenseCategory? category,
    String? description,
    int? itemCount,
    List<String>? tags,
    Object? note = _sentinel,
    Object? receipt = _sentinel,
    Object? ocrJobId = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      paidBy: paidBy ?? this.paidBy,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      itemCount: itemCount ?? this.itemCount,
      tags: tags ?? this.tags,
      note: identical(note, _sentinel) ? this.note : note as String?,
      receipt: identical(receipt, _sentinel)
          ? this.receipt
          : receipt as String?,
      ocrJobId: identical(ocrJobId, _sentinel)
          ? this.ocrJobId
          : ocrJobId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    groupId,
    paidBy,
    amount,
    category,
    description,
    itemCount,
    tags,
    note,
    receipt,
    ocrJobId,
    createdAt,
    updatedAt,
  ];
}

const Object _sentinel = Object();

String _optionalString(Object? value, {required String fallback}) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return fallback;
}

String _requiredString(Object? value, String key) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing required string field: $key');
}

double _requiredDouble(Object? value, String key) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  throw FormatException('Missing required double field: $key');
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
