import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/employee_entity.dart';
import '../cubit/shifts_cubit.dart';
import '../cubit/shifts_state.dart';
import '../pages/shift_report_page.dart';

class ShiftManagementDialog extends StatefulWidget {
  const ShiftManagementDialog({super.key});

  @override
  State<ShiftManagementDialog> createState() => _ShiftManagementDialogState();
}

class _ShiftManagementDialogState extends State<ShiftManagementDialog> {
  List<Employee> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });
    final employees = await context.read<ShiftsCubit>().fetchEmployeesList();
    setState(() {
      _employees = employees.where((e) => e.isActive).toList();
      _isLoading = false;
    });
  }

  void _showAddEmployeeDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    TimeOfDay selectedTime = TimeOfDay.now();
    TimeOfDay selectedEndTime = const TimeOfDay(hour: 23, minute: 59);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.person_add_alt_1_rounded),
                  SizedBox(width: 8),
                  Text('إضافة شفت جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم موظف الشيفت',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.play_arrow_rounded, color: Colors.green),
                      title: const Text('وقت البداية'),
                      subtitle: Text(selectedTime.format(context)),
                      trailing: TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                        child: const Text('تغيير'),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.stop_rounded, color: Colors.redAccent),
                      title: const Text('وقت النهاية'),
                      subtitle: Text(selectedEndTime.format(context)),
                      trailing: TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedEndTime,
                          );
                          if (time != null) {
                            setDialogState(() => selectedEndTime = time);
                          }
                        },
                        child: const Text('تغيير'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isSaving = true);
                            final shiftsCubit = context.read<ShiftsCubit>();
                            
                            // 1. إضافة الموظف
                            final newEmployee = await shiftsCubit.addEmployee(
                              name: nameCtrl.text,
                              password: '1234',
                            );
                            
                            if (newEmployee == null) {
                              setDialogState(() => isSaving = false);
                              return;
                            }
                            
                            // 2. حفظ الجدولة التلقائية (مع وقت البداية والنهاية)
                            await shiftsCubit.addScheduledShift(
                              employeeId: newEmployee.id!,
                              employeeName: newEmployee.name,
                              startHour: selectedTime.hour,
                              startMinute: selectedTime.minute,
                              endHour: selectedEndTime.hour,
                              endMinute: selectedEndTime.minute,
                            );
                            
                            // 3. لو الوقت المحدد فات أو يساوي الوقت الحالي → ابدأ الشفت فوراً
                            final now = DateTime.now();
                            final scheduledTime = DateTime(
                              now.year, now.month, now.day,
                              selectedTime.hour, selectedTime.minute,
                            );
                            
                            if (!scheduledTime.isAfter(now)) {
                              await shiftsCubit.startShiftDirectly(
                                newEmployee,
                                customStartTime: scheduledTime,
                              );
                            }
                            
                            // 4. إغلاق الدايلوج وتحديث القائمة
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            _loadEmployees();
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // الهيدر
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 28, color: ColorPalette.primaryColor),
                    SizedBox(width: 12),
                    Text(
                      'الموظف والشفتات',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),

            // القائمة
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _employees.isEmpty
                      ? const Center(child: Text('لا يوجد موظفين حالياً'))
                      : BlocBuilder<ShiftsCubit, ShiftsState>(
                          builder: (context, state) {
                            final activeShift = context.read<ShiftsCubit>().activeShift;

                            return ListView.separated(
                              itemCount: _employees.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final employee = _employees[index];
                                final isThisActive = activeShift?.employeeId == employee.id;
                                final isAnyActive = activeShift != null;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isThisActive ? Colors.orange : Colors.grey.shade200,
                                    child: Text(
                                      employee.name.substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        color: isThisActive ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    employee.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    isThisActive ? 'في الشفت حالياً' : 'غير متصل',
                                    style: TextStyle(color: isThisActive ? Colors.orange : Colors.grey),
                                  ),
                                  trailing: isThisActive
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                final report = await context.read<ShiftsCubit>().getLiveShiftReport();
                                                if (report != null && context.mounted) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => ShiftReportPage(
                                                        report: report,
                                                        onNewShift: () {},
                                                        isActiveShift: true,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blueAccent,
                                                foregroundColor: Colors.white,
                                              ),
                                              icon: const Icon(Icons.assessment_outlined, size: 18),
                                              label: const Text('تقرير الشفت'),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                context.read<ShiftsCubit>().endShiftDirectly();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.redAccent,
                                                foregroundColor: Colors.white,
                                              ),
                                              icon: const Icon(Icons.stop_circle_outlined, size: 18),
                                              label: const Text('إنهاء الشفت'),
                                            ),
                                          ],
                                        )
                                      : ElevatedButton.icon(
                                          onPressed: isAnyActive
                                              ? null
                                              : () {
                                                  context.read<ShiftsCubit>().startShiftDirectly(employee);
                                                },
                                          icon: const Icon(Icons.play_circle_outline, size: 18),
                                          label: const Text('بدء الشفت'),
                                        ),
                                );
                              },
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            
            // زر إضافة شفت جديد
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddEmployeeDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('إضافة شفت جديد'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
