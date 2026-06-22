import '../entities/expense_entity.dart';
import '../repositories/expenses_repository.dart';

class AddExpenseUseCase {
  final ExpensesRepository repository;

  AddExpenseUseCase(this.repository);

  Future<int> call(Expense expense) async {
    return await repository.addExpense(expense);
  }
}
