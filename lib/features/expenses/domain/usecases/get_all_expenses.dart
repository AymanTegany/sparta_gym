import '../entities/expense_entity.dart';
import '../repositories/expenses_repository.dart';

class GetAllExpensesUseCase {
  final ExpensesRepository repository;

  GetAllExpensesUseCase(this.repository);

  Future<List<Expense>> call() async {
    return await repository.getAllExpenses();
  }
}
