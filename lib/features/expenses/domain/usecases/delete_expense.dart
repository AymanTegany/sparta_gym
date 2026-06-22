import '../repositories/expenses_repository.dart';

class DeleteExpenseUseCase {
  final ExpensesRepository repository;

  DeleteExpenseUseCase(this.repository);

  Future<int> call(int id) async {
    return await repository.deleteExpense(id);
  }
}
