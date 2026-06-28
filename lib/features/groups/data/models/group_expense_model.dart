import 'package:equatable/equatable.dart';

class GroupExpenseModel extends Equatable {
  const GroupExpenseModel({
    required this.id,
    required this.groupId,
    required this.payerId,
    required this.title,
    required this.expenseDate,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.merchantName,
  });

  final String id;
  final String groupId;
  final String payerId;
  final String title;
  final String? merchantName;
  final DateTime expenseDate;
  final double totalAmount;
  final String currency;
  final String status;
  final DateTime createdAt;

  factory GroupExpenseModel.fromJson(Map<String, dynamic> json) {
    return GroupExpenseModel(
      id: _requiredString(json['id'], 'id'),
      groupId: _requiredString(json['group_id'], 'group_id'),
      payerId: _requiredString(json['payer_id'], 'payer_id'),
      title: _requiredString(json['title'], 'title'),
      merchantName: json['merchant_name'] as String?,
      expenseDate: _requiredDateTime(json['expense_date'], 'expense_date'),
      totalAmount: _requiredDouble(json['total_amount'], 'total_amount'),
      currency: _requiredString(json['currency'], 'currency'),
      status: _requiredString(json['status'], 'status'),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    groupId,
    payerId,
    title,
    merchantName,
    expenseDate,
    totalAmount,
    currency,
    status,
    createdAt,
  ];
}

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

double _requiredDouble(Object? value, String key) {
  if (value is num) {
    return value.toDouble();
  }

  throw FormatException('Missing required number field: $key');
}
