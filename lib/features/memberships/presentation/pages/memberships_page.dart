import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/common/widgets/sidebar_layout.dart';

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/membership_entity.dart';
import '../cubit/memberships_cubit.dart';
import '../cubit/memberships_state.dart';
import '../widgets/add_membership_dialog.dart';
import '../../../discount_codes/presentation/widgets/discount_codes_list.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// شاشة باقات الاشتراكات (Memberships Page)
/// ──────────────────────────────────────────────────────────────────────────────
class MembershipsPage extends StatefulWidget {
  const MembershipsPage({super.key});

  @override
  State<MembershipsPage> createState() => _MembershipsPageState();
}

class _MembershipsPageState extends State<MembershipsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MembershipsCubit>().loadMemberships();
    });
  }

  void _showAddMembershipDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddMembershipDialog(
        onSave: (newMembership) {
          context.read<MembershipsCubit>().addMembership(newMembership);
        },
      ),
    );
  }

  void _showEditMembershipDialog(BuildContext context, Membership membership) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddMembershipDialog(
        membership: membership,
        onSave: (updatedMembership) {
          context.read<MembershipsCubit>().updateMembership(updatedMembership);
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Membership membership) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('حذف الباقة', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في حذف باقة "${membership.name}"؟\nتنبيه: لن يتم إلغاء اشتراكات الأعضاء المشتركين بها حالياً، ولكن لن تتمكن من ربط أعضاء جدد بهذه الباقة.',
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
                context.read<MembershipsCubit>().deleteMembership(membership.id!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف الباقة'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'ar').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: SidebarLayout(
        activePage: 'memberships',
        title: 'باقات واشتراكات الجيم',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث البيانات',
            onPressed: () {
               context.read<MembershipsCubit>().loadMemberships();
            },
          ),
        ],
        body: Column(
          children: [
            Container(
              color: theme.cardColor,
              child: const TabBar(
                tabs: [
                  Tab(text: 'الباقات (Memberships)', icon: Icon(Icons.card_membership)),
                  Tab(text: 'أكواد الخصم (Discount Codes)', icon: Icon(Icons.discount)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildMembershipsTab(context, primary, theme),
                  const DiscountCodesList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipsTab(BuildContext context, Color primary, ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddMembershipDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة باقة جديدة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocConsumer<MembershipsCubit, MembershipsState>(
          listener: (context, state) {
            if (state is MembershipActionSuccess) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: ColorPalette.activeStatus,
                  ),
                );
            }
            if (state is MembershipsError) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.redAccent,
                  ),
                );
            }
          },
          builder: (context, state) {
            if (state is MembershipsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MembershipsLoaded) {
              final memberships = state.memberships;

              if (memberships.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.card_membership_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('لا توجد باقات اشتراكات معرفة حالياً'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAddMembershipDialog(context),
                        child: const Text('إضافة باقة أولى'),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
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
                            theme.brightness == Brightness.dark
                                ? Colors.grey[850]
                                : Colors.grey[200],
                          ),
                          columns: const [
                            DataColumn(label: Text('اسم الباقة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('مدة الاشتراك', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('السعر', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('أيام التجميد مسموح', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الزيارات المسموحة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('حالة الباقة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('تاريخ الإنشاء', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: memberships.map((membership) {
                            return DataRow(
                              cells: [
                                // اسم الباقة
                                DataCell(Text(membership.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                // الإجراءات
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                        tooltip: 'تعديل الباقة',
                                        onPressed: () => _showEditMembershipDialog(context, membership),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                        tooltip: 'حذف الباقة',
                                        onPressed: () => _showDeleteConfirmDialog(context, membership),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                      ),
                                    ],
                                  ),
                                ),
                                // مدة الاشتراك
                                DataCell(Text('${membership.durationDays} يوم')),
                                // السعر
                                DataCell(Text('${_formatCurrency(membership.price)} ج.م')),
                                // أيام التجميد
                                DataCell(Text('${membership.freezeDays} يوم')),
                                // الزيارات
                                DataCell(
                                  Text(
                                    membership.visitsLimit != null
                                        ? '${membership.visitsLimit} زيارة'
                                        : 'مفتوح (غير محدود)',
                                  ),
                                ),
                                // حالة الباقة
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: membership.isActive
                                          ? ColorPalette.activeStatus.withOpacity(0.12)
                                          : ColorPalette.expiredStatus.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      membership.isActive ? 'نشطة' : 'موقوفة',
                                      style: TextStyle(
                                        color: membership.isActive
                                            ? ColorPalette.activeStatus
                                            : ColorPalette.expiredStatus,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                // تاريخ الإنشاء
                                DataCell(Text(_formatDate(membership.createdAt))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return const Center(child: Text('تحميل البيانات...'));
          },
        ),
      ),
    ]);
  }
}
