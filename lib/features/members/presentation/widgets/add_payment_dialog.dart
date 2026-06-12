import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/member_entity.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// ديالوج إضافة دفعة مالية
/// ──────────────────────────────────────────────────────────────────────────────
/// يتيح إضافة دفعة جزئية أو كاملة لحساب العميل مع التحقق من صحة المبلغ.
class AddPaymentDialog extends StatefulWidget {
  /// بيانات العميل
  final Member member;

  /// دالة تأكيد الدفع — تُستدعى بمبلغ الدفعة
  final Function(double amount) onPayment;

  const AddPaymentDialog({
    super.key,
    required this.member,
    required this.onPayment,
  });

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  // ──────────────── مفتاح النموذج ────────────────
  final _formKey = GlobalKey<FormState>();

  // ──────────────── متحكم حقل المبلغ ────────────────
  late final TextEditingController _amountCtrl;

  // ──────────────── المبلغ المتبقي الجديد بعد الدفعة ────────────────
  double _newRemaining = 0;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _newRemaining = widget.member.remainingAmount;

    _amountCtrl.addListener(_calculateNewRemaining);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  /// حساب المتبقي الجديد بعد الدفعة
  void _calculateNewRemaining() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    setState(() {
      _newRemaining = widget.member.remainingAmount - amount;
      if (_newRemaining < 0) _newRemaining = 0;
    });
  }

  /// تنسيق المبلغ المالي
  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'ar').format(amount);
  }

  /// تأكيد الدفع
  void _confirmPayment() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    widget.onPayment(amount);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = widget.member;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ──────────── العنوان ────────────
              _buildHeader(),

              // ──────────── المحتوى ────────────
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم العميل
                      Center(
                        child: Text(
                          member.fullName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // بطاقة الملخص المالي
                      _buildFinancialSummary(theme, member),
                      const SizedBox(height: 24),

                      // حقل مبلغ الدفعة
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'مبلغ الدفعة',
                          hintText: 'أدخل المبلغ',
                          prefixIcon: const Icon(Icons.payments, size: 22),
                          suffixText: 'ج.م',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: ColorPalette.primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'المبلغ مطلوب';
                          }
                          final amount = double.tryParse(v);
                          if (amount == null || amount <= 0) {
                            return 'المبلغ يجب أن يكون أكبر من صفر';
                          }
                          if (amount > member.remainingAmount) {
                            return 'المبلغ أكبر من المتبقي (${_formatCurrency(member.remainingAmount)} ج.م)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // المتبقي بعد الدفعة
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _newRemaining > 0
                              ? ColorPalette.warningColor
                                  .withValues(alpha: 0.08)
                              : ColorPalette.successColor
                                  .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _newRemaining > 0
                                ? ColorPalette.warningColor
                                    .withValues(alpha: 0.3)
                                : ColorPalette.successColor
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _newRemaining > 0
                                      ? Icons.account_balance_wallet_outlined
                                      : Icons.check_circle_outline,
                                  size: 20,
                                  color: _newRemaining > 0
                                      ? ColorPalette.warningColor
                                      : ColorPalette.successColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'المتبقي بعد الدفعة:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_formatCurrency(_newRemaining)} ج.م',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _newRemaining > 0
                                    ? ColorPalette.warningColor
                                    : ColorPalette.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ──────────── الأزرار ────────────
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // العنوان
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: ColorPalette.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_card, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Text(
            'إضافة دفعة مالية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // بطاقة الملخص المالي
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFinancialSummary(ThemeData theme, Member member) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // العنوان
            Row(
              children: [
                const Icon(Icons.receipt_long,
                    size: 18, color: ColorPalette.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'الملخص المالي',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // سعر الاشتراك
            _summaryRow(
              'سعر الاشتراك',
              '${_formatCurrency(member.membershipPrice)} ج.م',
              theme,
            ),
            const SizedBox(height: 8),

            // الخصم
            _summaryRow(
              'الخصم',
              '${_formatCurrency(member.discount)} ج.م',
              theme,
              valueColor: ColorPalette.infoColor,
            ),
            const SizedBox(height: 8),

            // المدفوع حتى الآن
            _summaryRow(
              'المدفوع حتى الآن',
              '${_formatCurrency(member.paidAmount)} ج.م',
              theme,
              valueColor: ColorPalette.successColor,
            ),

            Divider(
              height: 20,
              color: theme.dividerColor,
            ),

            // المبلغ المتبقي
            _summaryRow(
              'المبلغ المتبقي',
              '${_formatCurrency(member.remainingAmount)} ج.م',
              theme,
              valueColor: member.remainingAmount > 0
                  ? ColorPalette.debtStatus
                  : ColorPalette.successColor,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  /// صف ملخص مالي واحد
  Widget _summaryRow(
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الأزرار السفلية
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('إلغاء'),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _confirmPayment,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('تأكيد الدفع'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.successColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}
