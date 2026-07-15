import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class GetExpenseUseCase {
  const GetExpenseUseCase(this.repository);

  final ExpenseRepository repository;

  Future<ExpenseEntity?> call(String expenseId) {
    return repository.getExpenseById(expenseId);
  }
}
