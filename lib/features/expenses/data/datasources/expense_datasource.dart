import '../models/expense_model.dart';

abstract class ExpenseDatasource {
  /// Create a new expense
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
  });

  /// Get expense by ID
  Future<ExpenseModel?> getExpenseById(String expenseId);

  /// Get all expenses for a group
  Future<List<ExpenseModel>> getExpensesByGroupId(String groupId);

  /// Get all expenses paid by a user
  Future<List<ExpenseModel>> getExpensesByPaidBy(String userId);

  /// Update an expense
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
  });

  /// Delete an expense
  Future<void> deleteExpense(String expenseId);

  /// Get expense history for a group (paginated)
  Future<List<ExpenseModel>> getExpenseHistory({
    required String groupId,
    int limit = 20,
    int offset = 0,
  });
}
