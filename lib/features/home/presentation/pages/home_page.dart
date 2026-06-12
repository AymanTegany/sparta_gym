import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../members/presentation/pages/members_page.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../payments/presentation/pages/payments_page.dart';
import '../../../../core/theme/color_palette.dart';

// Dashboard / Home Feature Imports
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

// Dialogs for Quick Actions
import '../../../members/presentation/widgets/add_member_dialog.dart';
import '../../../members/presentation/widgets/renew_subscription_dialog.dart';
import '../../../payments/presentation/widgets/add_payment_dialog.dart';
import '../../../members/presentation/cubit/members_cubit.dart';
import '../../../members/presentation/cubit/members_state.dart';
import '../../../members/domain/entities/member_entity.dart';
import '../../../payments/domain/entities/payment_entity.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// الشاشة الرئيسية للنظام (Dashboard / HomePage)
/// ──────────────────────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardCubit>().loadDashboard();
    });
  }

  // ──────────────── أزرار الإجراءات السريعة ────────────────
  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildQuickActionBtn(
            icon: Icons.person_add_alt_1_rounded,
            label: 'عضو جديد',
            color: ColorPalette.primaryColor,
            onPressed: () => _showAddMemberDialog(context),
          ),
          const SizedBox(width: 12),
          _buildQuickActionBtn(
            icon: Icons.add_card_rounded,
            label: 'إضافة دفعة',
            color: ColorPalette.successColor,
            onPressed: () => _showAddPaymentDialog(context),
          ),
          const SizedBox(width: 12),
          _buildQuickActionBtn(
            icon: Icons.autorenew_rounded,
            label: 'تجديد اشتراك',
            color: ColorPalette.infoColor,
            onPressed: () => _showRenewSearchDialog(context),
          ),
          const SizedBox(width: 12),
          _buildQuickActionBtn(
            icon: Icons.check_circle_rounded,
            label: 'تسجيل حضور',
            color: widget.isDarkMode ? ColorPalette.secondaryColorDarkMode : ColorPalette.secondaryColor,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendancePage()),
              ).then((_) => context.read<DashboardCubit>().loadDashboard());
            },
          ),
        ],
      ),
    );
  }

  // ──────────────── كروت الإحصائيات الأربعة ────────────────
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────── شاشات المتابعة التنبيهية والجداول ────────────────
  Widget _buildExpiringSoonSection(List<Member> members) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اشتراكات تنتهي قريباً',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MembersPage()),
                    ).then((_) => context.read<DashboardCubit>().loadDashboard());
                  },
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (members.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('لا توجد اشتراكات تنتهي قريباً', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                },
                children: [
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('الاسم', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('باقي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                    ],
                  ),
                  ...members.map((m) {
                    final days = m.remainingDays;
                    final textDays = days == 1 ? 'يوم واحد' : '$days أيام';
                    final color = days <= 3 ? ColorPalette.errorColor : ColorPalette.warningColor;
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              textDays,
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestPaymentsSection(List<Payment> payments) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'آخر المدفوعات',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentsPage()),
                    ).then((_) => context.read<DashboardCubit>().loadDashboard());
                  },
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (payments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('لا توجد مدفوعات مسجلة بعد', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                },
                children: [
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('المبلغ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                    ],
                  ),
                  ...payments.map((p) {
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(p.memberName ?? p.memberId, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${p.amount.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(
                              color: ColorPalette.successColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────── حضور اليوم والرسم البياني ────────────────
  Widget _buildAttendanceStatsCard({required int totalToday, required int currentInside}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'حضور اليوم',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.people_outline, color: ColorPalette.primaryColor),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$totalToday',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'إجمالي حضور اليوم',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 60, color: theme.dividerColor),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$currentInside',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.successColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'الموجودون الآن بالجيم',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // الرسم البياني المصمم خصيصاً بـ Flutter Widgets
  Widget _buildRevenueChartWidget(Map<String, double> chartData) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    double maxVal = 0.0;
    chartData.forEach((key, val) {
      if (val > maxVal) maxVal = val;
    });

    if (maxVal == 0.0) maxVal = 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      height: 220,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إيرادات آخر 7 أيام',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.bar_chart_rounded, color: ColorPalette.primaryColor),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chartData.entries.map((entry) {
                final dateStr = entry.key;
                final amount = entry.value;
                final heightFactor = amount / maxVal;

                String displayDate = dateStr;
                try {
                  final parsed = DateTime.parse(dateStr);
                  displayDate = DateFormat('MM/dd').format(parsed);
                } catch (_) {}

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (amount > 0)
                        Text(
                          '${amount.toStringAsFixed(0)} ج',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        )
                      else
                        const Text(
                          '—',
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        height: heightFactor * 100 + 4.0,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primary,
                              primary.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayDate,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────── قسم التنبيهات ────────────────
  Widget _buildAlertsSection({required int expiredAlerts, required int expiringThreeDays}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined, color: ColorPalette.errorColor),
                const SizedBox(width: 8),
                Text(
                  'التنبيهات المهمة',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (expiredAlerts == 0 && expiringThreeDays == 0)
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: ColorPalette.successColor),
                  SizedBox(width: 10),
                  Text('لا توجد تنبيهات عاجلة اليوم، كل شيء مستقر.', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              )
            else
              Column(
                children: [
                  if (expiredAlerts > 0)
                    ListTile(
                      leading: const Icon(Icons.error_outline_rounded, color: ColorPalette.errorColor),
                      title: Text(
                        'يوجد $expiredAlerts اشتراكات منتهية تحتاج إلى تجديد.',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      dense: true,
                    ),
                  if (expiringThreeDays > 0)
                    ListTile(
                      leading: const Icon(Icons.warning_amber_rounded, color: ColorPalette.warningColor),
                      title: Text(
                        'يوجد $expiringThreeDays اشتراكات تنتهي خلال الـ 3 أيام القادمة.',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      dense: true,
                    ),
                  const ListTile(
                    leading: Icon(Icons.inventory_2_outlined, color: Colors.grey),
                    title: Text(
                      'المخزون: لا توجد منتجات أوشكت على النفاد.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    dense: true,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────── دوال فتح الديالوجات الفرعية ────────────────
  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddMemberDialog(
        onSave: (newMember) {
          context.read<MembersCubit>().addMember(newMember);
        },
      ),
    ).then((_) => context.read<DashboardCubit>().loadDashboard());
  }

  void _showAddPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AddPaymentDialog(),
    ).then((_) => context.read<DashboardCubit>().loadDashboard());
  }

  void _showRenewDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RenewSubscriptionDialog(
        member: member,
        onRenew: ({
          required membershipType,
          required price,
          required discount,
          required paidAmount,
          required startDate,
          required endDate,
        }) {
          context.read<MembersCubit>().renewSubscription(
                member: member,
                newMembershipType: membershipType,
                newPrice: price,
                newDiscount: discount,
                newPaidAmount: paidAmount,
                newStartDate: startDate,
                newEndDate: endDate,
              );
        },
      ),
    ).then((_) => context.read<DashboardCubit>().loadDashboard());
  }

  void _showRenewSearchDialog(BuildContext context) {
    context.read<MembersCubit>().loadMembers();
    showDialog(
      context: context,
      builder: (dialogContext) {
        Member? selectedMember;
        return AlertDialog(
          title: const Text('تجديد اشتراك - اختر العضو', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ابحث عن اسم العضو أو رقم هاتفه لتجديد اشتراكه:'),
                const SizedBox(height: 16),
                RawAutocomplete<Member>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<Member>.empty();
                    }
                    final membersState = context.read<MembersCubit>().state;
                    if (membersState is MembersLoaded) {
                      return membersState.allMembers.where((Member option) {
                        return option.fullName.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                            (option.phoneNumber?.contains(textEditingValue.text) ?? false);
                      });
                    }
                    return const Iterable<Member>.empty();
                  },
                  displayStringForOption: (Member option) => option.fullName,
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'اكتب اسم العضو أو رقم الهاتف...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topRight,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(10),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 450),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            separatorBuilder: (c, i) => const Divider(height: 1),
                            itemBuilder: (BuildContext context, int index) {
                              final Member option = options.elementAt(index);
                              return ListTile(
                                title: Text(option.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'نوع الباقة: ${option.membershipType} | تاريخ الانتهاء: ${option.endDate.substring(0, 10)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  onSelected: (Member selection) {
                    selectedMember = selection;
                  },
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
                if (selectedMember != null) {
                  Navigator.pop(dialogContext);
                  _showRenewDialog(context, selectedMember!);
                }
              },
              child: const Text('موافق'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.fitness_center_rounded, color: primary, size: 28),
              const SizedBox(width: 10),
              const Text(
                'نظام Sparta Gym',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            // زر تحديث البيانات اليدوي
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => context.read<DashboardCubit>().loadDashboard(),
              tooltip: 'تحديث البيانات',
            ),
            // زر تبديل الثيم
            IconButton(
              icon: Icon(widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              onPressed: widget.onThemeToggle,
              tooltip: widget.isDarkMode ? 'تفعيل الوضع النهاري' : 'تفعيل الوضع الليلي',
            ),
            // زر الإعدادات
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ).then((_) => context.read<DashboardCubit>().loadDashboard());
              },
              tooltip: 'إعدادات النظام',
            ),
            // زر تسجيل الخروج
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج من النظام؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<AuthCubit>().logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('خروج'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DashboardError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: ColorPalette.errorColor, size: 60),
                    const SizedBox(height: 16),
                    Text('حدث خطأ أثناء تحميل لوحة التحكم:', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(state.message, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.read<DashboardCubit>().loadDashboard(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            if (state is DashboardLoaded) {
              final stats = state.stats;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // القسم 1: أزرار الإجراءات السريعة
                        _buildQuickActionsSection(context),

                        // القسم 2: صف الكروت الأربعة
                        GridView.count(
                          crossAxisCount: 4,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStatCard(
                              title: '👥 إجمالي الأعضاء',
                              value: '${stats.totalMembers}',
                              icon: Icons.group_rounded,
                              color: ColorPalette.primaryColor,
                              textColor: theme.textTheme.bodyLarge?.color ?? Colors.black,
                            ),
                            _buildStatCard(
                              title: '✅ الأعضاء النشطون',
                              value: '${stats.activeMembers}',
                              icon: Icons.check_circle_rounded,
                              color: ColorPalette.successColor,
                              textColor: theme.textTheme.bodyLarge?.color ?? Colors.black,
                            ),
                            _buildStatCard(
                              title: '⚠️ الاشتراكات المنتهية',
                              value: '${stats.expiredMembers}',
                              icon: Icons.error_rounded,
                              color: ColorPalette.errorColor,
                              textColor: theme.textTheme.bodyLarge?.color ?? Colors.black,
                            ),
                            _buildStatCard(
                              title: '💰 إيراد الشهر',
                              value: '${NumberFormat('#,##0', 'ar').format(stats.monthlyRevenue)} ج',
                              icon: Icons.monetization_on_rounded,
                              color: ColorPalette.warningColor,
                              textColor: theme.textTheme.bodyLarge?.color ?? Colors.black,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // القسم 3: جداول المتابعة (تنتهي قريباً + آخر المدفوعات)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildExpiringSoonSection(stats.expiringSoonMembers)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildLatestPaymentsSection(stats.latestPayments)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // القسم 4: حضور اليوم والرسم البياني
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildAttendanceStatsCard(
                                totalToday: stats.todayAttendance,
                                currentInside: stats.currentlyInside,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: _buildRevenueChartWidget(stats.revenueChartData),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // القسم 5: التنبيهات المهمة
                        _buildAlertsSection(
                          expiredAlerts: stats.expiredAlertsCount,
                          expiringThreeDays: stats.expiringThreeDaysCount,
                        ),
                        const SizedBox(height: 32),

                        // Footer Branding
                        Center(
                          child: Opacity(
                            opacity: 0.5,
                            child: Text(
                              'تم التطوير بواسطة Antigravity AI لمصلحة Sparta Gym',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return const Center(child: Text('جاري تحميل البيانات...'));
          },
        ),
      ),
    );
  }
}
