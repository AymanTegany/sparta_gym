import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/member_entity.dart';
import '../../../payments/presentation/cubit/payments_cubit.dart';
import '../../../payments/presentation/cubit/payments_state.dart';
import '../../../payments/presentation/widgets/receipt_dialog.dart';
import '../../../payments/domain/entities/payment_entity.dart';
import '../../../diets/domain/entities/diet_plan.dart';
import '../../../diets/presentation/cubit/diet_plans_cubit.dart';
import '../../../diets/presentation/cubit/diet_plans_state.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// ديالوج تفاصيل العميل
/// ──────────────────────────────────────────────────────────────────────────────
/// يعرض جميع بيانات العميل بشكل منظم مع أزرار الإجراءات المتاحة.
class MemberDetailsDialog extends StatelessWidget {
  /// بيانات العميل المراد عرضها
  final Member member;

  /// دالة تعديل بيانات العميل
  final VoidCallback? onEdit;

  /// دالة حذف العميل
  final VoidCallback? onDelete;

  /// دالة تجديد الاشتراك
  final VoidCallback? onRenew;

  /// دالة إضافة دفعة مالية
  final VoidCallback? onAddPayment;

  const MemberDetailsDialog({
    super.key,
    required this.member,
    this.onEdit,
    this.onDelete,
    this.onRenew,
    this.onAddPayment,
  });

  /// تنسيق التاريخ للعرض
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('yyyy/MM/dd').format(date);
  }

  /// تنسيق المبلغ المالي
  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'ar').format(amount);
  }

  /// الحصول على لون حالة الاشتراك
  Color _getStatusColor() {
    if (!member.isActive) return ColorPalette.expiredStatus;
    if (member.isExpiringSoon) return ColorPalette.expiringSoonStatus;
    return ColorPalette.activeStatus;
  }

  /// الحصول على أيقونة حالة الاشتراك
  IconData _getStatusIcon() {
    if (!member.isActive) return Icons.cancel;
    if (member.isExpiringSoon) return Icons.warning_amber_rounded;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dietPlansState = context.watch<DietPlansCubit>().state;
    DietPlan? memberDietPlan;
    if (dietPlansState is DietPlansLoaded && member.dietPlanId != null) {
      for (final d in dietPlansState.dietPlans) {
        if (d.id == member.dietPlanId) {
          memberDietPlan = d;
          break;
        }
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 800,
          height: 600,
          child: Column(
            children: [
              // ──────────── رأس الديالوج مع بيانات العميل الأساسية ────────────
              _buildHeader(theme),

              // ──────────── المحتوى الرئيسي ────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPersonalInfoSection(theme),
                      const SizedBox(height: 20),
                      _buildSubscriptionSection(theme),
                      const SizedBox(height: 20),
                      if (member.dietPlanId != null) ...[
                        _buildDietPlanSection(theme, memberDietPlan),
                        const SizedBox(height: 20),
                      ],
                      _buildPaymentsSection(theme),
                      const SizedBox(height: 20),
                      _buildAttendanceSection(theme),
                      const SizedBox(height: 20),
                      _buildNotesSection(theme),
                    ],
                  ),
                ),
              ),

              // ──────────── أزرار الإجراءات ────────────
              _buildActionButtons(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // رأس الديالوج — صورة العميل + الاسم + الحالة
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(ThemeData theme) {
    final statusColor = _getStatusColor();
    final initials = member.fullName.isNotEmpty
        ? member.fullName.trim().split(' ').map((e) => e[0]).take(2).join()
        : '?';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: ColorPalette.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // دائرة الأحرف الأولى للاسم
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // الاسم ورقم العضوية
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'رقم العضوية: ${member.memberId}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // شارة الحالة
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getStatusIcon(), color: statusColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  member.statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // القسم 1: البيانات الشخصية
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPersonalInfoSection(ThemeData theme) {
    return _buildSection(
      theme: theme,
      title: 'البيانات الشخصية',
      icon: Icons.person_outline,
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _infoItem('الاسم الكامل', member.fullName, Icons.person),
          _infoItem(
              'رقم الهاتف', member.phoneNumber ?? '—', Icons.phone),
          _infoItem('الجنس', member.gender ?? '—', Icons.wc),
          _infoItem(
              'العنوان', member.address ?? '—', Icons.location_on_outlined),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // القسم 2: معلومات الاشتراك
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSubscriptionSection(ThemeData theme) {
    return _buildSection(
      theme: theme,
      title: 'معلومات الاشتراك',
      icon: Icons.card_membership,
      child: Column(
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _infoItem('نوع الاشتراك', member.membershipType,
                  Icons.card_membership),
              _infoItem(
                  'سعر الاشتراك',
                  '${_formatCurrency(member.membershipPrice)} ج.م',
                  Icons.attach_money),
              _infoItem('الخصم', '${_formatCurrency(member.discount)} ج.م',
                  Icons.discount_outlined),
              _infoItem('المدفوع', '${_formatCurrency(member.paidAmount)} ج.م',
                  Icons.payments_outlined),
              _infoItem(
                  'المتبقي',
                  '${_formatCurrency(member.remainingAmount)} ج.م',
                  Icons.account_balance_wallet_outlined),
              _infoItem('تاريخ البدء', _formatDate(member.startDate),
                  Icons.calendar_today),
              _infoItem('تاريخ الانتهاء', _formatDate(member.endDate),
                  Icons.event_outlined),
              _infoItem(
                  'اسم المدرب', member.trainerName ?? '—', Icons.fitness_center),
            ],
          ),
          const SizedBox(height: 12),

          // شريط الأيام المتبقية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _getStatusColor().withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined,
                    color: _getStatusColor(), size: 20),
                const SizedBox(width: 8),
                Text(
                  member.isActive
                      ? 'متبقي ${member.remainingDays} يوم'
                      : 'الاشتراك منتهي',
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // القسم 3: سجل المدفوعات
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPaymentsSection(ThemeData theme) {
    return _buildSection(
      theme: theme,
      title: 'سجل المدفوعات',
      icon: Icons.receipt_long,
      child: MemberPaymentsSection(memberId: member.memberId),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // القسم 4: سجل الحضور
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAttendanceSection(ThemeData theme) {
    return _buildSection(
      theme: theme,
      title: 'سجل الحضور',
      icon: Icons.fact_check_outlined,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'لا يوجد سجل حضور بعد',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // القسم 5: الملاحظات
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNotesSection(ThemeData theme) {
    return _buildSection(
      theme: theme,
      title: 'الملاحظات',
      icon: Icons.notes_outlined,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          member.notes?.isNotEmpty == true
              ? member.notes!
              : 'لا توجد ملاحظات',
          style: TextStyle(
            color: member.notes?.isNotEmpty == true
                ? theme.textTheme.bodyLarge?.color
                : theme.textTheme.bodySmall?.color,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // القسم: النظام الغذائي
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDietPlanSection(ThemeData theme, DietPlan? dietPlan) {
    return _buildSection(
      theme: theme,
      title: 'النظام الغذائي المخصص',
      icon: Icons.restaurant_menu,
      child: dietPlan == null || dietPlan.name.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'جاري تحميل تفاصيل النظام الغذائي...',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dietPlan.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (dietPlan.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    dietPlan.description!,
                    style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'الوجبات:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ColorPalette.secondaryColor),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  width: double.infinity,
                  child: Text(
                    dietPlan.meals,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
                if (dietPlan.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'ملاحظات النظام:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dietPlan.notes!,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // أزرار الإجراءات
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
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
        children: [
          // زر التعديل
          _actionButton(
            label: 'تعديل',
            icon: Icons.edit_outlined,
            color: ColorPalette.primaryColor,
            onPressed: () {
              Navigator.of(context).pop();
              onEdit?.call();
            },
          ),
          const SizedBox(width: 10),

          // زر تجديد الاشتراك
          _actionButton(
            label: 'تجديد اشتراك',
            icon: Icons.autorenew,
            color: ColorPalette.infoColor,
            onPressed: () {
              Navigator.of(context).pop();
              onRenew?.call();
            },
          ),
          const SizedBox(width: 10),

          // زر إضافة دفعة
          _actionButton(
            label: 'إضافة دفعة',
            icon: Icons.add_card,
            color: ColorPalette.successColor,
            onPressed: () {
              Navigator.of(context).pop();
              onAddPayment?.call();
            },
          ),

          const Spacer(),

          // زر الحذف
          _actionButton(
            label: 'حذف',
            icon: Icons.delete_outline,
            color: ColorPalette.errorColor,
            outlined: true,
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  مكونات مشتركة
  // ═══════════════════════════════════════════════════════════════════════════

  /// بطاقة قسم مع عنوان
  Widget _buildSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان القسم
            Row(
              children: [
                Icon(icon, size: 20, color: ColorPalette.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  /// عنصر معلومة واحد (أيقونة + عنوان + قيمة)
  Widget _infoItem(String label, String value, IconData icon) {
    return SizedBox(
      width: 340,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: ColorPalette.primaryLight),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// زر إجراء موحّد
  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 1,
      ),
    );
  }
}

class MemberPaymentsSection extends StatefulWidget {
  final String memberId;

  const MemberPaymentsSection({super.key, required this.memberId});

  @override
  State<MemberPaymentsSection> createState() => _MemberPaymentsSectionState();
}

class _MemberPaymentsSectionState extends State<MemberPaymentsSection> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentsCubit>().getMemberPayments(widget.memberId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<PaymentsCubit, PaymentsState>(
      builder: (context, state) {
        if (state is PaymentsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Payment> payments = [];
        if (state is PaymentsLoaded) {
          payments = state.memberPayments;
        }

        if (payments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'لا توجد مدفوعات مسجلة بعد',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          separatorBuilder: (c, i) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final p = payments[index];
            final date = DateTime.tryParse(p.paymentDate);
            final dateStr = date != null ? DateFormat('yyyy/MM/dd hh:mm a').format(date) : p.paymentDate;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${NumberFormat('#,##0', 'ar').format(p.amount)} ج.م - ${p.paymentMethod}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                'التاريخ: $dateStr | الموظف: ${p.employeeName}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.print, size: 18, color: ColorPalette.infoColor),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ReceiptDialog(payment: p),
                  );
                },
                tooltip: 'عرض وطباعة الإيصال',
              ),
            );
          },
        );
      },
    );
  }
}
