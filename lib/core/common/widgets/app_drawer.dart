import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../../features/shifts/presentation/cubit/shifts_cubit.dart';
import '../../../features/shifts/presentation/cubit/shifts_cubit.dart';
import '../../../features/shifts/presentation/cubit/shifts_state.dart';
import '../../../features/shifts/presentation/widgets/end_shift_dialog.dart';
import '../../../features/shifts/presentation/widgets/shift_management_dialog.dart';
import '../../../features/auth/presentation/cubit/auth_cubit.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// قائمة ملاحة جانبية موحدة للنظام (AppDrawer)
/// ──────────────────────────────────────────────────────────────────────────────
class AppDrawer extends StatelessWidget {
  final String activePage;

  const AppDrawer({super.key, required this.activePage});

  void _navigateTo(BuildContext context, String page) {
    if (activePage == page) {
      Navigator.pop(context);
      return;
    }

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
      default:
        return;
    }

    // إغلاق الدروار ثم فتح الصفحة الجديدة بالاستبدال
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetPage),
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
              Navigator.pop(context); // إغلاق الدروار
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
  }

  void _switchShift(BuildContext context) {
    Navigator.pop(context); // إغلاق الدروار أولاً
    showDialog(
      context: context,
      builder: (_) => const ShiftManagementDialog(),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Color? selectedColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? (selectedColor ?? ColorPalette.primaryColor) : Colors.grey,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? (selectedColor ?? ColorPalette.primaryColor) : null,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // جلب اسم الجيم من إعدادات الجيم
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        child: Column(
          children: [
            // هيدر القائمة الجانبية بشكل جذاب ورياضي
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: Icon(Icons.fitness_center_rounded, color: primary, size: 36),
              ),
              accountName: Text(
                gymName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              accountEmail: Text(
                'الموظف: $employeeName',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
              ),
            ),

            // قائمة عناصر الملاحة
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'لوحة التحكم الرئيسيّة',
                    isSelected: activePage == 'home',
                    onTap: () => _navigateTo(context, 'home'),
                  ),
                  const Divider(height: 16),
                  _buildDrawerItem(
                    icon: Icons.group_rounded,
                    title: 'إدارة الأعضاء والمشتركين',
                    isSelected: activePage == 'members',
                    onTap: () => _navigateTo(context, 'members'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'تسجيل الحضور والانصراف',
                    isSelected: activePage == 'attendance',
                    onTap: () => _navigateTo(context, 'attendance'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.card_membership_rounded,
                    title: 'إدارة باقات الاشتراكات',
                    isSelected: activePage == 'memberships',
                    onTap: () => _navigateTo(context, 'memberships'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.payments_rounded,
                    title: 'إدارة المدفوعات والمالية',
                    isSelected: activePage == 'payments',
                    onTap: () => _navigateTo(context, 'payments'),
                  ),
                  const Divider(height: 16),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'إعدادات النظام',
                    isSelected: activePage == 'settings',
                    onTap: () => _navigateTo(context, 'settings'),
                  ),
                ],
              ),
            ),

            // زر تسجيل الخروج في ذيل القائمة
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildDrawerItem(
                icon: Icons.swap_horiz_rounded,
                title: 'الشفتات والموظفين',
                isSelected: false,
                onTap: () => _switchShift(context),
                selectedColor: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
