import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/color_palette.dart';
import '../../../members/domain/entities/member_entity.dart';
import '../../../members/presentation/cubit/members_cubit.dart';
import '../../../members/presentation/cubit/members_state.dart';
import '../cubit/payments_cubit.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/auth/presentation/cubit/auth_state.dart';

class AddPaymentDialog extends StatefulWidget {
  final Member? member;

  const AddPaymentDialog({super.key, this.member});

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  Member? _selectedMember;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  String _paymentMethod = 'نقدي';

  final List<String> _methods = [
    'نقدي',
    'فودافون كاش',
    'إنستاباي',
    'تحويل بنكي',
    'بطاقة',
  ];

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _notesCtrl = TextEditingController();

    if (widget.member != null) {
      _selectedMember = widget.member;
      _amountCtrl.text = widget.member!.remainingAmount.toStringAsFixed(0);
    } else {
      // تحميل الأعضاء للتمكن من البحث واختيار العضو
      context.read<MembersCubit>().loadMembers();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'ar').format(amount);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMember == null) return;

    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (amount <= 0) return;

    // الحصول على اسم الموظف الحالي
    String employeeName = 'موظف';
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      employeeName = authState.user.fullName.isNotEmpty
          ? authState.user.fullName
          : authState.user.username;
    }

    context.read<PaymentsCubit>().recordPayment(
          memberId: _selectedMember!.memberId,
          amount: amount,
          paymentMethod: _paymentMethod,
          employeeName: employeeName,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );

    // تحديث قائمة الأعضاء لكي تظهر الأرصدة الجديدة
    context.read<MembersCubit>().loadMembers();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: const BoxDecoration(
                    color: ColorPalette.successColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_card, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'تسجيل دفعة مالية جديدة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. اختيار العميل
                        Text(
                          'العميل المستحق دفعته:',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (widget.member != null)
                          // عرض العميل المحدد مسبقاً (للقراءة فقط)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withOpacity(0.05),
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person, color: ColorPalette.primaryColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.member!.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'رقم العضوية: ${widget.member!.memberId}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // حقل البحث التلقائي عن الأعضاء
                          BlocBuilder<MembersCubit, MembersState>(
                            builder: (context, membersState) {
                              List<Member> members = [];
                              if (membersState is MembersLoaded) {
                                members = membersState.allMembers;
                              }

                              return RawAutocomplete<Member>(
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable<Member>.empty();
                                  }
                                  return members.where((Member option) {
                                    return option.fullName
                                            .toLowerCase()
                                            .contains(textEditingValue.text.toLowerCase()) ||
                                        option.memberId
                                            .toLowerCase()
                                            .contains(textEditingValue.text.toLowerCase()) ||
                                        (option.phoneNumber != null &&
                                            option.phoneNumber!.contains(textEditingValue.text));
                                  });
                                },
                                displayStringForOption: (Member option) => option.fullName,
                                fieldViewBuilder: (context, fieldTextEditingController, focusNode,
                                    onFieldSubmitted) {
                                  return TextFormField(
                                    controller: fieldTextEditingController,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      hintText: 'ابحث باسم العميل أو رقم الهاتف...',
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (_selectedMember == null) {
                                        return 'يرجى اختيار العميل من القائمة';
                                      }
                                      return null;
                                    },
                                  );
                                },
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topRight,
                                    child: Material(
                                      elevation: 4.0,
                                      borderRadius: BorderRadius.circular(10),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxHeight: 200, maxWidth: 450),
                                        child: ListView.separated(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          itemCount: options.length,
                                          separatorBuilder: (c, i) => const Divider(height: 1),
                                          itemBuilder: (BuildContext context, int index) {
                                            final Member option = options.elementAt(index);
                                            return ListTile(
                                              title: Text(option.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                              subtitle: Text('الرمز: ${option.memberId} | المتبقي: ${_formatCurrency(option.remainingAmount)} ج.م', style: const TextStyle(fontSize: 12)),
                                              onTap: () {
                                                onSelected(option);
                                                setState(() {
                                                  _selectedMember = option;
                                                  _amountCtrl.text = option.remainingAmount.toStringAsFixed(0);
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                        const SizedBox(height: 16),

                        // 2. كارت الذمم والوضع المالي
                        if (_selectedMember != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ColorPalette.debtStatus.withOpacity(0.06),
                              border: Border.all(color: ColorPalette.debtStatus.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.money_off, color: ColorPalette.debtStatus),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'المستحق المتبقي على العضو:',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    Text(
                                      '${_formatCurrency(_selectedMember!.remainingAmount)} ج.م',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: ColorPalette.debtStatus,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 3. قيمة الدفعة وطريقة الدفع
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _amountCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'قيمة الدفعة *',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'المبلغ مطلوب';
                                  final amount = double.tryParse(v) ?? 0.0;
                                  if (amount <= 0) return 'يجب أن يكون أكبر من 0';
                                  if (_selectedMember != null && amount > _selectedMember!.remainingAmount) {
                                    return 'تجاوزت المديونية المتبقية (${_selectedMember!.remainingAmount})';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _paymentMethod,
                                decoration: InputDecoration(
                                  labelText: 'طريقة الدفع *',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: _methods.map((method) {
                                  return DropdownMenuItem(
                                    value: method,
                                    child: Text(method),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _paymentMethod = v;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 4. الملاحظات
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'ملاحظات',
                            hintText: 'أدخل أي تفاصيل إضافية للعملية...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Footer Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              child: const Text('إلغاء'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorPalette.successColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                              child: const Text('تسجيل الدفع والوصول'),
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
}
