import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/usecases/get_all_expenses.dart';
import '../../domain/usecases/add_expense.dart';
import '../../domain/usecases/delete_expense.dart';
import 'expenses_state.dart';

class ExpensesCubit extends Cubit<ExpensesState> {
  final GetAllExpensesUseCase getAllExpenses;
  final AddExpenseUseCase addExpenseUseCase;
  final DeleteExpenseUseCase deleteExpenseUseCase;

  ExpensesCubit({
    required this.getAllExpenses,
    required this.addExpenseUseCase,
    required this.deleteExpenseUseCase,
  }) : super(ExpensesInitial());

  Future<void> loadExpenses() async {
    emit(ExpensesLoading());
    try {
      final expenses = await getAllExpenses();
      emit(ExpensesLoaded(expenses));
    } catch (e) {
      emit(ExpensesError(e.toString()));
    }
  }

  Future<void> addExpense(Expense expense, {int? shiftId}) async {
    try {
      final expenseWithShift = Expense(
        id: expense.id,
        title: expense.title,
        category: expense.category,
        amount: expense.amount,
        date: expense.date,
        notes: expense.notes,
        createdAt: expense.createdAt,
        shiftId: shiftId,
      );
      await addExpenseUseCase(expenseWithShift);
      loadExpenses();
    } catch (e) {
      emit(ExpensesError(e.toString()));
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await deleteExpenseUseCase(id);
      loadExpenses();
    } catch (e) {
      emit(ExpensesError(e.toString()));
    }
  }
}
