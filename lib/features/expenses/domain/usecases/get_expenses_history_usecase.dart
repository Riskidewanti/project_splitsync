import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class GetExpensesHistoryUseCase {
  const GetExpensesHistoryUseCase(this.repository);

  final ExpenseRepository repository;

  Future<List<ExpenseEntity>> call({
    required String groupId,
    int limit = 20,
    int offset = 0,
  }) {
    return repository.getExpenseHistory(
      groupId: groupId,
      limit: limit,
      offset: offset,
    );
  }
}
