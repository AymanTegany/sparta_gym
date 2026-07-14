import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../members/presentation/pages/members_page.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../payments/presentation/pages/payments_page.dart';
import '../../../../core/theme/color_palette.dart';

// Dashboard / Home Feature Imports
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../../../../core/common/widgets/sidebar_layout.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:updat/updat.dart';
import '../../../../core/services/github_update_service.dart';
import '../../../../core/common/widgets/arabic_update_builders.dart';

// Dialogs for Quick Actions
import '../../../members/presentation/widgets/add_member_dialog.dart';
import '../../../members/presentation/widgets/renew_subscription_dialog.dart';
import '../../../members/presentation/widgets/member_details_dialog.dart';
import '../../../payments/presentation/widgets/add_payment_dialog.dart';
import '../../../payments/presentation/widgets/receipt_dialog.dart';
import '../../../members/presentation/cubit/members_cubit.dart';
import '../../../members/presentation/cubit/members_state.dart';
import '../../../members/domain/entities/member_entity.dart';
import '../../../payments/domain/entities/payment_entity.dart';
import '../../../payments/presentation/cubit/payments_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../shifts/presentation/cubit/shifts_cubit.dart';
import '../../../shifts/presentation/cubit/shifts_state.dart';
import '../../../members/presentation/widgets/print_member_invoice.dart';

// UI Widgets
import '../widgets/quick_actions_section.dart';
import '../widgets/stat_card.dart';
import '../widgets/expiring_soon_section.dart';
import '../widgets/latest_payments_section.dart';
import '../widgets/attendance_stats_card.dart';
import '../widgets/revenue_chart_widget.dart';
import '../widgets/alerts_section.dart';

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
  final ScrollController _scrollController = ScrollController();
  static bool _hasCheckedForUpdates = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardCubit>().loadDashboard();
      if (!_hasCheckedForUpdates) {
        _hasCheckedForUpdates = true;
        _checkForUpdateAndShowDialog();
      }
    });
  }

  Future<void> _checkForUpdateAndShowDialog() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final updateService = GithubUpdateService(owner: 'AymanTegany', repo: 'sparta-gym-releases');
      final latestVersion = await updateService.getLatestVersion();
      
      if (latestVersion.isNotEmpty && latestVersion != currentVersion && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.system_update, color: ColorPalette.primaryColor),
                SizedBox(width: 10),
                Text('تحديث جديد متوفر!'),
              ],
            ),
            content: Text(
              'يتوفر الآن الإصدار $latestVersion من النظام.\nأنت تستخدم حالياً الإصدار $currentVersion.\n\nاضغط على الزر بالأسفل للبدء في التحديث للحصول على أحدث الميزات.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ذكرني لاحقاً', style: TextStyle(color: Colors.grey)),
              ),
              UpdatWidget(
                currentVersion: currentVersion,
                getLatestVersion: () async => latestVersion,
                getBinaryUrl: (v) async => await updateService.getBinaryUrl(v),
                appName: 'Sparta Gym',
                updateChipBuilder: buildArabicUpdateChip,
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking update: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ──────────────── دوال فتح الديالوجات الفرعية ────────────────
  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddMemberDialog(
        onSave: (newMember, paymentMethod, {bool printInvoice = false, bool shareWhatsapp = false}) async {
          // الحصول على اسم الموظف الحالي
          String employeeName = 'موظف';
          final shiftsState = context.read<ShiftsCubit>().state;
          if (shiftsState is ShiftsActiveShift) {
            employeeName = shiftsState.shift.employeeName;
          } else {
            final authState = context.read<AuthCubit>().state;
            if (authState is AuthAuthenticated) {
              employeeName = authState.user.fullName.isNotEmpty
                  ? authState.user.fullName
                  : authState.user.username;
            }
          }

          // 1. حفظ العضو بمدفوع = 0 ومتبقي = الصافي كامل
          final memberToSave = newMember.copyWith(
            paidAmount: 0,
            remainingAmount: newMember.netPrice,
          );

          final success = await context.read<MembersCubit>().addMember(
                memberToSave,
                refreshList: newMember.paidAmount == 0,
              );

          // 2. إذا نجح الحفظ وكان هناك مبلغ مدفوع، سجل الدفعة
          Payment? generatedPayment;
          if (success && newMember.paidAmount > 0) {
            final shiftId = context.read<ShiftsCubit>().currentShiftId;
            generatedPayment = await context.read<PaymentsCubit>().recordPayment(
              memberId: newMember.memberId,
              amount: newMember.paidAmount,
              paymentMethod: paymentMethod,
              employeeName: employeeName,
              shiftId: shiftId,
              notes: 'دفعة أولى عند الاشتراك',
            );
            if (context.mounted) {
              await context.read<MembersCubit>().loadMembers();
            }
          }

          if (shareWhatsapp && context.mounted) {
            // إنشاء كائن Payment للمعاينة حتى لو لم يكن هناك مدفوعات
            final paymentToShare = generatedPayment ?? Payment(
              receiptId: 'REC-${DateTime.now().millisecondsSinceEpoch}',
              memberId: newMember.memberId,
              memberName: newMember.fullName,
              memberPhone: newMember.phoneNumber,
              amount: newMember.paidAmount,
              paymentMethod: paymentMethod,
              paymentDate: DateTime.now().toIso8601String(),
              employeeName: employeeName,
              notes: 'اشتراك باقة ${newMember.membershipType}',
            );
            // لضمان وجود البيانات في المعاينة (الاسم ورقم الهاتف)
            final previewPayment = Payment(
              id: paymentToShare.id,
              receiptId: paymentToShare.receiptId,
              memberId: paymentToShare.memberId,
              memberName: paymentToShare.memberName ?? newMember.fullName,
              memberPhone: paymentToShare.memberPhone ?? newMember.phoneNumber,
              amount: paymentToShare.amount,
              paymentMethod: paymentToShare.paymentMethod,
              paymentDate: paymentToShare.paymentDate,
              employeeName: paymentToShare.employeeName,
              notes: paymentToShare.notes,
            );
            showDialog(
              context: context,
              builder: (_) => ReceiptDialog(payment: previewPayment),
            );
          }
          
          if (printInvoice && context.mounted) {
            await printMemberA4Invoice(context, newMember);
          }
        },
      ),
    ).then((_) => context.read<DashboardCubit>().loadDashboard());
  }

  void _showAddPaymentDialog(BuildContext context, [Member? member]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddPaymentDialog(member: member),
    ).then((_) => context.read<DashboardCubit>().loadDashboard());
  }

  void _showRenewDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RenewSubscriptionDialog(
        member: member,
        onRenew:
            ({
              required membershipType,
              required price,
              required discount,
              required paidAmount,
              required startDate,
              required endDate,
              required paymentMethod,
            }) async {
              // الحصول على اسم الموظف الحالي
              String employeeName = 'موظف';
              final shiftsState = context.read<ShiftsCubit>().state;
              if (shiftsState is ShiftsActiveShift) {
                employeeName = shiftsState.shift.employeeName;
              } else {
                final authState = context.read<AuthCubit>().state;
                if (authState is AuthAuthenticated) {
                  employeeName = authState.user.fullName.isNotEmpty
                      ? authState.user.fullName
                      : authState.user.username;
                }
              }

              // 1. تجديد الاشتراك بوضع مبلغ مدفوع = 0، ومتبقي = الصافي الجديد
              final success = await context
                  .read<MembersCubit>()
                  .renewSubscription(
                    member: member,
                    newMembershipType: membershipType,
                    newPrice: price,
                    newDiscount: discount,
                    newPaidAmount: 0,
                    newStartDate: startDate,
                    newEndDate: endDate,
                    refreshList: paidAmount == 0,
                  );

              // 2. إذا تم التجديد بنجاح وكان هناك مبلغ مدفوع، سجل الدفعة
              if (success && paidAmount > 0) {
                final shiftId = context.read<ShiftsCubit>().currentShiftId;
                await context.read<PaymentsCubit>().recordPayment(
                  memberId: member.memberId,
                  amount: paidAmount,
                  paymentMethod: paymentMethod,
                  employeeName: employeeName,
                  shiftId: shiftId,
                  notes: 'تجديد اشتراك: $membershipType',
                );
                if (context.mounted) {
                  await context.read<MembersCubit>().loadMembers();
                }
              }
            },
      ),
    ).then((_) => context.read<DashboardCubit>().loadDashboard());
  }

  void _showEditMemberDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddMemberDialog(
        member: member,
        onSave: (updatedMember, paymentMethod, {bool printInvoice = false, bool shareWhatsapp = false}) {
          context.read<MembersCubit>().updateMember(updatedMember);
        },
      ),
    ).then((_) => context.read<DashboardCubit>().loadDashboard());
  }

  void _showDeleteConfirmDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                'حذف العميل',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في حذف العميل "${member.fullName}"؟\nلا يمكن التراجع عن هذا الإجراء وسيتم حذف جميع سجلاته نهائياً.',
            style: const TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<MembersCubit>().deleteMember(member.id!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف نهائي'),
            ),
          ],
        );
      },
    ).then((_) => context.read<DashboardCubit>().loadDashboard());
  }

  void _showDetailsDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (dialogContext) => MemberDetailsDialog(
        member: member,
        onEdit: () {
          _showEditMemberDialog(context, member);
        },
        onDelete: () {
          _showDeleteConfirmDialog(context, member);
        },
        onRenew: () {
          _showRenewDialog(context, member);
        },
        onAddPayment: () {
          _showAddPaymentDialog(context, member);
        },
      ),
    ).then((_) => context.read<DashboardCubit>().loadDashboard());
  }

  void _showInquireAndRenewSearchDialog(BuildContext context) {
    context.read<MembersCubit>().loadMembers();
    showDialog(
      context: context,
      builder: (dialogContext) {
        Member? selectedMember;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'استعلام وتجديد اشتراك - اختر العضو',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ابحث عن اسم العضو، كوده أو رقم هاتفه لعرض بياناته:'),
                  const SizedBox(height: 16),
                  RawAutocomplete<Member>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Member>.empty();
                      }
                      final membersState = context.read<MembersCubit>().state;
                      if (membersState is MembersLoaded) {
                        return membersState.allMembers.where((Member option) {
                          return option.fullName.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ) ||
                              (option.phoneNumber?.contains(
                                    textEditingValue.text,
                                  ) ??
                                  false) ||
                              option.memberId.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              );
                        });
                      }
                      return const Iterable<Member>.empty();
                    },
                    displayStringForOption: (Member option) => option.fullName,
                    fieldViewBuilder:
                        (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'اكتب اسم العضو، الكود أو رقم الهاتف...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                            constraints: const BoxConstraints(
                              maxHeight: 200,
                              maxWidth: 450,
                            ),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (c, i) =>
                                  const Divider(height: 1),
                              itemBuilder: (BuildContext context, int index) {
                                final Member option = options.elementAt(index);
                                return ListTile(
                                  title: Text(
                                    option.fullName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'الكود: ${option.memberId} | الهاتف: ${option.phoneNumber ?? "لا يوجد"} | نوع الباقة: ${option.membershipType}',
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
                    _showDetailsDialog(context, selectedMember!);
                  }
                },
                child: const Text('عرض البروفايل'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SidebarLayout(
      activePage: 'home',
      title: 'لوحة التحكم الرئيسية',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<DashboardCubit>().loadDashboard(),
          tooltip: 'تحديث البيانات',
        ),
      ],
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
                  const Icon(
                    Icons.error_outline_rounded,
                    color: ColorPalette.errorColor,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ أثناء تحميل لوحة التحكم:',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<DashboardCubit>().loadDashboard(),
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
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false, // We use a custom Scrollbar below
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // القسم 1: أزرار الإجراءات السريعة
                      QuickActionsSection(
                        isDarkMode: widget.isDarkMode,
                        onAddMember: () => _showAddMemberDialog(context),
                        onAddPayment: () => _showAddPaymentDialog(context),
                        onInquireAndRenew: () => _showInquireAndRenewSearchDialog(context),
                        onAttendance: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AttendancePage()),
                          ).then((_) => context.read<DashboardCubit>().loadDashboard());
                        },
                      ),

                      // القسم 2: صف الكروت الأربعة
                      GridView.count(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          StatCard(
                            title: 'إجمالي الأعضاء',
                            value: '${stats.totalMembers}',
                            icon: Icons.group_rounded,
                            color: ColorPalette.primaryColor,
                            textColor:
                                theme.textTheme.bodyLarge?.color ??
                                Colors.black,
                          ),
                          StatCard(
                            title: 'الأعضاء النشطون',
                            value: '${stats.activeMembers}',
                            icon: Icons.check_circle_rounded,
                            color: ColorPalette.successColor,
                            textColor:
                                theme.textTheme.bodyLarge?.color ??
                                Colors.black,
                          ),
                          StatCard(
                            title: '⚠️الاشتراكات المنتهية',
                            value: '${stats.expiredMembers}',
                            icon: Icons.error_rounded,
                            color: ColorPalette.errorColor,
                            textColor:
                                theme.textTheme.bodyLarge?.color ??
                                Colors.black,
                          ),
                          StatCard(
                            title: 'إيراد الشهر',
                            value:
                                '${NumberFormat('#,##0', 'ar').format(stats.monthlyRevenue)} ج',
                            icon: Icons.monetization_on_rounded,
                            color: ColorPalette.warningColor,
                            textColor:
                                theme.textTheme.bodyLarge?.color ??
                                Colors.black,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // القسم 3: جداول المتابعة (تنتهي قريباً + آخر المدفوعات)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ExpiringSoonSection(
                              members: stats.expiringSoonMembers,
                              onShowAll: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MembersPage()),
                                ).then((_) => context.read<DashboardCubit>().loadDashboard());
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: LatestPaymentsSection(
                              payments: stats.latestPayments,
                              onShowAll: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PaymentsPage()),
                                ).then((_) => context.read<DashboardCubit>().loadDashboard());
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // القسم 4: حضور اليوم والرسم البياني
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: AttendanceStatsCard(
                              totalToday: stats.todayAttendance,
                              currentInside: stats.currentlyInside,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: RevenueChartWidget(
                              chartData: stats.revenueChartData,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // القسم 5: التنبيهات المهمة
                      AlertsSection(
                        expiredAlerts: stats.expiredAlertsCount,
                        expiringThreeDays: stats.expiringThreeDaysCount,
                      ),
                      const SizedBox(height: 32),

                      // Footer Branding
                      Center(
                        child: Opacity(
                          opacity: 0.5,
                          child: Text(
                            'Powered by Ayman Tegany\n01030731218',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
          }

          return const Center(child: Text('جاري تحميل البيانات...'));
        },
      ),
    );
  }
}
