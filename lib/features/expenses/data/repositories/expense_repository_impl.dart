import '../datasources/expense_datasource.dart';
import '../models/expense_model.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl extends ExpenseRepository {
  ExpenseRepositoryImpl(this.datasource);

  final ExpenseDatasource datasource;

  @override
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
  }) async {
    final ExpenseModel model = await datasource.createExpense(
      groupId: groupId,
      paidBy: paidBy,
      amount: amount,
      category: category,
      description: description,
      itemCount: itemCount,
      tags: tags,
      note: note,
      receipt: receipt,
      ocrJobId: ocrJobId,
    );
    return ExpenseEntity.fromModel(model);
  }

  @override
  Future<ExpenseEntity?> getExpenseById(String expenseId) async {
    final ExpenseModel? model = await datasource.getExpenseById(expenseId);
    return model != null ? ExpenseEntity.fromModel(model) : null;
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByGroupId(String groupId) async {
    final List<ExpenseModel> models = await datasource.getExpensesByGroupId(groupId);
    return models.map((ExpenseModel model) => ExpenseEntity.fromModel(model)).toList();
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByPaidBy(String userId) async {
    final List<ExpenseModel> models = await datasource.getExpensesByPaidBy(userId);
    return models.map((ExpenseModel model) => ExpenseEntity.fromModel(model)).toList();
  }

  @override
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
  }) async {
    final ExpenseModel model = await datasource.updateExpense(
      expenseId: expenseId,
      paidBy: paidBy,
      amount: amount,
      category: category,
      description: description,
      itemCount: itemCount,
      tags: tags,
      note: note,
      receipt: receipt,
    );
    return ExpenseEntity.fromModel(model);
  }

  @override
  Future<void> deleteExpense(String expenseId) {
    return datasource.deleteExpense(expenseId);
  }

  @override
  Future<List<ExpenseEntity>> getExpenseHistory({
    required String groupId,
    int limit = 20,
    int offset = 0,
  }) async {
    final List<ExpenseModel> models = await datasource.getExpenseHistory(
      groupId: groupId,
      limit: limit,
      offset: offset,
    );
    return models.map((ExpenseModel model) => ExpenseEntity.fromModel(model)).toList();
  }
}
