import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../core/theme/color_palette.dart';
import '../../../../core/common/widgets/sidebar_layout.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _registerCtrl;
  String _dbPath = 'جاري التحميل...';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _registerCtrl = TextEditingController();

    // تحميل الإعدادات ومسار قاعدة البيانات
    context.read<SettingsCubit>().loadSettings();
    _getDatabasePath();
  }

  Future<void> _getDatabasePath() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      setState(() {
        _dbPath = p.join(appDocDir.path, 'SpartaGym', 'sparta_gym.db');
      });
    } catch (e) {
      setState(() {
        _dbPath = 'تعذر الحصول على المسار: $e';
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _registerCtrl.dispose();
    super.dispose();
  }

  void _save(SettingsLoaded state) {
    if (!_formKey.currentState!.validate()) return;

    context.read<SettingsCubit>().saveGymInfo(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          register: _registerCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SidebarLayout(
      activePage: 'settings',
      title: 'إعدادات النظام',
      body: BlocConsumer<SettingsCubit, SettingsState>(
          listener: (context, state) {
            if (state is SettingsLoaded) {
              if (state.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message!,
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    backgroundColor: ColorPalette.successColor,
                  ),
                );
              }
              // ملء الحقول بالبيانات المحملة
              _nameCtrl.text = state.settings.gymName;
              _phoneCtrl.text = state.settings.gymPhone;
              _addressCtrl.text = state.settings.gymAddress;
              _registerCtrl.text = state.settings.commercialRegister;
            } else if (state is SettingsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  backgroundColor: ColorPalette.errorColor,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SettingsLoading || state is SettingsInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SettingsLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. كارت بيانات الجيم
                          _buildSectionHeader('بيانات الجيم الأساسية', Icons.business),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _nameCtrl,
                                          label: 'اسم الجيم *',
                                          icon: Icons.fitness_center,
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _phoneCtrl,
                                          label: 'رقم الهاتف',
                                          icon: Icons.phone,
                                          keyboardType: TextInputType.phone,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _addressCtrl,
                                          label: 'العنوان',
                                          icon: Icons.location_on,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _registerCtrl,
                                          label: 'السجل التجاري',
                                          icon: Icons.app_registration,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _save(state),
                                      icon: const Icon(Icons.save, color: Colors.white),
                                      label: const Text('حفظ التغييرات'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ColorPalette.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 2. كارت المظهر والوضع الليلي
                          _buildSectionHeader('مظهر التطبيق (Theme)', Icons.palette),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الوضع الحالي: ${state.settings.themeMode == 'light' ? 'الوضع النهاري' : 'الوضع الليلي'}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'تبديل مظهر واجهة النظام بالكامل للوضع المناسب لك.',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.read<SettingsCubit>().toggleTheme();
                                    },
                                    icon: Icon(
                                      state.settings.themeMode == 'light'
                                          ? Icons.dark_mode
                                          : Icons.light_mode,
                                    ),
                                    label: Text(
                                      state.settings.themeMode == 'light'
                                          ? 'تفعيل الوضع الليلي'
                                          : 'تفعيل الوضع النهاري',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: state.settings.themeMode == 'light'
                                          ? ColorPalette.secondaryColor
                                          : Colors.white,
                                      foregroundColor: state.settings.themeMode == 'light'
                                          ? Colors.white
                                          : Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 3. كارت قاعدة البيانات والنسخ الاحتياطي
                          _buildSectionHeader('موقع قاعدة البيانات المحلية', Icons.storage),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: ColorPalette.infoColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'يتم تخزين كافة بيانات المشتركين والمدفوعات محلياً في هذا المسار. يمكنك نسخ الملف يدوياً لعمل نسخ احتياطي.',
                                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          readOnly: true,
                                          initialValue: _dbPath,
                                          key: ValueKey(_dbPath),
                                          decoration: InputDecoration(
                                            labelText: 'مسار ملف قاعدة البيانات',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        height: 54,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: _dbPath));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('تم نسخ مسار قاعدة البيانات بنجاح!'),
                                                backgroundColor: ColorPalette.infoColor,
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.copy),
                                          label: const Text('نسخ المسار'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: ColorPalette.infoColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
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
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
      );
    }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: ColorPalette.primaryColor, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.primaryColor, width: 2),
        ),
      ),
    );
  }
}
