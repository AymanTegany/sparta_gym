import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/common/widgets/sidebar_layout.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/employee_entity.dart';
import '../cubit/shifts_cubit.dart';
import '../cubit/shifts_state.dart';

/// صفحة إدارة الموظفين — إضافة، تعديل، حذف الموظفين.
class ManageEmployeesPage extends StatefulWidget {
  const ManageEmployeesPage({super.key});

  @override
  State<ManageEmployeesPage> createState() => _ManageEmployeesPageState();
}

class _ManageEmployeesPageState extends State<ManageEmployeesPage> {
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoadingSchedules = false;

  Duration _timeUntilStart(int startHour, int startMinute) {
    final now = DateTime.now();
    var startDateTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
    if (startDateTime.isBefore(now)) {
      startDateTime = startDateTime.add(const Duration(days: 1));
    }
    return startDateTime.difference(now);
  }

  String _formatDurationArabic(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours == 0) {
      return '$minutes دقيقة';
    } else if (hours == 1) {
      if (minutes == 0) return 'ساعة واحدة';
      return 'ساعة و$minutes دقيقة';
    } else if (hours == 2) {
      if (minutes == 0) return 'ساعتين';
      return 'ساعتين و$minutes دقيقة';
    } else if (hours >= 3 && hours <= 10) {
      if (minutes == 0) return '$hours ساعات';
      return '$hours ساعات و$minutes دقيقة';
    } else {
      if (minutes == 0) return '$hours ساعة';
      return '$hours ساعة و$minutes دقيقة';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoadingSchedules = true);
    context.read<ShiftsCubit>().loadEmployees();
    final schedules = await context.read<ShiftsCubit>().getScheduledShifts();
    if (mounted) {
      setState(() {
        _schedules = schedules;
        _isLoadingSchedules = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor:
              isError ? ColorPalette.errorColor : ColorPalette.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return SidebarLayout(
      activePage: 'employees',
      title: 'إدارة الموظفين',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showAddEditDialog(context),
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text('إضافة موظف'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
      body: BlocListener<ShiftsCubit, ShiftsState>(
        listener: (context, state) {
          if (state is ShiftsError) {
            _showSnackBar(state.message, isError: true);
          } else if (state is ShiftsEmployeeActionSuccess) {
            _showSnackBar(state.message);
            // إعادة تحميل القائمة بعد أي عملية ناجحة
            _loadData();
          }
        },
        child: BlocBuilder<ShiftsCubit, ShiftsState>(
          buildWhen: (prev, curr) =>
              curr is ShiftsEmployeesLoaded || curr is ShiftsLoading,
          builder: (context, state) {
            if (state is ShiftsLoading || _isLoadingSchedules) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ShiftsEmployeesLoaded) {
              if (state.employees.isEmpty) {
                return _buildEmptyState(isDark, primary);
              }
              return _buildEmployeesList(
                  state.employees, theme, isDark, primary);
            }

            // حالة افتراضية
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // حالة عدم وجود موظفين
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState(bool isDark, Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off_rounded,
            size: 72,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد موظفين',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? ColorPalette.textPrimaryDark
                  : ColorPalette.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على "إضافة موظف" لإضافة أول موظف',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? ColorPalette.textSecondaryDark
                  : ColorPalette.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(context),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('إضافة موظف'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // قائمة الموظفين
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildEmployeesList(
      List<Employee> employees, ThemeData theme, bool isDark, Color primary) {
    final dateFmt = DateFormat('d/M/yyyy', 'ar');

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final emp = employees[index];
        final scheduleIndex = _schedules.indexWhere((s) => s['employeeId'] == emp.id);
        final schedule = scheduleIndex != -1 ? _schedules[scheduleIndex] : null;

        String scheduleText = '';
        if (schedule != null) {
          final startHour = (schedule['startHour'] as int).toString().padLeft(2, '0');
          final startMinute = (schedule['startMinute'] as int).toString().padLeft(2, '0');
          final endHour = (schedule['endHour'] as int).toString().padLeft(2, '0');
          final endMinute = (schedule['endMinute'] as int).toString().padLeft(2, '0');
          scheduleText = '$startHour:$startMinute - $endHour:$endMinute';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            // الأفاتار
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: emp.isActive
                  ? primary.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.15),
              child: Text(
                emp.name.isNotEmpty ? emp.name.substring(0, 1) : '؟',
                style: TextStyle(
                  color: emp.isActive ? primary : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            // الاسم والدور
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    emp.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark
                          ? ColorPalette.textPrimaryDark
                          : ColorPalette.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRoleBadge(emp),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // حالة النشاط
                  _buildStatusBadge(emp.isActive),
                  if (schedule != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: schedule['isEnabled'] == 1 ? Colors.green : Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          schedule['isEnabled'] == 1
                              ? 'الدوام: $scheduleText (نشط - يبدأ بعد ${_formatDurationArabic(_timeUntilStart(schedule['startHour'] as int, schedule['startMinute'] as int))})'
                              : 'الدوام: $scheduleText (معطل)',
                          style: TextStyle(
                            fontSize: 12,
                            color: schedule['isEnabled'] == 1 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 14, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        const Text(
                          'الدوام: غير محدد (معطل)',
                          style: TextStyle(fontSize: 12, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ],
                  // تاريخ الإنشاء
                  if (emp.createdAt != null)
                    Text(
                      'أُضيف: ${dateFmt.format(emp.createdAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? ColorPalette.textSecondaryDark
                            : ColorPalette.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
            // أزرار التعديل والحذف
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_rounded,
                      color: ColorPalette.infoColor, size: 20),
                  onPressed: () => _showAddEditDialog(context, employee: emp),
                  tooltip: 'تعديل',
                ),
                IconButton(
                  icon: Icon(Icons.delete_rounded,
                      color: ColorPalette.errorColor, size: 20),
                  onPressed: () => _showDeleteDialog(context, emp),
                  tooltip: 'حذف',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // شارات الدور والحالة
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildRoleBadge(Employee emp) {
    final isAdmin = emp.isAdmin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin
            ? ColorPalette.warningColor.withOpacity(0.12)
            : ColorPalette.infoColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        emp.roleLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isAdmin ? ColorPalette.warningColor : ColorPalette.infoColor,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? ColorPalette.successColor.withOpacity(0.12)
            : ColorPalette.errorColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 7,
            color: isActive
                ? ColorPalette.successColor
                : ColorPalette.errorColor,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'نشط' : 'غير نشط',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? ColorPalette.successColor
                  : ColorPalette.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // حوار إضافة/تعديل موظف
  // ══════════════════════════════════════════════════════════════════════════

  void _showAddEditDialog(BuildContext context, {Employee? employee}) {
    final isEdit = employee != null;
    final nameCtrl = TextEditingController(text: employee?.name ?? '');
    final passwordCtrl = TextEditingController();
    String selectedRole = employee?.role ?? 'employee';
    bool isActive = employee?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final scheduleIndex = employee != null
        ? _schedules.indexWhere((s) => s['employeeId'] == employee.id)
        : -1;
    final schedule = scheduleIndex != -1 ? _schedules[scheduleIndex] : null;

    TimeOfDay selectedStartTime = schedule != null
        ? TimeOfDay(
            hour: schedule['startHour'] as int,
            minute: schedule['startMinute'] as int,
          )
        : const TimeOfDay(hour: 9, minute: 0);

    TimeOfDay selectedEndTime = schedule != null
        ? TimeOfDay(
            hour: schedule['endHour'] as int,
            minute: schedule['endMinute'] as int,
          )
        : const TimeOfDay(hour: 17, minute: 0);

    bool isScheduledEnabled = schedule != null ? (schedule['isEnabled'] == 1) : true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                backgroundColor: theme.colorScheme.surface,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── أيقونة Header ──
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isEdit
                                  ? Icons.edit_rounded
                                  : Icons.person_add_alt_1_rounded,
                              color: primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isEdit ? 'تعديل بيانات الموظف' : 'إضافة موظف جديد',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? ColorPalette.textPrimaryDark
                                  : ColorPalette.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── اسم الموظف ──
                          TextFormField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'اسم الموظف',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'أدخل اسم الموظف'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ── كلمة المرور ──
                          TextFormField(
                            controller: passwordCtrl,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: isEdit
                                  ? 'كلمة المرور الجديدة (اختياري)'
                                  : 'كلمة المرور',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                            ),
                            validator: isEdit
                                ? null
                                : (v) => (v == null || v.isEmpty)
                                    ? 'أدخل كلمة المرور'
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          // ── الدور ──
                          DropdownButtonFormField<String>(
                            value: selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'الدور',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'employee',
                                child: Text('موظف'),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('مدير'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => selectedRole = v);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── وقت بداية الشفت ──
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.green,
                            ),
                            title: const Text('وقت بداية الشفت'),
                            subtitle: Text(selectedStartTime.format(ctx)),
                            trailing: TextButton(
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: ctx,
                                  initialTime: selectedStartTime,
                                );
                                if (time != null) {
                                  setDialogState(() => selectedStartTime = time);
                                }
                              },
                              child: const Text('تغيير'),
                            ),
                          ),

                          // ── وقت نهاية الشفت ──
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.stop_rounded,
                              color: Colors.redAccent,
                            ),
                            title: const Text('وقت نهاية الشفت'),
                            subtitle: Text(selectedEndTime.format(ctx)),
                            trailing: TextButton(
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: ctx,
                                  initialTime: selectedEndTime,
                                );
                                if (time != null) {
                                  setDialogState(() => selectedEndTime = time);
                                }
                              },
                              child: const Text('تغيير'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('تفعيل الجدولة التلقائية'),
                            subtitle: const Text('بدء الشفت تلقائياً عند حلول موعده'),
                            value: isScheduledEnabled,
                            onChanged: (val) {
                              setDialogState(() => isScheduledEnabled = val);
                            },
                            activeColor: primary,
                          ),
                          const SizedBox(height: 8),

                          // ── حالة النشاط (للتعديل فقط) ──
                          if (isEdit)
                            SwitchListTile(
                              title: const Text('نشط'),
                              subtitle: Text(
                                isActive
                                    ? 'الموظف يمكنه تسجيل الدخول'
                                    : 'الموظف معطّل',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? ColorPalette.textSecondaryDark
                                      : ColorPalette.textSecondaryLight,
                                ),
                              ),
                              value: isActive,
                              onChanged: (v) {
                                setDialogState(() => isActive = v);
                              },
                              activeColor: ColorPalette.successColor,
                              contentPadding: EdgeInsets.zero,
                            ),
                          const SizedBox(height: 24),

                          // ── الأزرار ──
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('إلغاء'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    Navigator.pop(ctx);

                                    if (isEdit) {
                                      final updated = employee.copyWith(
                                        name: nameCtrl.text.trim(),
                                        role: selectedRole,
                                        isActive: isActive,
                                      );
                                      await context
                                          .read<ShiftsCubit>()
                                          .updateEmployee(
                                            updated,
                                            newPassword:
                                                passwordCtrl.text.isNotEmpty
                                                    ? passwordCtrl.text
                                                    : null,
                                          );

                                      await context
                                          .read<ShiftsCubit>()
                                          .updateEmployeeSchedule(
                                            employeeId: employee.id!,
                                            employeeName: nameCtrl.text.trim(),
                                            startHour: selectedStartTime.hour,
                                            startMinute: selectedStartTime.minute,
                                            endHour: selectedEndTime.hour,
                                            endMinute: selectedEndTime.minute,
                                            isEnabled: isScheduledEnabled ? 1 : 0,
                                          );
                                      _loadData();
                                    } else {
                                      final newEmployee = await context
                                          .read<ShiftsCubit>()
                                          .addEmployee(
                                            name: nameCtrl.text.trim(),
                                            password: passwordCtrl.text,
                                            role: selectedRole,
                                          );
                                      if (newEmployee != null) {
                                        await context
                                            .read<ShiftsCubit>()
                                            .addScheduledShift(
                                              employeeId: newEmployee.id!,
                                              employeeName: newEmployee.name,
                                              startHour: selectedStartTime.hour,
                                              startMinute: selectedStartTime.minute,
                                              endHour: selectedEndTime.hour,
                                              endMinute: selectedEndTime.minute,
                                              isEnabled: isScheduledEnabled ? 1 : 0,
                                            );
                                        _loadData();
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    isEdit ? 'حفظ التعديلات' : 'إضافة',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // حوار تأكيد الحذف
  // ══════════════════════════════════════════════════════════════════════════

  void _showDeleteDialog(BuildContext context, Employee employee) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorPalette.errorColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: ColorPalette.errorColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('حذف الموظف'),
              ],
            ),
            content: Text(
              'هل أنت متأكد من حذف الموظف "${employee.name}"؟\n\nهذا الإجراء لا يمكن التراجع عنه.',
              style: TextStyle(
                color: isDark
                    ? ColorPalette.textSecondaryDark
                    : ColorPalette.textSecondaryLight,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (employee.id != null) {
                    context.read<ShiftsCubit>().deleteEmployee(employee.id!);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.errorColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );
  }
}
