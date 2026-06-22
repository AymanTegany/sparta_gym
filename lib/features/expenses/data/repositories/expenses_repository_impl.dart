import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../datasources/expenses_local_data_source.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  final ExpensesLocalDataSource localDataSource;

  ExpensesRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Expense>> getAllExpenses() async {
    return await localDataSource.getAllExpenses();
  }

  @override
  Future<int> addExpense(Expense expense) async {
    return await localDataSource.addExpense(expense);
  }

  @override
  Future<int> deleteExpense(int id) async {
    return await localDataSource.deleteExpense(id);
  }
}
