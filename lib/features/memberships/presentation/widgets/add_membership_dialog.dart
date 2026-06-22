import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/membership_entity.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// ديالوج إضافة / تعديل باقة اشتراك (Add / Edit Membership Dialog)
/// ──────────────────────────────────────────────────────────────────────────────
class AddMembershipDialog extends StatefulWidget {
  final Membership? membership;
  final Function(Membership) onSave;

  const AddMembershipDialog({
    super.key,
    this.membership,
    required this.onSave,
  });

  @override
  State<AddMembershipDialog> createState() => _AddMembershipDialogState();
}

class _AddMembershipDialogState extends State<AddMembershipDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _durationDaysCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _freezeDaysCtrl;
  late final TextEditingController _visitsLimitCtrl;

  bool _isLimitedVisits = false;
  bool _isActive = true;

  bool get _isEditing => widget.membership != null;

  @override
  void initState() {
    super.initState();
    final m = widget.membership;

    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _durationDaysCtrl = TextEditingController(text: m?.durationDays.toString() ?? '30');
    _priceCtrl = TextEditingController(text: m != null ? m.price.toStringAsFixed(0) : '');
    _freezeDaysCtrl = TextEditingController(text: m?.freezeDays.toString() ?? '0');
    _visitsLimitCtrl = TextEditingController(
      text: m?.visitsLimit != null ? m!.visitsLimit.toString() : '',
    );

    _isLimitedVisits = m?.visitsLimit != null;
    _isActive = m?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _durationDaysCtrl.dispose();
    _priceCtrl.dispose();
    _freezeDaysCtrl.dispose();
    _visitsLimitCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final membership = Membership(
      id: widget.membership?.id,
      name: _nameCtrl.text.trim(),
      durationDays: int.tryParse(_durationDaysCtrl.text) ?? 30,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      freezeDays: int.tryParse(_freezeDaysCtrl.text) ?? 0,
      visitsLimit: _isLimitedVisits ? (int.tryParse(_visitsLimitCtrl.text) ?? 0) : null,
      isActive: _isActive,
      createdAt: widget.membership?.createdAt ?? DateTime.now().toIso8601String(),
    );

    widget.onSave(membership);
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
          width: 500,
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
                      Icon(Icons.card_membership_rounded, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        _isEditing ? 'تعديل باقة الاشتراك' : 'إضافة باقة جديدة',
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

                  // اسم الباقة
                  _buildTextField(
                    controller: _nameCtrl,
                    label: 'اسم الباقة *',
                    icon: Icons.edit_note,
                    validator: (v) => v == null || v.trim().isEmpty ? 'الرجاء إدخال اسم الباقة' : null,
                  ),
                  const SizedBox(height: 16),

                  // مدة الاشتراك والسعر في صف واحد
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _durationDaysCtrl,
                          label: 'مدة الاشتراك (بالأيام) *',
                          icon: Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => v == null || v.trim().isEmpty ? 'الرجاء إدخال المدة' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _priceCtrl,
                          label: 'سعر الاشتراك *',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => v == null || v.trim().isEmpty ? 'الرجاء إدخال السعر' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // أيام التجميد
                  _buildTextField(
                    controller: _freezeDaysCtrl,
                    label: 'أيام التجميد المسموح بها',
                    icon: Icons.ac_unit,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),

                  // باقة بالحصة / محدودة الزيارات
                  CheckboxListTile(
                    title: const Text('باقة بالحصة (تحديد عدد الزيارات / التمارين)'),
                    subtitle: const Text('قم بتفعيل هذا الخيار لإنشاء باقة تحاسب بالحصة (مثال: 1 لتمرينة واحدة، أو 10 لـ 10 حصص).'),
                    value: _isLimitedVisits,
                    activeColor: ColorPalette.primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() {
                        _isLimitedVisits = val ?? false;
                        if (_isLimitedVisits && _visitsLimitCtrl.text.isEmpty) {
                          _visitsLimitCtrl.text = '1'; // Default to 1 session
                        }
                      });
                    },
                  ),
                  if (_isLimitedVisits) ...[
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _visitsLimitCtrl,
                      label: 'عدد الزيارات / الحصص المسموح بها *',
                      icon: Icons.filter_9_plus_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => _isLimitedVisits && (v == null || v.trim().isEmpty)
                          ? 'الرجاء إدخال عدد الزيارات'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // حالة الباقة
                  DropdownButtonFormField<bool>(
                    value: _isActive,
                    decoration: InputDecoration(
                      labelText: 'حالة الباقة',
                      prefixIcon: const Icon(Icons.toggle_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('نشطة')),
                      DropdownMenuItem(value: false, child: Text('موقوفة')),
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
                      ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('حفظ الباقة'),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
