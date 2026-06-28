import '../repositories/expense_repository.dart';

class DeleteExpenseUseCase {
  const DeleteExpenseUseCase(this.repository);

  final ExpenseRepository repository;

  Future<void> call(String expenseId) {
    return repository.deleteExpense(expenseId);
  }
}
