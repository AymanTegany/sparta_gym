import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/color_palette.dart';
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
    showDialog(
      context: context,
      builder: (_) => const AddPaymentDialog(),
    ).then((_) {
      context.read<PaymentsCubit>().loadPaymentsAndStats();
    });
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? ColorPalette.backgroundDark : ColorPalette.backgroundLight,
        appBar: AppBar(
          title: const Text(
            'إدارة المدفوعات والمالية',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<PaymentsCubit>().loadPaymentsAndStats(),
              tooltip: 'تحديث البيانات',
            ),
          ],
        ),
        body: BlocConsumer<PaymentsCubit, PaymentsState>(
          listener: (context, state) {
            if (state is PaymentsActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
                  backgroundColor: ColorPalette.successColor,
                ),
              );
              // إظهار إيصال الدفع تلقائياً للمعاينة والطباعة عند تسجيل الدفع بنجاح
              _showReceiptDialog(state.payment);
            } else if (state is PaymentsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
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
              return name.contains(query) || id.contains(query) || receipt.contains(query);
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                hintText: 'ابحث باسم المشترك، أو رقم العضوية، أو رقم الإيصال...',
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
                      const SizedBox(width: 16),
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
                    child: _buildPaymentsTable(theme, filteredList, isLoading, isDark),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // شريط كروت الإحصائيات
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsRow(ThemeData theme, Map<String, dynamic> stats, bool isDark) {
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
                      color: isDark ? ColorPalette.textSecondaryDark : ColorPalette.textSecondaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isDark ? ColorPalette.textPrimaryDark : ColorPalette.textPrimaryLight,
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
      return const Card(
        child: Center(child: CircularProgressIndicator()),
      );
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
                style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
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
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 950,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      isDark ? ColorPalette.tableHeaderDark : ColorPalette.tableHeaderLight.withOpacity(0.05),
                    ),
                    columns: const [
                      DataColumn(label: Text('رقم الإيصال', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('اسم العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('المبلغ', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('التاريخ والوقت', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الموظف', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: list.map((p) {
                      return DataRow(
                        cells: [
                          DataCell(Text(p.receiptId, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                          DataCell(Text(p.memberName ?? 'عضو غير معروف')),
                          DataCell(Text('${_formatCurrency(p.amount)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ColorPalette.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.paymentMethod,
                              style: const TextStyle(color: ColorPalette.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          )),
                          DataCell(Text(_formatDate(p.paymentDate))),
                          DataCell(Text(p.employeeName)),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.print, color: ColorPalette.infoColor),
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
