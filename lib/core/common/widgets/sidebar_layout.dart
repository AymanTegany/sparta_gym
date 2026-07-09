import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/color_palette.dart';
import '../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../features/auth/presentation/cubit/auth_state.dart';
import '../../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../../features/settings/presentation/cubit/settings_state.dart';
import '../../../features/home/presentation/pages/home_page.dart';
import '../../../features/members/presentation/pages/members_page.dart';
import '../../../features/attendance/presentation/pages/attendance_page.dart';
import '../../../features/memberships/presentation/pages/memberships_page.dart';
import '../../../features/payments/presentation/pages/payments_page.dart';
import '../../../features/settings/presentation/pages/settings_page.dart';
import '../../../features/trainers/presentation/pages/trainers_page.dart';
import '../../../features/expenses/presentation/pages/expenses_page.dart';
import '../../../features/inventory/presentation/pages/inventory_page.dart';
import '../../../features/pos/presentation/pages/pos_page.dart';
import '../../../features/diets/presentation/pages/diet_plans_page.dart';
import '../../../features/reports/presentation/pages/reports_page.dart';
import '../../../features/reports/presentation/pages/comprehensive_reports_page.dart';
import '../../../features/shifts/presentation/cubit/shifts_cubit.dart';
import '../../../features/shifts/presentation/cubit/shifts_state.dart';
import '../../../features/shifts/presentation/pages/manage_employees_page.dart';
import '../../../features/shifts/presentation/widgets/end_shift_dialog.dart';
import '../../../features/shifts/presentation/widgets/shift_management_dialog.dart';
import '../../../init_dependencies.dart';
import 'global_scanner_listener.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// تخطيط الصفحة الموحد مع شريط تنقل جانبي متطور وقابل للطي (SidebarLayout)
/// يدعم وضع سطح المكتب (Sidebar ثابت) ووضع الموبايل (Drawer منزلق) تلقائياً.
/// ──────────────────────────────────────────────────────────────────────────────
class SidebarLayout extends StatefulWidget {
  final String activePage;
  final String title;
  final List<Widget>? actions;
  final Widget body;

  const SidebarLayout({
    super.key,
    required this.activePage,
    required this.title,
    this.actions,
    required this.body,
  });

  @override
  State<SidebarLayout> createState() => _SidebarLayoutState();
}

class _SidebarLayoutState extends State<SidebarLayout> {
  // حالة الطي العامة (تُحفظ كمتغير ستاتيك لتظل ثابتة أثناء التنقل بين الصفحات)
  static bool _isCollapsed = false;
  final ScrollController _sidebarScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // استرجاع حالة الطي المخزنة في الذاكرة الدائمة
    try {
      final prefs = serviceLocator<SharedPreferences>();
      setState(() {
        _isCollapsed = prefs.getBool('sidebar_collapsed') ?? _isCollapsed;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _sidebarScrollController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
    try {
      final prefs = serviceLocator<SharedPreferences>();
      prefs.setBool('sidebar_collapsed', _isCollapsed);
    } catch (_) {}
  }

  void _navigateTo(BuildContext context, String page) {
    if (widget.activePage == page) return;

    Widget targetPage;
    switch (page) {
      case 'home':
        final settingsCubit = context.read<SettingsCubit>();
        final isDarkMode = settingsCubit.state is SettingsLoaded
            ? (settingsCubit.state as SettingsLoaded).settings.themeMode == 'dark'
            : false;
        targetPage = HomePage(
          onThemeToggle: () => settingsCubit.toggleTheme(),
          isDarkMode: isDarkMode,
        );
        break;
      case 'members':
        targetPage = const MembersPage();
        break;
      case 'attendance':
        targetPage = const AttendancePage();
        break;
      case 'memberships':
        targetPage = const MembershipsPage();
        break;
      case 'payments':
        targetPage = const PaymentsPage();
        break;
      case 'settings':
        targetPage = const SettingsPage();
        break;
      case 'trainers':
        targetPage = const TrainersPage();
        break;
      case 'expenses':
        targetPage = const ExpensesPage();
        break;
      case 'inventory':
        targetPage = const InventoryPage();
        break;
      case 'pos':
        targetPage = const PosPage();
        break;
      case 'diets':
        targetPage = const DietPlansPage();
        break;
      case 'reports':
        targetPage = const ReportsPage();
        break;
      case 'comprehensive_reports':
        targetPage = const ComprehensiveReportsPage();
        break;
      case 'employees':
        targetPage = const ManageEmployeesPage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // تأثير حركة انتقال ناعمة جداً
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
              Navigator.of(context, rootNavigator: true)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void _showEndShiftDialog(BuildContext context, ShiftsCubit shiftsCubit, ShiftsState state) {
    if (state is ShiftsActiveShift) {
      showDialog(
        context: context,
        builder: (ctx) => EndShiftDialog(
          currentShift: state.shift,
          onConfirm: () {
            shiftsCubit.endCurrentShift();
          },
        ),
      );
    }
  }

  // بناء عنصر ملاحة منفرد
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String page,
    required ThemeData theme,
  }) {
    final bool isSelected = widget.activePage == page;
    final primary = theme.colorScheme.primary;

    if (_isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Tooltip(
          message: title,
          preferBelow: false,
          child: Material(
            color: isSelected ? primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _navigateTo(context, page),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border(right: BorderSide(color: primary, width: 3.5))
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? primary : (theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600]),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Material(
        color: isSelected ? primary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _navigateTo(context, page),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isSelected
                  ? Border(right: BorderSide(color: primary, width: 3.5))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? primary : (theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600]),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? primary : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // بناء شريط التنقل الجانبي لسطح المكتب
  Widget _buildDesktopSidebar(BuildContext context, ThemeData theme, bool isDark) {
    final primary = theme.colorScheme.primary;

    // جلب اسم الجيم
    String gymName = 'Sparta Gym';
    final settingsState = context.watch<SettingsCubit>().state;
    if (settingsState is SettingsLoaded) {
      gymName = settingsState.settings.gymName.isNotEmpty
          ? settingsState.settings.gymName
          : 'Sparta Gym';
    }

    // جلب اسم الموظف الحالي
    String employeeName = 'موظف';
    final authState = context.watch<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      employeeName = authState.user.fullName.isNotEmpty
          ? authState.user.fullName
          : authState.user.username;
    }

    final sidebarBg = isDark ? const Color(0xFF161616) : theme.cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _isCollapsed ? 80.0 : 260.0,
      color: sidebarBg,
      child: Column(
        children: [
          // رأس القائمة (Header)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: _isCollapsed
                ? Column(
                    children: [
                      Icon(Icons.fitness_center_rounded, color: primary, size: 32),
                      const SizedBox(height: 16),
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor, size: 16),
                        onPressed: _toggleSidebar,
                        tooltip: 'توسيع القائمة',
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fitness_center_rounded, color: primary, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            gymName,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios_rounded, color: iconColor, size: 16),
                        onPressed: _toggleSidebar,
                        tooltip: 'طي القائمة',
                      ),
                    ],
                  ),
          ),
          Divider(color: dividerColor, height: 1),

          // عناصر الملاحة (Nav Items)
          Expanded(
            child: Scrollbar(
              controller: _sidebarScrollController,
              thumbVisibility: true,
              child: ListView(
                controller: _sidebarScrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  title: 'لوحة التحكم الرئيسية',
                  page: 'home',
                  theme: theme,
                ),
                if (!_isCollapsed)
                  const Padding(
                    padding: EdgeInsets.only(right: 20, top: 16, bottom: 4),
                    child: Text('الأعضاء والاشتراكات', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                if (_isCollapsed) const SizedBox(height: 8),
                _buildNavItem(
                  context: context,
                  icon: Icons.group_rounded,
                  title: 'إدارة الأعضاء والمشتركين',
                  page: 'members',
                  theme: theme,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'الحضور والانصراف',
                  page: 'attendance',
                  theme: theme,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.card_membership_rounded,
                  title: 'باقات الاشتراكات',
                  page: 'memberships',
                  theme: theme,
                ),
                if (!_isCollapsed)
                  const Padding(
                    padding: EdgeInsets.only(right: 20, top: 16, bottom: 4),
                    child: Text('الخدمات والمدربين', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                if (_isCollapsed) const SizedBox(height: 8),
                _buildNavItem(
                  context: context,
                  icon: Icons.sports_gymnastics_rounded,
                  title: 'إدارة المدربين',
                  page: 'trainers',
                  theme: theme,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.fastfood_rounded,
                  title: 'الأنظمة الغذائية',
                  page: 'diets',
                  theme: theme,
                ),
                if (!_isCollapsed)
                  const Padding(
                    padding: EdgeInsets.only(right: 20, top: 16, bottom: 4),
                    child: Text('المالية والمبيعات', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                if (_isCollapsed) const SizedBox(height: 8),
                _buildNavItem(
                  context: context,
                  icon: Icons.point_of_sale_rounded,
                  title: 'نقطة البيع (POS)',
                  page: 'pos',
                  theme: theme,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.payments_rounded,
                  title: 'المدفوعات والمالية',
                  page: 'payments',
                  theme: theme,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'المصروفات',
                  page: 'expenses',
                  theme: theme,
                ),
                if (!_isCollapsed)
                  const Padding(
                    padding: EdgeInsets.only(right: 20, top: 16, bottom: 4),
                    child: Text('أخرى', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                if (_isCollapsed) const SizedBox(height: 8),
                _buildNavItem(
                  context: context,
                  icon: Icons.inventory_2_rounded,
                  title: 'المخزون',
                  page: 'inventory',
                  theme: theme,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.analytics_rounded,
                  title: 'تقرير الشيفت',
                  page: 'reports',
                  theme: theme,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.pie_chart_rounded,
                  title: 'التقارير الشاملة',
                  page: 'comprehensive_reports',
                  theme: theme,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  title: 'إعدادات النظام',
                  page: 'settings',
                  theme: theme,
                ),
              ],
              ),
            ),
          ),
          BlocBuilder<ShiftsCubit, ShiftsState>(
            builder: (context, state) {
              if (state is ShiftsActiveShift) {
                if (_isCollapsed) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: IconButton(
                      icon: const Icon(Icons.stop_circle_rounded, color: Colors.orange),
                      onPressed: () => _showEndShiftDialog(context, context.read<ShiftsCubit>(), state),
                      tooltip: 'إنهاء الشفت (${state.shift.employeeName})',
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: InkWell(
                    onTap: () => _showEndShiftDialog(context, context.read<ShiftsCubit>(), state),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stop_circle_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'إنهاء شفت: ${state.shift.employeeName}',
                              style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Divider(color: dividerColor, height: 1),

          // ذيل القائمة (Switch Employee / Shift)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: _isCollapsed
                ? Tooltip(
                    message: 'تبديل الموظفين والشفتات',
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const ShiftManagementDialog(),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.swap_horiz_rounded, color: primary),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ShiftManagementDialog(),
                      );
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 24),
                    label: const Text('الشفتات والموظفين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: primary.withOpacity(0.1),
                      foregroundColor: primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return GlobalScannerListener(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            // التحقق من عرض الشاشة (Desktop vs Mobile)
            final bool isDesktop = constraints.maxWidth > 850;

            if (isDesktop) {
              return Row(
                children: [
                  // 1. شريط الملاحة الأيمن الثابت
                  _buildDesktopSidebar(context, theme, isDark),

                  // 2. محتوى الصفحة الأيسر
                  Expanded(
                    child: Column(
                      children: [
                        // شريط العنوان العلوي (Topbar)
                        Container(
                          height: 64,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            border: Border(bottom: BorderSide(color: theme.dividerColor)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Row(
                                children: [
                                  if (widget.actions != null) ...widget.actions!,
                                  const SizedBox(width: 8),
                                  // زر تبديل السيم العلوي
                                  IconButton(
                                    icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                                    onPressed: () => context.read<SettingsCubit>().toggleTheme(),
                                    tooltip: isDark ? 'تفعيل الوضع النهاري' : 'تفعيل الوضع الليلي',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // محتوى الصفحة الفعلي
                        Expanded(
                          child: Container(
                            color: isDark ? ColorPalette.backgroundDark : ColorPalette.backgroundLight,
                            child: widget.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // في حال الشاشات الصغيرة (Mobile Layout): نستخدم دراور تقليدي للسلامة المتجاوبة
            return Scaffold(
              drawer: Drawer(
                child: Column(
                  children: [
                    UserAccountsDrawerHeader(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      currentAccountPicture: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.fitness_center_rounded, color: primary, size: 36),
                      ),
                      accountName: BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, state) {
                          String name = 'Sparta Gym';
                          if (state is SettingsLoaded) {
                            name = state.settings.gymName.isNotEmpty ? state.settings.gymName : name;
                          }
                          return Text(name, style: const TextStyle(fontWeight: FontWeight.bold));
                        },
                      ),
                      accountEmail: BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          String emp = 'موظف';
                          if (state is AuthAuthenticated) {
                            emp = state.user.fullName.isNotEmpty ? state.user.fullName : state.user.username;
                          }
                          return Text('الموظف: $emp');
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.dashboard_rounded),
                            title: const Text('لوحة التحكم الرئيسية'),
                            selected: widget.activePage == 'home',
                            onTap: () => _navigateTo(context, 'home'),
                          ),
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('الأعضاء والاشتراكات', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          ListTile(
                            leading: const Icon(Icons.group_rounded),
                            title: const Text('إدارة الأعضاء والمشتركين'),
                            selected: widget.activePage == 'members',
                            onTap: () => _navigateTo(context, 'members'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.qr_code_scanner_rounded),
                            title: const Text('الحضور والانصراف'),
                            selected: widget.activePage == 'attendance',
                            onTap: () => _navigateTo(context, 'attendance'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.card_membership_rounded),
                            title: const Text('باقات الاشتراكات'),
                            selected: widget.activePage == 'memberships',
                            onTap: () => _navigateTo(context, 'memberships'),
                          ),
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('الخدمات والمدربين', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          ListTile(
                            leading: const Icon(Icons.sports_gymnastics_rounded),
                            title: const Text('إدارة المدربين'),
                            selected: widget.activePage == 'trainers',
                            onTap: () => _navigateTo(context, 'trainers'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.fastfood_rounded),
                            title: const Text('الأنظمة الغذائية'),
                            selected: widget.activePage == 'diets',
                            onTap: () => _navigateTo(context, 'diets'),
                          ),
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('المالية والمبيعات', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          ListTile(
                            leading: const Icon(Icons.point_of_sale_rounded),
                            title: const Text('نقطة البيع (POS)'),
                            selected: widget.activePage == 'pos',
                            onTap: () => _navigateTo(context, 'pos'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.payments_rounded),
                            title: const Text('المدفوعات والمالية'),
                            selected: widget.activePage == 'payments',
                            onTap: () => _navigateTo(context, 'payments'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.account_balance_wallet_rounded),
                            title: const Text('المصروفات'),
                            selected: widget.activePage == 'expenses',
                            onTap: () => _navigateTo(context, 'expenses'),
                          ),
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('أخرى', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          ListTile(
                            leading: const Icon(Icons.inventory_2_rounded),
                            title: const Text('المخزون'),
                            selected: widget.activePage == 'inventory',
                            onTap: () => _navigateTo(context, 'inventory'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.analytics_rounded),
                            title: const Text('تقرير الشيفت'),
                            selected: widget.activePage == 'reports',
                            onTap: () => _navigateTo(context, 'reports'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.pie_chart_rounded),
                            title: const Text('التقارير الشاملة'),
                            selected: widget.activePage == 'comprehensive_reports',
                            onTap: () => _navigateTo(context, 'comprehensive_reports'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.settings_rounded),
                            title: const Text('إعدادات النظام'),
                            selected: widget.activePage == 'settings',
                            onTap: () => _navigateTo(context, 'settings'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    BlocBuilder<ShiftsCubit, ShiftsState>(
                      builder: (context, state) {
                        if (state is ShiftsActiveShift) {
                          return ListTile(
                            leading: const Icon(Icons.stop_circle_rounded, color: Colors.orange),
                            title: const Text('إنهاء الشفت', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                            subtitle: Text('الموظف: ${state.shift.employeeName}', style: const TextStyle(fontSize: 10, color: Colors.orange)),
                            onTap: () => _showEndShiftDialog(context, context.read<ShiftsCubit>(), state),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    BlocBuilder<ShiftsCubit, ShiftsState>(
                      builder: (context, state) {
                        return ListTile(
                          leading: const Icon(Icons.swap_horiz_rounded, color: Colors.orange),
                          title: const Text('الشفتات والموظفين', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          onTap: () {
                            Navigator.pop(context); // close drawer
                            showDialog(
                              context: context,
                              builder: (_) => const ShiftManagementDialog(),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              appBar: AppBar(
                title: Text(widget.title),
                actions: [
                  if (widget.actions != null) ...widget.actions!,
                  IconButton(
                    icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                    onPressed: () => context.read<SettingsCubit>().toggleTheme(),
                  ),
                ],
              ),
              body: Container(
                color: isDark ? ColorPalette.backgroundDark : ColorPalette.backgroundLight,
                child: widget.body,
              ),
            );
          },
        ),
        ),
      ),
    );
  }
}
