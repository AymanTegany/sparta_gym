import '../../../../../core/database/database_helper.dart';
import '../../domain/entities/expense_entity.dart';

abstract class ExpensesLocalDataSource {
  Future<List<Expense>> getAllExpenses();
  Future<int> addExpense(Expense expense);
  Future<int> deleteExpense(int id);
}

class ExpensesLocalDataSourceImpl implements ExpensesLocalDataSource {
  final DatabaseHelper databaseHelper;

  ExpensesLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<Expense>> getAllExpenses() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('expenses', orderBy: 'date DESC, id DESC');
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  @override
  Future<int> addExpense(Expense expense) async {
    final db = await databaseHelper.database;
    return await db.insert('expenses', expense.toMap());
  }

  @override
  Future<int> deleteExpense(int id) async {
    final db = await databaseHelper.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
