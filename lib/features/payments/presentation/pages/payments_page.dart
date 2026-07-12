import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/color_palette.dart';
import '../../../../core/common/widgets/sidebar_layout.dart';
import '../../domain/entities/payment_entity.dart';
import '../cubit/payments_cubit.dart';
import '../cubit/payments_state.dart';
import '../widgets/add_payment_dialog.dart';
import '../widgets/receipt_dialog.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _dateFilter =
      'all'; // 'all', 'today', 'yesterday', 'dayBeforeYesterday', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    context.read<PaymentsCubit>().loadPaymentsAndStats();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('yyyy/MM/dd hh:mm a').format(date);
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'ar').format(amount);
  }

  void _showAddPaymentDialog() {
    showDialog(context: context, builder: (_) => const AddPaymentDialog()).then(
      (_) {
        context.read<PaymentsCubit>().loadPaymentsAndStats();
      },
    );
  }

  void _showReceiptDialog(Payment payment) {
    showDialog(
      context: context,
      builder: (_) => ReceiptDialog(payment: payment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SidebarLayout(
      activePage: 'payments',
      title: 'إدارة المدفوعات والمالية',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<PaymentsCubit>().loadPaymentsAndStats(),
          tooltip: 'تحديث البيانات',
        ),
      ],
      body: BlocConsumer<PaymentsCubit, PaymentsState>(
        listener: (context, state) {
          if (state is PaymentsActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: ColorPalette.successColor,
              ),
            );
            // إظهار إيصال الدفع تلقائياً للمعاينة والطباعة عند تسجيل الدفع بنجاح
            _showReceiptDialog(state.payment);
          } else if (state is PaymentsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: ColorPalette.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          List<Payment> list = [];
          Map<String, dynamic> stats = {
            'todayRevenue': 0.0,
            'monthRevenue': 0.0,
            'totalRevenue': 0.0,
            'totalDebts': 0.0,
          };
          bool isLoading = state is PaymentsLoading;

          if (state is PaymentsLoaded) {
            list = state.allPayments;
            stats = state.stats;
          }

          // تطبيق فلتر البحث
          final filteredList = list.where((p) {
            final query = _searchQuery.toLowerCase();
            final name = (p.memberName ?? '').toLowerCase();
            final id = p.memberId.toLowerCase();
            final receipt = p.receiptId.toLowerCase();
            final matchesSearch =
                name.contains(query) ||
                id.contains(query) ||
                receipt.contains(query);

            bool matchesDate = true;
            if (_dateFilter != 'all') {
              final paymentDate = DateTime.tryParse(p.paymentDate);
              if (paymentDate != null) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final pDate = DateTime(
                  paymentDate.year,
                  paymentDate.month,
                  paymentDate.day,
                );

                if (_dateFilter == 'today') {
                  matchesDate = pDate.isAtSameMomentAs(today);
                } else if (_dateFilter == 'yesterday') {
                  matchesDate = pDate.isAtSameMomentAs(
                    today.subtract(const Duration(days: 1)),
                  );
                } else if (_dateFilter == 'dayBeforeYesterday') {
                  matchesDate = pDate.isAtSameMomentAs(
                    today.subtract(const Duration(days: 2)),
                  );
                } else if (_dateFilter == 'custom') {
                  if (_customStartDate != null && _customEndDate != null) {
                    final start = DateTime(
                      _customStartDate!.year,
                      _customStartDate!.month,
                      _customStartDate!.day,
                    );
                    final end = DateTime(
                      _customEndDate!.year,
                      _customEndDate!.month,
                      _customEndDate!.day,
                    );
                    matchesDate =
                        (pDate.isAtSameMomentAs(start) ||
                            pDate.isAfter(start)) &&
                        (pDate.isAtSameMomentAs(end) || pDate.isBefore(end));
                  }
                }
              }
            }

            return matchesSearch && matchesDate;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // 1. شريط الإحصائيات المالية
                _buildStatsRow(theme, stats, isDark),
                const SizedBox(height: 24),

                // 2. شريط البحث وإجراء الإضافة
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextFormField(
                            controller: _searchCtrl,
                            onChanged: (v) {
                              setState(() {
                                _searchQuery = v;
                              });
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'ابحث باسم المشترك، أو رقم العضوية، أو رقم الإيصال...',
                              prefixIcon: const Icon(Icons.search),
                              border: InputBorder.none,
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildDateFilterDropdown(),
                    if (_dateFilter == 'custom') ...[
                      const SizedBox(width: 8),
                      _buildCustomDatePickers(),
                    ],
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _showAddPaymentDialog,
                        icon: const Icon(Icons.add_card, color: Colors.white),
                        label: const Text('إضافة دفعة مالية'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalette.successColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. جدول سجل المدفوعات
                Expanded(
                  child: _buildPaymentsTable(
                    theme,
                    filteredList,
                    isLoading,
                    isDark,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateFilterDropdown() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _dateFilter,
            icon: const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.filter_alt_outlined, color: Colors.grey),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('كل التواريخ')),
              DropdownMenuItem(value: 'today', child: Text('اليوم')),
              DropdownMenuItem(value: 'yesterday', child: Text('أمس')),
              DropdownMenuItem(
                value: 'dayBeforeYesterday',
                child: Text('أول أمس'),
              ),
              DropdownMenuItem(value: 'custom', child: Text('مخصص')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _dateFilter = val;
                  if (val != 'custom') {
                    _customStartDate = null;
                    _customEndDate = null;
                  } else {
                    _customStartDate = DateTime.now();
                    _customEndDate = DateTime.now();
                  }
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDatePickers() {
    return Row(
      children: [
        _buildDatePickerBtn(
          label: _customStartDate == null
              ? 'من'
              : DateFormat('yyyy/MM/dd').format(_customStartDate!),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _customStartDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => _customStartDate = date);
            }
          },
        ),
        const SizedBox(width: 8),
        _buildDatePickerBtn(
          label: _customEndDate == null
              ? 'إلى'
              : DateFormat('yyyy/MM/dd').format(_customEndDate!),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _customEndDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => _customEndDate = date);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDatePickerBtn({
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // شريط كروت الإحصائيات
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsRow(
    ThemeData theme,
    Map<String, dynamic> stats,
    bool isDark,
  ) {
    final today = stats['todayRevenue'] as double? ?? 0.0;
    final month = stats['monthRevenue'] as double? ?? 0.0;
    final total = stats['totalRevenue'] as double? ?? 0.0;
    final debts = stats['totalDebts'] as double? ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            'إيراد اليوم',
            '${_formatCurrency(today)} ج.م',
            Icons.today,
            ColorPalette.successColor,
            isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            theme,
            'إيراد الشهر',
            '${_formatCurrency(month)} ج.م',
            Icons.calendar_month,
            ColorPalette.primaryColor,
            isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            theme,
            'إجمالي الإيرادات',
            '${_formatCurrency(total)} ج.م',
            Icons.account_balance,
            ColorPalette.infoColor,
            isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            theme,
            'المديونيات المتبقية',
            '${_formatCurrency(debts)} ج.م',
            Icons.money_off,
            ColorPalette.debtStatus,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? ColorPalette.cardDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? ColorPalette.textSecondaryDark
                          : ColorPalette.textSecondaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isDark
                          ? ColorPalette.textPrimaryDark
                          : ColorPalette.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // جدول سجل العمليات
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPaymentsTable(
    ThemeData theme,
    List<Payment> list,
    bool isLoading,
    bool isDark,
  ) {
    if (isLoading && list.isEmpty) {
      return const Card(child: Center(child: CircularProgressIndicator()));
    }

    if (list.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'لا توجد عمليات دفع مسجلة بعد',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'سجل المدفوعات والتحصيلات',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 48,
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      isDark
                          ? ColorPalette.tableHeaderDark
                          : ColorPalette.tableHeaderLight.withOpacity(0.05),
                    ),
                    columns: const [
                      //     DataColumn(label: Text('رقم الإيصال', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                        label: Text(
                          'اسم العميل',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'المبلغ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'طريقة الدفع',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'التاريخ والوقت',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'الموظف',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'الإجراءات',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: list.map((p) {
                      return DataRow(
                        cells: [
                          // DataCell(Text(p.receiptId, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                          DataCell(Text(p.memberName ?? 'عضو غير معروف')),
                          DataCell(
                            Text(
                              '${_formatCurrency(p.amount)} ج.م',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ColorPalette.primaryColor.withOpacity(
                                  0.08,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.paymentMethod,
                                style: const TextStyle(
                                  color: ColorPalette.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(_formatDate(p.paymentDate))),
                          DataCell(Text(p.employeeName)),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.print,
                                color: ColorPalette.infoColor,
                              ),
                              onPressed: () => _showReceiptDialog(p),
                              tooltip: 'عرض وطباعة الإيصال',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
