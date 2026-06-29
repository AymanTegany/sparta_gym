import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/discount_code.dart';

class AddDiscountCodeDialog extends StatefulWidget {
  final DiscountCode? discountCode;
  final Function(DiscountCode) onSave;

  const AddDiscountCodeDialog({
    super.key,
    this.discountCode,
    required this.onSave,
  });

  @override
  State<AddDiscountCodeDialog> createState() => _AddDiscountCodeDialogState();
}

class _AddDiscountCodeDialogState extends State<AddDiscountCodeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _valueController;
  String _type = 'fixed';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.discountCode?.name ?? '');
    _valueController = TextEditingController(
        text: widget.discountCode != null ? widget.discountCode!.value.toStringAsFixed(0) : '');
    _type = widget.discountCode?.type ?? 'fixed';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final code = DiscountCode(
        id: widget.discountCode?.id,
        name: _nameController.text.trim(),
        type: _type,
        value: double.parse(_valueController.text.trim()),
        createdAt: widget.discountCode?.createdAt ?? DateTime.now().toIso8601String(),
      );
      widget.onSave(code);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.discountCode != null;
    return AlertDialog(
      title: Text(isEdit ? 'تعديل كود خصم' : 'إضافة كود خصم جديد'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم كود الخصم',
                  hintText: 'مثل: خصم العيد، خصم 10%',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.abc),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم الكود';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'نوع الخصم',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                ),
                items: const [
                  DropdownMenuItem(value: 'fixed', child: Text('مبلغ ثابت (ج.م)')),
                  DropdownMenuItem(value: 'percentage', child: Text('نسبة مئوية (%)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _type = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'القيمة',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.money),
                  suffixText: _type == 'fixed' ? 'ج.م' : '%',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال القيمة';
                  }
                  final doubleValue = double.tryParse(value);
                  if (doubleValue == null) {
                    return 'قيمة غير صالحة';
                  }
                  if (_type == 'percentage' && doubleValue > 100) {
                    return 'النسبة لا يمكن أن تتجاوز 100%';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
