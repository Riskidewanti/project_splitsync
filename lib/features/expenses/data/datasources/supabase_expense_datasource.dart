import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expense_model.dart';
import 'expense_datasource.dart';

class SupabaseExpenseDatasource implements ExpenseDatasource {
  SupabaseExpenseDatasource(this._client);

  final SupabaseClient _client;

  static const String _table = 'expenses';

  @override
  Future<ExpenseModel> createExpense({
    required String groupId,
    required String paidBy,
    required double amount,
    required String category,
    required String description,
    int? itemCount,
    List<String>? tags,
    String? note,
    String? receipt,
    String? ocrJobId,
  }) async {
    final String now = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic> data = <String, dynamic>{
      'total_amount': amount,
      'title': description,
      'expense_date': now,
      'currency': 'IDR',
      'status': 'pending',
      'split_method': 'equal',
      'created_at': now,
      'updated_at': now,
    };
    _putUuidIfValid(data, 'group_id', groupId);
    _putUuidIfValid(data, 'payer_id', paidBy);

    final Map<String, dynamic> response = await _client
        .from(_table)
        .insert(data)
        .select()
        .single();
    return ExpenseModel.fromJson(response);
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _client.from(_table).delete().eq('id', expenseId);
  }

  @override
  Future<ExpenseModel?> getExpenseById(String expenseId) async {
    final Map<String, dynamic>? response = await _client
        .from(_table)
        .select()
        .eq('id', expenseId)
        .maybeSingle();
    if (response == null) return null;
    return ExpenseModel.fromJson(response);
  }

  @override
  Future<List<ExpenseModel>> getExpenseHistory({
    required String groupId,
    int limit = 20,
    int offset = 0,
  }) async {
    final List<dynamic> response = await _client
        .from(_table)
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return response
        .map((dynamic row) => row as Map<String, dynamic>)
        .map(ExpenseModel.fromJson)
        .toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByGroupId(String groupId) async {
    final List<dynamic> response = await _client
        .from(_table)
        .select()
        .eq('group_id', groupId);
    return response
        .map((dynamic row) => row as Map<String, dynamic>)
        .map(ExpenseModel.fromJson)
        .toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByPaidBy(String userId) async {
    final List<dynamic> response = await _client
        .from(_table)
        .select()
        .eq('payer_id', userId);
    return response
        .map((dynamic row) => row as Map<String, dynamic>)
        .map(ExpenseModel.fromJson)
        .toList();
  }

  @override
  Future<ExpenseModel> updateExpense({
    required String expenseId,
    String? paidBy,
    double? amount,
    String? category,
    String? description,
    int? itemCount,
    List<String>? tags,
    String? note,
    String? receipt,
  }) async {
    final Map<String, dynamic> data = <String, dynamic>{
      'total_amount': amount,
      'title': description,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (paidBy != null) {
      _putUuidIfValid(data, 'payer_id', paidBy);
    }
    data.removeWhere((String key, dynamic value) => value == null);

    final Map<String, dynamic> response = await _client
        .from(_table)
        .update(data)
        .eq('id', expenseId)
        .select()
        .single();
    return ExpenseModel.fromJson(response);
  }

  void _putUuidIfValid(Map<String, dynamic> data, String key, String value) {
    if (_isUuid(value)) {
      data[key] = value;
    }
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}
