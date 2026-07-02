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
      id: _safeString(json['id'], ''),
      groupId: _safeString(json['group_id'], ''),
      payerId: _safeString(json['payer_id'], ''),
      title: _safeString(json['title'], 'Pengeluaran Tanpa Judul'),
      merchantName: _nullableStringCoerce(json['merchant_name']),
      expenseDate: _safeDateTime(json['expense_date']) ?? DateTime.now(),
      totalAmount: _safeDouble(json['total_amount'], 0.0),
      currency: _safeString(json['currency'], 'IDR'),
      status: _safeString(json['status'], 'active'),
      createdAt: _safeDateTime(json['created_at']) ?? DateTime.now(),
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

double _safeDouble(Object? value, double fallback) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  try {
    return double.parse(value.toString());
  } catch (_) {
    return fallback;
  }
}

