import 'package:flutter/material.dart';
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
    required String groupId,
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
    required List<String> participantIds,
  }) async {
    debugPrint("========== AUTH ==========");
    debugPrint(
      "CurrentUser : ${Supabase.instance.client.auth.currentUser?.id}",
    );
    debugPrint(
      "Session     : ${Supabase.instance.client.auth.currentSession != null}",
    );
    debugPrint(
      "AccessToken : ${Supabase.instance.client.auth.currentSession?.accessToken.substring(0, 20)}...",
    );
    final String currentUserId = await _requireCurrentUserId();
    debugPrint("========================");
    debugPrint("USER ID = $currentUserId");
    debugPrint("IS UUID = ${_isUuid(currentUserId)}");
    debugPrint("GROUP ID = $groupId");
    debugPrint("GROUP UUID = ${_isUuid(groupId)}");

    final rows = await _client
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);

    debugPrint("GROUP MEMBERS = $rows");

    debugPrint("PARTICIPANT IDS = $participantIds");
    debugPrint("========================");

    debugPrint("CurrentUserId = $currentUserId");
    debugPrint("CURRENT USER = $currentUserId");
    debugPrint("PARTICIPANTS = $participantIds");
    debugPrint("CurrentUserId = $currentUserId");
    debugPrint("AUTH USER = ${Supabase.instance.client.auth.currentUser?.id}");

    debugPrint(
      "SESSION = ${Supabase.instance.client.auth.currentSession != null}",
    );
    if (!_isUuid(groupId)) {
      throw const FormatException('Group ID tidak valid untuk pengeluaran.');
    }
    debugPrint("STEP 1 - INSERT EXPENSE");
    final Map<String, dynamic> expenseRow = await _client
        .from('expenses')
        .insert(<String, dynamic>{
          'group_id': groupId,
          'payer_id': currentUserId,
          'created_by': currentUserId,
          'title': merchantName.trim().isEmpty
              ? 'Receipt'
              : merchantName.trim(),
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

    final test = await _client.from('expenses').select().eq('id', expenseId);

    debugPrint("TEST EXPENSE = $test");
    debugPrint("STEP 2 - EXPENSE ID : $expenseId");
    debugPrint("STEP 3 - INSERT EXPENSE ITEMS");
    debugPrint("ExpenseId = $expenseId");

    for (final item in items) {
      debugPrint(
        "Item => "
        "name=${item.name}, "
        "qty=${item.quantity}, "
        "price=${item.unitPrice}",
      );
    }
    try {
      final insertedItems = await _client.from('expense_items').insert([
        for (int index = 0; index < items.length; index++)
          {
            'expense_id': expenseId,
            'name': items[index].name,
            'quantity': items[index].quantity,
            'unit_price': items[index].unitPrice,
            'sort_order': index,
          },
      ]).select();

      debugPrint("INSERTED ITEMS = $insertedItems");

      final expenseItemId = insertedItems.first['id'];

      debugPrint("STEP 4 - EXPENSE ITEM ID = $expenseItemId");

      final members = participantIds.where((e) => e != currentUserId).toList();

      debugPrint("==================================");
      debugPrint("CURRENT USER = $currentUserId");
      debugPrint("PARTICIPANTS = $participantIds");
      debugPrint("MEMBERS = $members");
      debugPrint("COUNT = ${members.length}");
      debugPrint("==================================");

      final splitAmount = totalAmount / members.length;
      debugPrint("MEMBERS AFTER FILTER = $members");
      debugPrint("TOTAL = $totalAmount");
      debugPrint("SPLIT = $splitAmount");
      for (int i = 0; i < members.length; i++) {
        final userId = members[i];

        double amount = splitAmount;

        // supaya total pas 200000
        if (i == members.length - 1) {
          final used = splitAmount * (members.length - 1);
          amount = totalAmount - used;
        }

        debugPrint("INSERT SPLIT => $userId");
        debugPrint("AMOUNT = $amount");

        await _client.from('split_bill').insert({
          'expense_id': expenseId,
          'expense_item_id': expenseItemId,
          'user_id': userId,
          'exact_amount': amount,
          'share_percentage': null,
          'currency': 'IDR',
          'category': 'General',
          'is_paid': false,
        });

        debugPrint("SUCCESS INSERT SPLIT");
      }
    } on PostgrestException catch (e, st) {
      debugPrint("========== POSTGREST ERROR ==========");
      debugPrint("MESSAGE : ${e.message}");
      debugPrint("CODE    : ${e.code}");
      debugPrint("DETAILS : ${e.details}");
      debugPrint("HINT    : ${e.hint}");
      debugPrint(st.toString());
      rethrow;
    } catch (e, st) {
      debugPrint("========== OTHER ERROR ==========");
      debugPrint(e.toString());
      debugPrint(st.toString());
      rethrow;
    }

    return expenseId;
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
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
