import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/employee_entity.dart';
import '../cubit/shifts_cubit.dart';
import '../cubit/shifts_state.dart';

/// صفحة تسجيل دخول الشفت — يختار الموظف اسمه ويُدخل كلمة المرور لبدء الشفت.
/// تُعرض بعد تسجيل الدخول الرئيسي (Auth) وقبل الوصول للتطبيق.
class ShiftLoginPage extends StatefulWidget {
  final VoidCallback onShiftStarted;

  const ShiftLoginPage({super.key, required this.onShiftStarted});

  @override
  State<ShiftLoginPage> createState() => _ShiftLoginPageState();
}

class _ShiftLoginPageState extends State<ShiftLoginPage>
    with SingleTickerProviderStateMixin {
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  Employee? _selectedEmployee;
  bool _isLoggingIn = false;

  // ساعة حيّة
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  // أنيميشن
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _startShift() async {
    if (_selectedEmployee == null) {
      _showSnackBar('يرجى اختيار الموظف أولاً', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoggingIn = true);

    final success = await context.read<ShiftsCubit>().loginAndStartShift(
          name: _selectedEmployee!.name,
          password: _passwordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _isLoggingIn = false);

    if (success) {
      widget.onShiftStarted();
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  void _showAddEmployeeDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

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
                  Text('إضافة موظف جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        labelText: 'اسم الموظف',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passCtrl,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      obscureText: true,
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
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
                            final employee = await context.read<ShiftsCubit>().addEmployee(
                                  name: nameCtrl.text,
                                  password: passCtrl.text,
                                );
                            if (employee != null && mounted) {
                              Navigator.pop(ctx);
                              context.read<ShiftsCubit>().checkActiveShift();
                            } else {
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('حفظ وإضافة'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor:
          isDark ? ColorPalette.backgroundDark : ColorPalette.backgroundLight,
      body: BlocListener<ShiftsCubit, ShiftsState>(
        listener: (context, state) {
          if (state is ShiftsError) {
            _showSnackBar(state.message, isError: true);
          }
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      // ── الساعة والتاريخ ──
                      _buildClockHeader(theme, isDark, primary),
                      const SizedBox(height: 28),

                      // ── البطاقة الرئيسية ──
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // ── Header ──
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primary, primary.withOpacity(0.85)],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.access_time_filled_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'تسجيل دخول الشفت',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'اختر اسمك وأدخل كلمة المرور لبدء الشفت',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── قائمة الموظفين ──
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.people_alt_rounded,
                                          size: 20, color: primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'اختر الموظف',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildEmployeeGrid(theme, isDark, primary),
                                ],
                              ),
                            ),

                            // ── حقل كلمة المرور وزر الدخول ──
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _passwordCtrl,
                                      obscureText: _obscure,
                                      decoration: InputDecoration(
                                        labelText: 'كلمة المرور',
                                        prefixIcon:
                                            const Icon(Icons.lock_outline_rounded),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(
                                              () => _obscure = !_obscure),
                                        ),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.isEmpty)
                                              ? 'أدخل كلمة المرور'
                                              : null,
                                      onFieldSubmitted: (_) => _startShift(),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isLoggingIn ? null : _startShift,
                                        icon: _isLoggingIn
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.play_arrow_rounded),
                                        label: Text(
                                          _isLoggingIn
                                              ? 'جاري التسجيل...'
                                              : 'بدء الشفت',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── ساعة وتاريخ في الأعلى ──
  Widget _buildClockHeader(ThemeData theme, bool isDark, Color primary) {
    final timeStr = DateFormat('hh:mm:ss a', 'ar').format(_now);
    final dateStr = DateFormat('EEEE، d MMMM yyyy', 'ar').format(_now);

    return Column(
      children: [
        Icon(Icons.fitness_center_rounded, color: primary, size: 40),
        const SizedBox(height: 12),
        Text(
          timeStr,
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? ColorPalette.textSecondaryDark
                : ColorPalette.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  // ── شبكة بطاقات الموظفين ──
  Widget _buildEmployeeGrid(ThemeData theme, bool isDark, Color primary) {
    return BlocBuilder<ShiftsCubit, ShiftsState>(
      buildWhen: (prev, curr) => curr is ShiftsNoActiveShift,
      builder: (context, state) {
        List<Employee> employees = [];
        if (state is ShiftsNoActiveShift) {
          employees = state.employees;
        }

        if (employees.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.person_off_rounded,
                    size: 48,
                    color: isDark
                        ? Colors.grey[600]
                        : Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'لا يوجد موظفين نشطين',
                  style: TextStyle(
                    color: isDark
                        ? ColorPalette.textSecondaryDark
                        : ColorPalette.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showAddEmployeeDialog(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('إضافة موظف (للمسؤول)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary.withOpacity(0.1),
                    foregroundColor: primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: employees.map((emp) {
            final isSelected = _selectedEmployee?.id == emp.id;
            return _EmployeeCard(
              employee: emp,
              isSelected: isSelected,
              primary: primary,
              isDark: isDark,
              onTap: () {
                setState(() => _selectedEmployee = emp);
              },
            );
          }).toList(),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// بطاقة الموظف
// ══════════════════════════════════════════════════════════════════════════════

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final bool isSelected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  const _EmployeeCard({
    required this.employee,
    required this.isSelected,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isSelected
            ? primary.withOpacity(0.12)
            : (isDark ? ColorPalette.cardDark : ColorPalette.cardLight),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الأفاتار
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      isSelected ? primary : primary.withOpacity(0.2),
                  child: Text(
                    employee.name.isNotEmpty
                        ? employee.name.substring(0, 1)
                        : '؟',
                    style: TextStyle(
                      color: isSelected ? Colors.white : primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSelected
                            ? primary
                            : (isDark
                                ? ColorPalette.textPrimaryDark
                                : ColorPalette.textPrimaryLight),
                      ),
                    ),
                    Text(
                      employee.roleLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? ColorPalette.textSecondaryDark
                            : ColorPalette.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle_rounded, color: primary, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
