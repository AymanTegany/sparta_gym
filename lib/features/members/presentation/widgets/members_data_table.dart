import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/member_entity.dart';

/// جدول بيانات العملاء مع Pagination.
/// يعرض: رقم العضوية، الاسم، الهاتف، نوع الاشتراك، تاريخ البداية، الانتهاء، الحالة،
/// المدفوع، المتبقي، الأيام المتبقية، الإجراءات.
class MembersDataTable extends StatefulWidget {
  final List<Member> members;
  final Function(Member) onEdit;
  final Function(Member) onDelete;
  final Function(Member) onViewDetails;
  final Function(Member) onRenew;
  final Function(Member) onAddPayment;
  final Function(Member) onPrintCard;
  final Function(Member) onWhatsAppAlert;
  final Function(Member) onWelcomeMessage;
  final Function(Member) onRefundAndDelete;

  const MembersDataTable({
    super.key,
    required this.members,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
    required this.onRenew,
    required this.onAddPayment,
    required this.onPrintCard,
    required this.onWhatsAppAlert,
    required this.onWelcomeMessage,
    required this.onRefundAndDelete,
  });

  @override
  State<MembersDataTable> createState() => _MembersDataTableState();
}

class _MembersDataTableState extends State<MembersDataTable> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  late List<Member> _sortedMembers;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sortedMembers = List.from(widget.members);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MembersDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.members != widget.members) {
      _sortedMembers = List.from(widget.members);
    }
  }

  void _sort<T>(
    Comparable<T> Function(Member m) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortedMembers.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_sortedMembers.isEmpty) {
      return _buildEmptyState(context, isDark);
    }

    return Column(
      children: [
        // الجدول
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? ColorPalette.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade200,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Scrollbar(
                controller: _verticalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalScrollController,
                  scrollDirection: Axis.vertical,
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                headingRowHeight: 48,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 56,
                columnSpacing: 20,
                horizontalMargin: 16,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                headingRowColor: WidgetStateProperty.all(
                  isDark
                      ? ColorPalette.tableHeaderDark
                      : ColorPalette.tableHeaderLight,
                ),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                columns: [
                  DataColumn(
                    label: const Text('رقم العضوية'),
                    onSort: (i, asc) => _sort((m) => m.memberId, i, asc),
                  ),
                  DataColumn(
                    label: const Text('الاسم'),
                    onSort: (i, asc) => _sort((m) => m.fullName, i, asc),
                  ),
                  const DataColumn(label: Text('رقم الهاتف')),
                  const DataColumn(label: Text('نوع الاشتراك')),
                  DataColumn(
                    label: const Text('تاريخ البداية'),
                    onSort: (i, asc) => _sort((m) => m.startDate, i, asc),
                  ),
                  DataColumn(
                    label: const Text('تاريخ الانتهاء'),
                    onSort: (i, asc) => _sort((m) => m.endDate, i, asc),
                  ),
                  const DataColumn(label: Text('الحالة')),
                  DataColumn(
                    label: const Text('المدفوع'),
                    numeric: true,
                    onSort: (i, asc) => _sort((m) => m.paidAmount, i, asc),
                  ),
                  DataColumn(
                    label: const Text('المتبقي'),
                    numeric: true,
                    onSort: (i, asc) => _sort((m) => m.remainingAmount, i, asc),
                  ),
                  DataColumn(
                    label: const Text('أيام متبقية'),
                    numeric: true,
                    onSort: (i, asc) => _sort((m) => m.remainingDays, i, asc),
                  ),
                  const DataColumn(label: Text('الإجراءات')),
                ],
                rows: List.generate(_sortedMembers.length, (index) {
                  final member = _sortedMembers[index];
                  final isEvenRow = index.isEven;

                  return DataRow(
                    color: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.colorScheme.primary.withValues(
                          alpha: 0.05,
                        );
                      }
                      return isEvenRow
                          ? (isDark
                                ? ColorPalette.tableRowEvenDark
                                : ColorPalette.tableRowEvenLight)
                          : (isDark
                                ? ColorPalette.tableRowOddDark
                                : ColorPalette.tableRowOddLight);
                    }),
                    cells: [
                      DataCell(
                        Text(
                          member.memberId,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        onTap: () => widget.onViewDetails(member),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              child: Text(
                                member.fullName.isNotEmpty
                                    ? member.fullName[0]
                                    : '?',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                member.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => widget.onViewDetails(member),
                      ),
                      DataCell(Text(member.phoneNumber ?? '-')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            member.membershipType,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(_formatDate(member.startDate))),
                      DataCell(Text(_formatDate(member.endDate))),
                      DataCell(_buildStatusBadge(member)),
                      DataCell(
                        Text(
                          '${member.paidAmount.toStringAsFixed(0)} ج.م',
                          style: TextStyle(
                            color: isDark
                                ? ColorPalette.textPrimaryDark
                                : ColorPalette.textPrimaryLight,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${member.remainingAmount.toStringAsFixed(0)} ج.م',
                          style: TextStyle(
                            color: member.hasDebt
                                ? ColorPalette.debtStatus
                                : ColorPalette.activeStatus,
                            fontWeight: member.hasDebt
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${member.remainingDays} يوم',
                          style: TextStyle(
                            color: member.remainingDays == 0
                                ? ColorPalette.expiredStatus
                                : member.remainingDays <= 7
                                ? ColorPalette.expiringSoonStatus
                                : (isDark
                                      ? ColorPalette.textPrimaryDark
                                      : ColorPalette.textPrimaryLight),
                            fontWeight: member.remainingDays <= 7
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      DataCell(_buildActionsMenu(context, member, isDark)),
                    ],
                  );
                }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// بناء شارة الحالة
  Widget _buildStatusBadge(Member member) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    if (!member.isActive) {
      bgColor = ColorPalette.expiredStatus.withValues(alpha: 0.12);
      textColor = ColorPalette.expiredStatus;
      text = 'منتهي';
      icon = Icons.cancel_rounded;
    } else if (member.isExpiringSoon) {
      bgColor = ColorPalette.expiringSoonStatus.withValues(alpha: 0.12);
      textColor = ColorPalette.expiringSoonStatus;
      text = 'ينتهي قريباً';
      icon = Icons.warning_rounded;
    } else {
      bgColor = ColorPalette.activeStatus.withValues(alpha: 0.12);
      textColor = ColorPalette.activeStatus;
      text = 'نشط';
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// قائمة الإجراءات
  Widget _buildActionsMenu(BuildContext context, Member member, bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: isDark
            ? ColorPalette.textSecondaryDark
            : ColorPalette.textSecondaryLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? ColorPalette.cardDark : Colors.white,
      elevation: 8,
      onSelected: (value) {
        switch (value) {
          case 'view':
            widget.onViewDetails(member);
            break;
          case 'edit':
            widget.onEdit(member);
            break;
          case 'renew':
            widget.onRenew(member);
            break;
          case 'payment':
            widget.onAddPayment(member);
            break;
          case 'print':
            widget.onPrintCard(member);
            break;
          case 'whatsapp':
            widget.onWhatsAppAlert(member);
            break;
          case 'welcome_msg':
            widget.onWelcomeMessage(member);
            break;
          case 'refund_delete':
            widget.onRefundAndDelete(member);
            break;
          case 'delete':
            widget.onDelete(member);
            break;
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem(
          'view',
          Icons.visibility_rounded,
          'عرض التفاصيل',
          isDark,
        ),
        _buildPopupItem('edit', Icons.edit_rounded, 'تعديل', isDark),
        _buildPopupItem(
          'renew',
          Icons.autorenew_rounded,
          'تجديد اشتراك',
          isDark,
        ),
        _buildPopupItem('payment', Icons.payment_rounded, 'إضافة دفعة', isDark),
        _buildPopupItem('print', Icons.print_rounded, 'طباعة بطاقة', isDark),
        _buildPopupItem('whatsapp', Icons.chat_rounded, 'تنبيه واتساب', isDark),
        _buildPopupItem('welcome_msg', Icons.waving_hand_rounded, 'رسالة ترحيب', isDark),
        const PopupMenuDivider(),
        _buildPopupItem(
          'refund_delete',
          Icons.money_off_rounded,
          'ارجاع مبلغ الاشتراك وحذف العميل',
          isDark,
          isDestructive: true,
        ),
        _buildPopupItem(
          'delete',
          Icons.delete_rounded,
          'حذف',
          isDark,
          isDestructive: true,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String label,
    bool isDark, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDestructive
                ? ColorPalette.errorColor
                : (isDark
                      ? ColorPalette.textSecondaryDark
                      : ColorPalette.textSecondaryLight),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: isDestructive
                  ? ColorPalette.errorColor
                  : (isDark
                        ? ColorPalette.textPrimaryDark
                        : ColorPalette.textPrimaryLight),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }



  /// بناء حالة عدم وجود بيانات
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: isDark ? ColorPalette.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 72,
            color: isDark
                ? ColorPalette.textSecondaryDark.withValues(alpha: 0.4)
                : ColorPalette.textSecondaryLight.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد عملاء',
            style: theme.textTheme.titleLarge?.copyWith(
              color: isDark
                  ? ColorPalette.textSecondaryDark
                  : ColorPalette.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإضافة عميل جديد للبدء',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorPalette.textSecondaryDark.withValues(alpha: 0.7)
                  : ColorPalette.textSecondaryLight.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// تنسيق التاريخ
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy/MM/dd').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
