import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/trainer_entity.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// ديالوج إضافة / تعديل مدرب (Add / Edit Trainer Dialog)
/// ──────────────────────────────────────────────────────────────────────────────
class AddTrainerDialog extends StatefulWidget {
  final Trainer? trainer;
  final Function(Trainer) onSave;

  const AddTrainerDialog({
    super.key,
    this.trainer,
    required this.onSave,
  });

  @override
  State<AddTrainerDialog> createState() => _AddTrainerDialogState();
}

class _AddTrainerDialogState extends State<AddTrainerDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _notesCtrl;

  bool _isActive = true;

  bool get _isEditing => widget.trainer != null;

  @override
  void initState() {
    super.initState();
    final t = widget.trainer;

    _nameCtrl = TextEditingController(text: t?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: t?.phoneNumber ?? '');
    _specCtrl = TextEditingController(text: t?.specialization ?? '');
    _salaryCtrl = TextEditingController(
      text: t?.salary != null ? t!.salary!.toStringAsFixed(0) : '',
    );
    _hoursCtrl = TextEditingController(text: t?.workingHours ?? '');
    _notesCtrl = TextEditingController(text: t?.notes ?? '');

    _isActive = t?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _specCtrl.dispose();
    _salaryCtrl.dispose();
    _hoursCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final trainer = Trainer(
      id: widget.trainer?.id,
      fullName: _nameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      specialization: _specCtrl.text.trim().isEmpty ? null : _specCtrl.text.trim(),
      salary: _salaryCtrl.text.trim().isNotEmpty
          ? double.tryParse(_salaryCtrl.text.trim())
          : null,
      workingHours: _hoursCtrl.text.trim().isEmpty ? null : _hoursCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      isActive: _isActive,
      createdAt: widget.trainer?.createdAt ?? DateTime.now().toIso8601String(),
    );

    widget.onSave(trainer);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان
                  Row(
                    children: [
                      Icon(Icons.sports_gymnastics_rounded, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        _isEditing ? 'تعديل بيانات المدرب' : 'إضافة مدرب جديد',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // اسم المدرب ورقم الهاتف
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _nameCtrl,
                          label: 'اسم المدرب *',
                          icon: Icons.person,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'الرجاء إدخال اسم المدرب' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _phoneCtrl,
                          label: 'رقم الهاتف *',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'الرجاء إدخال رقم الهاتف' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // التخصص والراتب
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _specCtrl,
                          label: 'التخصص',
                          icon: Icons.category_rounded,
                          hintText: 'مثال: كمال أجسام، كارديو، لياقة',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _salaryCtrl,
                          label: 'الراتب',
                          icon: Icons.monetization_on_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ساعات العمل
                  _buildTextField(
                    controller: _hoursCtrl,
                    label: 'ساعات العمل',
                    icon: Icons.access_time_rounded,
                    hintText: 'مثال: من 8 صباحاً حتى 4 مساءً',
                  ),
                  const SizedBox(height: 16),

                  // ملاحظات
                  _buildTextField(
                    controller: _notesCtrl,
                    label: 'ملاحظات',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // حالة المدرب
                  DropdownButtonFormField<bool>(
                    value: _isActive,
                    decoration: InputDecoration(
                      labelText: 'حالة المدرب',
                      prefixIcon: const Icon(Icons.toggle_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('نشط')),
                      DropdownMenuItem(value: false, child: Text('غير نشط')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _isActive = val);
                    },
                  ),
                  const SizedBox(height: 24),

                  // أزرار الحفظ والإلغاء
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _save,
                        icon: Icon(_isEditing ? Icons.save : Icons.add, color: Colors.white),
                        label: Text(_isEditing ? 'حفظ التعديلات' : 'إضافة المدرب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? hintText,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
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
