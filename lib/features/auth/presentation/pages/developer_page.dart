import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sparta_gym/core/services/license_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sparta_gym/features/auth/presentation/cubit/auth_cubit.dart';

class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  final _deviceIdCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  int _selectedDays = 30;
  String _generatedKey = '';
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _initDeviceId();
  }

  Future<void> _initDeviceId() async {
    final id = await context.read<AuthCubit>().getDeviceId();
    setState(() => _deviceIdCtrl.text = id);
  }

  void _generate() {
    if (_deviceIdCtrl.text.trim().isEmpty) return;
    final key = LicenseService.generateLicense(
      _deviceIdCtrl.text.trim(),
      _selectedDays,
    );
    setState(() => _generatedKey = key);
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _generatedKey));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ الكرت بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (!_isUnlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('دخول المبرمج')),
        body: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('أدخل كلمة مرور المبرمج للمتابعة'),
                const SizedBox(height: 20),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _checkPass(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _checkPass,
                  child: const Text('دخول'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المبرمج - إنشاء كروت الاشتراك'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _deviceIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'معرف الجهاز (Device ID)',
                    prefixIcon: Icon(Icons.important_devices),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'مدة الاشتراك:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: _selectedDays,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 14, child: Text('14 يوم (تجريبي)')),
                    DropdownMenuItem(value: 30, child: Text('شهر (30 يوم)')),
                    DropdownMenuItem(value: 90, child: Text('3 أشهر')),
                    DropdownMenuItem(value: 180, child: Text('6 أشهر')),
                    DropdownMenuItem(value: 365, child: Text('سنة (365 يوم)')),
                    DropdownMenuItem(value: 3650, child: Text('مدى الحياة')),
                  ],
                  onChanged: (v) => setState(() => _selectedDays = v!),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _generate,
                    child: const Text('إنشاء كرت اشتراك'),
                  ),
                ),
                if (_generatedKey.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  const Text(
                    'الكرت الناتج:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        SelectableText(
                          _generatedKey,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _copy,
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('نسخ الكود'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkPass() {
    if (_passCtrl.text == '01030731218') {
      setState(() => _isUnlocked = true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('كلمة المرور غير صحيحة')));
    }
  }
}
