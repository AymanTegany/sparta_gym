import '../entities/expense_entity.dart';

abstract class ExpensesRepository {
  Future<List<Expense>> getAllExpenses();
  Future<int> addExpense(Expense expense);
  Future<int> deleteExpense(int id);
}
