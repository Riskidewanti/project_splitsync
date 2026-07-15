import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class GetGroupExpensesUseCase {
  const GetGroupExpensesUseCase(this.repository);

  final ExpenseRepository repository;

  Future<List<ExpenseEntity>> call(String groupId) {
    return repository.getExpensesByGroupId(groupId);
  }
}
