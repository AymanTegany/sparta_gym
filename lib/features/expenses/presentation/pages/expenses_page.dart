import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/widgets/sidebar_layout.dart';
import '../../../../core/theme/color_palette.dart';
import '../cubit/expenses_cubit.dart';
import '../cubit/expenses_state.dart';
import '../../domain/entities/expense_entity.dart';
import '../../../../features/shifts/presentation/cubit/shifts_cubit.dart';

enum ExpenseDateFilter {
  all('الكل', Icons.all_inclusive_rounded),
  today('اليوم', Icons.today_rounded),
  yesterday('أمس', Icons.history_rounded),
  dayBeforeYesterday('أول أمس', Icons.replay_rounded),
  thisWeek('هذا الأسبوع', Icons.date_range_rounded),
  thisMonth('هذا الشهر', Icons.calendar_month_rounded),
  custom('تاريخ مخصص', Icons.edit_calendar_rounded);

  final String label;
  final IconData icon;
  const ExpenseDateFilter(this.label, this.icon);
}

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ExpenseDateFilter _selectedFilter = ExpenseDateFilter.all;
  DateTime? _customSelectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpensesCubit>().loadExpenses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _matchesDateFilter(Expense expense) {
    DateTime? expenseDate = DateTime.tryParse(expense.date);
    if (expenseDate == null) {
      final parsedCreated = DateTime.tryParse(expense.createdAt);
      if (parsedCreated != null) {
        expenseDate = DateTime(parsedCreated.year, parsedCreated.month, parsedCreated.day);
      }
    } else {
      expenseDate = DateTime(expenseDate.year, expenseDate.month, expenseDate.day);
    }

    if (expenseDate == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBeforeYesterday = today.subtract(const Duration(days: 2));

    switch (_selectedFilter) {
      case ExpenseDateFilter.all:
        return true;
      case ExpenseDateFilter.today:
        return expenseDate.isAtSameMomentAs(today);
      case ExpenseDateFilter.yesterday:
        return expenseDate.isAtSameMomentAs(yesterday);
      case ExpenseDateFilter.dayBeforeYesterday:
        return expenseDate.isAtSameMomentAs(dayBeforeYesterday);
      case ExpenseDateFilter.thisWeek:
        final weekStart = today.subtract(const Duration(days: 6));
        return !expenseDate.isBefore(weekStart) && !expenseDate.isAfter(today);
      case ExpenseDateFilter.thisMonth:
        return expenseDate.year == today.year && expenseDate.month == today.month;
      case ExpenseDateFilter.custom:
        if (_customSelectedDate != null) {
          final target = DateTime(
            _customSelectedDate!.year,
            _customSelectedDate!.month,
            _customSelectedDate!.day,
          );
          return expenseDate.isAtSameMomentAs(target);
        }
        return true;
    }
  }

  String _getDateBadgeText(String dateStr) {
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expenseDate = DateTime(parsed.year, parsed.month, parsed.day);

    if (expenseDate.isAtSameMomentAs(today)) {
      return 'اليوم ($dateStr)';
    } else if (expenseDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'أمس ($dateStr)';
    } else if (expenseDate.isAtSameMomentAs(today.subtract(const Duration(days: 2)))) {
      return 'أول أمس ($dateStr)';
    }
    return dateStr;
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
                    Tab(text: 'المصروفات اليومية', icon: Icon(Icons.receipt_long_outlined)),
                  ],
                ),
              ),
              _buildFilterBar(context),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExpenseSection('إيجار', Icons.home_work_outlined, state),
                    _buildExpenseSection('كهرباء', Icons.bolt_outlined, state),
                    _buildExpenseSection('رواتب', Icons.payments_outlined, state),
                    _buildExpenseSection('معدات', Icons.build_outlined, state),
                    _buildExpenseSection('مصروفات يومية', Icons.receipt_long_outlined, state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_alt_outlined, size: 18, color: primaryColor),
              const SizedBox(width: 6),
              const Text(
                'تصفية حسب الوقت:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ExpenseDateFilter.values.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  String displayLabel = filter.label;
                  if (filter == ExpenseDateFilter.custom && _customSelectedDate != null) {
                    final d = _customSelectedDate!;
                    displayLabel = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          if (filter == ExpenseDateFilter.custom) {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _customSelectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              locale: const Locale('ar'),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedFilter = ExpenseDateFilter.custom;
                                _customSelectedDate = picked;
                              });
                            }
                          } else {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.15)
                                : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                filter.icon,
                                size: 16,
                                color: isSelected
                                    ? primaryColor
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                displayLabel,
                                style: TextStyle(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseSection(String category, IconData icon, ExpensesState state) {
    List<Expense> categoryExpenses = [];
    if (state is ExpensesLoaded) {
      categoryExpenses = state.expenses
          .where((e) => e.category == category && _matchesDateFilter(e))
          .toList();
    }

    final totalAmount = categoryExpenses.fold(0.0, (sum, item) => sum + item.amount);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'إجمالي $category: $totalAmount ج.م',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (_selectedFilter != ExpenseDateFilter.all) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ColorPalette.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedFilter == ExpenseDateFilter.custom && _customSelectedDate != null
                            ? 'بتاريخ: ${_customSelectedDate!.year}-${_customSelectedDate!.month.toString().padLeft(2, '0')}-${_customSelectedDate!.day.toString().padLeft(2, '0')}'
                            : _selectedFilter.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddExpenseDialog(context, category),
                icon: const Icon(Icons.add),
                label: const Text('إضافة مصروف'),
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
                        _selectedFilter == ExpenseDateFilter.all
                            ? 'لا توجد سجلات حالية لـ $category'
                            : 'لا توجد مصروفات لـ $category في الفترة المحددة (${_selectedFilter.label})',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: categoryExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = categoryExpenses[index];
                    final dateLabel = _getDateBadgeText(expense.date);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(icon)),
                        title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$dateLabel ${expense.notes != null && expense.notes!.isNotEmpty ? '- ${expense.notes}' : ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${expense.amount} ج.م',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
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
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: ColorPalette.primaryColor),
                            const SizedBox(width: 8),
                            Text('التاريخ: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              locale: const Locale('ar'),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('تغيير'),
                        ),
                      ],
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
                    final title = titleController.text.trim();
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (title.isNotEmpty && amount > 0) {
                      final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                      final expense = Expense(
                        title: title,
                        category: selectedCategory,
                        amount: amount,
                        date: formattedDate,
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        createdAt: DateTime.now().toIso8601String(),
                      );
                      final shiftId = context.read<ShiftsCubit>().currentShiftId;
                      context.read<ExpensesCubit>().addExpense(expense, shiftId: shiftId);
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

