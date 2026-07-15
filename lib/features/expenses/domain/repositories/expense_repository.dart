import '../entities/expense_entity.dart';

abstract class ExpenseRepository {
  /// Create a new expense
  Future<ExpenseEntity> createExpense({
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
  });

  /// Get expense by ID
  Future<ExpenseEntity?> getExpenseById(String expenseId);

  /// Get all expenses for a group
  Future<List<ExpenseEntity>> getExpensesByGroupId(String groupId);

  /// Get all expenses paid by a user
  Future<List<ExpenseEntity>> getExpensesByPaidBy(String userId);

  /// Update an expense
  Future<ExpenseEntity> updateExpense({
    required String expenseId,
    String? paidBy,
    double? amount,
    String? category,
    String? description,
    int? itemCount,
    List<String>? tags,
    String? note,
    String? receipt,
  });

  /// Delete an expense
  Future<void> deleteExpense(String expenseId);

  /// Get expense history for a group (paginated)
  Future<List<ExpenseEntity>> getExpenseHistory({
    required String groupId,
    int limit = 20,
    int offset = 0,
  });
}
