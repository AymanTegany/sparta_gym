import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:updat/updat.dart';
import '../../../../core/services/github_update_service.dart';
import '../../../../core/common/widgets/arabic_update_builders.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/common/widgets/sidebar_layout.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

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
  late final TextEditingController _whatsappAccessTokenCtrl;
  late final TextEditingController _whatsappPhoneNumberIdCtrl;
  String _dbPath = 'جاري التحميل...';
  String? _selectedLogoPath;
  List<Printer> _availablePrinters = [];
  bool _isLoadingPrinters = false;
  String? _selectedPrinter;

  String _currentAppVersion = 'جاري التحميل...';
  String _latestAppVersion = 'جاري التحميل...';
  bool _isCheckingUpdate = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _registerCtrl = TextEditingController();
    _whatsappAccessTokenCtrl = TextEditingController();
    _whatsappPhoneNumberIdCtrl = TextEditingController();

    // تحميل الإعدادات ومسار قاعدة البيانات
    context.read<SettingsCubit>().loadSettings();
    _getDatabasePath();
    _loadAvailablePrinters();
    _checkUpdateInfo();
  }

  Future<void> _checkUpdateInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final updateService = GithubUpdateService(
        owner: 'AymanTegany',
        repo: 'sparta_gym',
      );
      final latestVersion = await updateService.getLatestVersion();

      if (mounted) {
        setState(() {
          _currentAppVersion = currentVersion;
          _latestAppVersion = latestVersion.isEmpty
              ? 'غير متوفر'
              : latestVersion;
          _isCheckingUpdate = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAppVersion = 'خطأ';
          _latestAppVersion = 'خطأ';
          _isCheckingUpdate = false;
        });
      }
    }
  }

  Future<void> _loadAvailablePrinters() async {
    setState(() {
      _isLoadingPrinters = true;
    });
    try {
      final printers = await Printing.listPrinters();
      setState(() {
        _availablePrinters = printers;
        _isLoadingPrinters = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPrinters = false;
      });
      debugPrint('Error listing printers: $e');
    }
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
    _whatsappAccessTokenCtrl.dispose();
    _whatsappPhoneNumberIdCtrl.dispose();
    super.dispose();
  }

  void _save(SettingsLoaded state) {
    if (!_formKey.currentState!.validate()) return;

    context.read<SettingsCubit>().saveGymInfo(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      register: _registerCtrl.text.trim(),
      logoPath: _selectedLogoPath,
      defaultA4Printer: _selectedPrinter,
      whatsappAccessToken: _whatsappAccessTokenCtrl.text.trim(),
      whatsappPhoneNumberId: _whatsappPhoneNumberIdCtrl.text.trim(),
    );
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedLogoPath = result.files.single.path;
      });
    }
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
            _whatsappAccessTokenCtrl.text = state.settings.whatsappAccessToken;
            _whatsappPhoneNumberIdCtrl.text = state.settings.whatsappPhoneNumberId;
            if (_selectedLogoPath == null &&
                state.settings.logoPath.isNotEmpty) {
              _selectedLogoPath = state.settings.logoPath;
            }
            _selectedPrinter = state.settings.defaultA4Printer.isEmpty
                ? null
                : state.settings.defaultA4Printer;
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
                        _buildSectionHeader(
                          'بيانات الجيم الأساسية',
                          Icons.business,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Logo picker
                                    GestureDetector(
                                      onTap: _pickLogo,
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: ColorPalette.primaryColor
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child:
                                            _selectedLogoPath != null &&
                                                _selectedLogoPath!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.file(
                                                  File(_selectedLogoPath!),
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : const Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.add_a_photo,
                                                    color: ColorPalette
                                                        .primaryColor,
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'شعار الجيم',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
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
                                                      (v == null ||
                                                          v.trim().isEmpty)
                                                      ? 'الاسم مطلوب'
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _buildTextField(
                                                  controller: _phoneCtrl,
                                                  label: 'رقم الهاتف',
                                                  icon: Icons.phone,
                                                  keyboardType:
                                                      TextInputType.phone,
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
                                        ],
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
                                    icon: const Icon(
                                      Icons.save,
                                      color: Colors.white,
                                    ),
                                    label: const Text('حفظ التغييرات'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          ColorPalette.primaryColor,
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

                        // 2. كارت إعدادات الطباعة
                        _buildSectionHeader(
                          'إعدادات الطباعة (Printer Settings)',
                          Icons.print,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'الطابعة الافتراضية للفواتير (A4)',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'حدد الطابعة التي سيتم إرسال الفواتير إليها مباشرة دون الحاجة لاختيارها في كل مرة.',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      onPressed: _loadAvailablePrinters,
                                      icon: _isLoadingPrinters
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.refresh),
                                      tooltip: 'تحديث قائمة الطابعات',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                if (_isLoadingPrinters)
                                  const LinearProgressIndicator()
                                else if (_availablePrinters.isEmpty &&
                                    (_selectedPrinter == null ||
                                        _selectedPrinter!.isEmpty))
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: ColorPalette.warningColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'لم يتم العثور على طابعات متصلة بالنظام. يرجى التحقق من التوصيل وإعادة المحاولة.',
                                          style: TextStyle(
                                            color: theme.colorScheme.error,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  DropdownButtonFormField<String>(
                                    value:
                                        (_selectedPrinter == null ||
                                            _selectedPrinter!.isEmpty)
                                        ? ''
                                        : _selectedPrinter,
                                    hint: const Text(
                                      'اختر الطابعة الافتراضية من القائمة',
                                      style: TextStyle(fontFamily: 'Cairo'),
                                    ),
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.print_outlined,
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: '',
                                        child: Text(
                                          'لا توجد طابعة افتراضية (عرض معاينة الفاتورة قبل الطباعة)',
                                          style: TextStyle(fontFamily: 'Cairo'),
                                        ),
                                      ),
                                      if (_selectedPrinter != null &&
                                          _selectedPrinter!.isNotEmpty &&
                                          !_availablePrinters.any(
                                            (p) => p.name == _selectedPrinter,
                                          ))
                                        DropdownMenuItem<String>(
                                          value: _selectedPrinter,
                                          child: Text(
                                            '$_selectedPrinter (غير متصلة حالياً)',
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),
                                      ..._availablePrinters.map((printer) {
                                        return DropdownMenuItem<String>(
                                          value: printer.name,
                                          child: Text(
                                            printer.name,
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPrinter = value;
                                      });
                                      context.read<SettingsCubit>().saveGymInfo(
                                        name: _nameCtrl.text.trim(),
                                        phone: _phoneCtrl.text.trim(),
                                        address: _addressCtrl.text.trim(),
                                        register: _registerCtrl.text.trim(),
                                        logoPath: _selectedLogoPath,
                                        defaultA4Printer: value,
                                        whatsappAccessToken: _whatsappAccessTokenCtrl.text.trim(),
                                        whatsappPhoneNumberId: _whatsappPhoneNumberIdCtrl.text.trim(),
                                      );
                                    },
                                  ),
                                if (_selectedPrinter != null &&
                                    _selectedPrinter!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: ColorPalette.successColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'سيتم إرسال الفاتورة تلقائياً إلى: $_selectedPrinter',
                                        style: const TextStyle(
                                          color: ColorPalette.successColor,
                                          fontSize: 13,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 2. كارت المظهر والوضع الليلي
                        _buildSectionHeader(
                          'مظهر التطبيق (Theme)',
                          Icons.palette,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الوضع الحالي: ${state.settings.themeMode == 'light' ? 'الوضع النهاري' : 'الوضع الليلي'}',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
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
                                    backgroundColor:
                                        state.settings.themeMode == 'light'
                                        ? ColorPalette.secondaryColor
                                        : Colors.white,
                                    foregroundColor:
                                        state.settings.themeMode == 'light'
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

                        // كارت إعدادات ربط واتساب API
                        _buildSectionHeader(
                          'ربط واتساب (WhatsApp API)',
                          Icons.chat_bubble_outline,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: ColorPalette.infoColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'أدخل بيانات WhatsApp Cloud API لإرسال الرسائل التلقائية للعملاء. إذا تركتها فارغة سيتم تحويلك إلى تطبيق واتساب للإرسال اليدوي.',
                                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _whatsappAccessTokenCtrl,
                                  label: 'Access Token',
                                  icon: Icons.key,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _whatsappPhoneNumberIdCtrl,
                                  label: 'Phone Number ID',
                                  icon: Icons.phone_android,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _save(state),
                                    icon: const Icon(
                                      Icons.save,
                                      color: Colors.white,
                                    ),
                                    label: const Text('حفظ إعدادات واتساب'),
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

                        // 3. كارت قاعدة البيانات والنسخ الاحتياطي
                        _buildSectionHeader(
                          'موقع قاعدة البيانات المحلية',
                          Icons.storage,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: ColorPalette.infoColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'يتم تخزين كافة بيانات المشتركين والمدفوعات محلياً في هذا المسار. يمكنك نسخ الملف يدوياً لعمل نسخ احتياطي.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(height: 1.4),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      height: 54,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(text: _dbPath),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'تم نسخ مسار قاعدة البيانات بنجاح!',
                                              ),
                                              backgroundColor:
                                                  ColorPalette.infoColor,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.copy),
                                        label: const Text('نسخ المسار'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              ColorPalette.infoColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                        const SizedBox(height: 32),

                        // 4. كارت التحديث
                        _buildSectionHeader(
                          'تحديث النظام',
                          Icons.system_update,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الإصدار الحالي: $_currentAppVersion',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'آخر إصدار متاح: $_latestAppVersion',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (_isCheckingUpdate)
                                  const CircularProgressIndicator()
                                else if (_currentAppVersion ==
                                        _latestAppVersion ||
                                    _latestAppVersion == 'غير متوفر' ||
                                    _latestAppVersion == 'خطأ')
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: ColorPalette.successColor,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'التطبيق محدث',
                                        style: TextStyle(
                                          color: ColorPalette.successColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  UpdatWidget(
                                    currentVersion: _currentAppVersion,
                                    getLatestVersion: () async {
                                      return _latestAppVersion;
                                    },
                                    getBinaryUrl: (version) async {
                                      return await GithubUpdateService(
                                        owner: 'AymanTegany',
                                        repo: 'sparta_gym',
                                      ).getBinaryUrl(version);
                                    },
                                    appName: 'Sparta Gym',
                                    updateChipBuilder: buildArabicUpdateChip,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 5. كارت تسجيل الخروج
                        _buildSectionHeader('تسجيل الخروج', Icons.logout),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تسجيل الخروج من النظام',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'تسجيل الخروج كمسؤول والعودة لشاشة الدخول الرئيسية.',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _showLogoutDialog(context);
                                  },
                                  icon: const Icon(
                                    Icons.logout,
                                    color: Colors.white,
                                  ),
                                  label: const Text('تسجيل الخروج'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
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
          borderSide: const BorderSide(
            color: ColorPalette.primaryColor,
            width: 2,
          ),
        ),
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
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamedAndRemoveUntil('/', (route) => false);
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
}
