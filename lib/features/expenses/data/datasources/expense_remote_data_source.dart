import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../authentication/auth_service.dart';

class ExpenseItemDraft {
  const ExpenseItemDraft({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final double unitPrice;
}

class ExpenseRemoteDataSource {
  ExpenseRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> createExpense({
    required String merchantName,
    required DateTime expenseDate,
    required List<ExpenseItemDraft> items,
    required double subtotal,
    required double taxAmount,
    required double serviceChargeAmount,
    required double discountAmount,
    required double totalAmount,
    required String splitMethod,
    required double currentUserSplitAmount,
    required double? currentUserPercentage,
  }) async {
    final String currentUserId = await _requireCurrentUserId();

    final Map<String, dynamic> expenseRow = await _client
        .from('expenses')
        .insert(<String, dynamic>{
          'group_id': null,
          'payer_id': currentUserId,
          'created_by': currentUserId,
          'title': merchantName.trim().isEmpty ? 'Receipt' : merchantName.trim(),
          'merchant_name': merchantName.trim().isEmpty
              ? null
              : merchantName.trim(),
          'expense_date': expenseDate.toUtc().toIso8601String(),
          'currency': 'IDR',
          'subtotal': subtotal,
          'tax_amount': taxAmount,
          'service_charge_amount': serviceChargeAmount,
          'discount_amount': discountAmount,
          'total_amount': totalAmount,
          'split_method': splitMethod,
          'status': 'draft',
        })
        .select('id')
        .single();

    final String expenseId = expenseRow['id'] as String;

    if (items.isNotEmpty) {
      await _client.from('expense_items').insert(<Map<String, dynamic>>[
        for (int index = 0; index < items.length; index++)
          <String, dynamic>{
            'expense_id': expenseId,
            'name': items[index].name,
            'quantity': items[index].quantity,
            'unit_price': items[index].unitPrice,
            'sort_order': index,
          },
      ]);
    }

    final double shareRatio = totalAmount <= 0
        ? 0
        : currentUserSplitAmount / totalAmount;

    await _client.from('expense_splits').insert(<String, dynamic>{
      'expense_id': expenseId,
      'user_id': currentUserId,
      'split_method': splitMethod,
      'base_amount': subtotal * shareRatio,
      'tax_share': taxAmount * shareRatio,
      'service_charge_share': serviceChargeAmount * shareRatio,
      'discount_share': discountAmount * shareRatio,
      'total_share': currentUserSplitAmount,
      'percentage': currentUserPercentage,
    });

    return expenseId;
  }

  Future<String> _requireCurrentUserId() async {
    final SessionProfile? profile = await AuthService.currentSession();
    final String? userId = profile?.id;
    if (userId == null) {
      throw const AuthException('User must be logged in to save an expense.');
    }

    return userId;
  }
}
