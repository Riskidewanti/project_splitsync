import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class UpdateExpenseUseCase {
  const UpdateExpenseUseCase(this.repository);

  final ExpenseRepository repository;

  Future<ExpenseEntity> call({
    required String expenseId,
    String? paidBy,
    double? amount,
    String? category,
    String? description,
    int? itemCount,
    List<String>? tags,
    String? note,
    String? receipt,
  }) {
    return repository.updateExpense(
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
  }
}
