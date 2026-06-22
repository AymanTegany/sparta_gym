import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/widgets/sidebar_layout.dart';
import '../cubit/expenses_cubit.dart';
import '../cubit/expenses_state.dart';
import '../../domain/entities/expense_entity.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpensesCubit>().loadExpenses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SidebarLayout(
      activePage: 'expenses',
      title: 'إدارة المصروفات',
      body: BlocBuilder<ExpensesCubit, ExpensesState>(
        builder: (context, state) {
          if (state is ExpensesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Container(
                color: theme.cardColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: theme.colorScheme.primary,
                  tabs: const [
                    Tab(text: 'الإيجار', icon: Icon(Icons.home_work_outlined)),
                    Tab(text: 'الكهرباء والمرافق', icon: Icon(Icons.bolt_outlined)),
                    Tab(text: 'الرواتب', icon: Icon(Icons.payments_outlined)),
                    Tab(text: 'المعدات والصيانة', icon: Icon(Icons.build_outlined)),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExpenseSection('إيجار', Icons.home_work_outlined, state),
                    _buildExpenseSection('كهرباء', Icons.bolt_outlined, state),
                    _buildExpenseSection('رواتب', Icons.payments_outlined, state),
                    _buildExpenseSection('معدات', Icons.build_outlined, state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpenseSection(String category, IconData icon, ExpensesState state) {
    List<Expense> categoryExpenses = [];
    if (state is ExpensesLoaded) {
      categoryExpenses = state.expenses.where((e) => e.category == category).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('إجمالي $category: ${categoryExpenses.fold(0.0, (sum, item) => sum + item.amount)} ج.م', 
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                onPressed: () => _showAddExpenseDialog(context, category),
                icon: const Icon(Icons.add),
                label: Text('إضافة مصروف'),
              )
            ],
          ),
        ),
        Expanded(
          child: categoryExpenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد سجلات حالية لـ $category',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: categoryExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = categoryExpenses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(icon)),
                        title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${expense.date} ${expense.notes != null ? '- ${expense.notes}' : ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${expense.amount} ج.م', 
                                 style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                context.read<ExpensesCubit>().deleteExpense(expense.id!);
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddExpenseDialog(BuildContext context, String defaultCategory) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = defaultCategory;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('إضافة مصروف ($defaultCategory)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'الوصف / العنوان'),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'المبلغ (ج.م)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات إضافية'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text;
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (title.isNotEmpty && amount > 0) {
                  final expense = Expense(
                    title: title,
                    category: selectedCategory,
                    amount: amount,
                    date: DateTime.now().toIso8601String().split('T').first,
                    notes: notesController.text,
                    createdAt: DateTime.now().toIso8601String(),
                  );
                  context.read<ExpensesCubit>().addExpense(expense);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }
}
