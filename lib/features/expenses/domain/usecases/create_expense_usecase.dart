import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class CreateExpenseUseCase {
  const CreateExpenseUseCase(this.repository);

  final ExpenseRepository repository;

  Future<ExpenseEntity> call({
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
  }) {
    return repository.createExpense(
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
  }
}
