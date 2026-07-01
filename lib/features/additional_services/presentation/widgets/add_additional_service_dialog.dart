import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/additional_service.dart';

class AddAdditionalServiceDialog extends StatefulWidget {
  final AdditionalService? service;
  final Function(AdditionalService) onSave;

  const AddAdditionalServiceDialog({super.key, this.service, required this.onSave});

  @override
  State<AddAdditionalServiceDialog> createState() => _AddAdditionalServiceDialogState();
}

class _AddAdditionalServiceDialogState extends State<AddAdditionalServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _visitsCtrl;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?.name ?? '');
    _priceCtrl = TextEditingController(
        text: widget.service != null ? widget.service!.monthlyPrice.toStringAsFixed(0) : '');
    _visitsCtrl = TextEditingController(
        text: widget.service != null ? widget.service!.visitsLimit.toString() : '');
    _isActive = widget.service?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _visitsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _nameCtrl.text.trim();
      final price = double.tryParse(_priceCtrl.text) ?? 0.0;
      final visits = int.tryParse(_visitsCtrl.text) ?? 0;

      final newService = AdditionalService(
        id: widget.service?.id,
        name: name,
        monthlyPrice: price,
        visitsLimit: visits,
        isActive: _isActive,
        createdAt: widget.service?.createdAt ?? DateTime.now().toIso8601String(),
      );

      widget.onSave(newService);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.service != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit : Icons.add,
                      color: ColorPalette.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    isEditing ? 'تعديل خدمة إضافية' : 'إضافة خدمة إضافية',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'اسم الخدمة (مثل: ساونا، جاكوزي)',
                  prefixIcon: const Icon(Icons.spa_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              
              // Price and Visits
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'السعر الشهري',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'مطلوب';
                        if (double.tryParse(value) == null) return 'رقم غير صالح';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _visitsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'عدد مرات الدخول',
                        prefixIcon: const Icon(Icons.confirmation_number_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'مطلوب';
                        if (int.tryParse(value) == null) return 'رقم غير صالح';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Is Active
              SwitchListTile(
                title: const Text('نشط'),
                subtitle: const Text('هل الخدمة متاحة حالياً للاشتراك؟'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                activeColor: ColorPalette.primaryColor,
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
