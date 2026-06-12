import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/member_entity.dart';
import '../../../../init_dependencies.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../memberships/domain/entities/membership_entity.dart';
import '../../../memberships/domain/usecases/get_all_memberships.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// ديالوج إضافة / تعديل عميل
/// ──────────────────────────────────────────────────────────────────────────────
/// يُستخدم لإنشاء عميل جديد أو تعديل بيانات عميل حالي.
/// يحتوي على 3 تبويبات: البيانات الشخصية، بيانات الاشتراك، والملاحظات.
class AddMemberDialog extends StatefulWidget {
  /// العميل المراد تعديله (null = إضافة جديد)
  final Member? member;

  /// دالة الحفظ تُستدعى بكائن [Member] الجديد أو المعدّل
  final Function(Member) onSave;

  const AddMemberDialog({
    super.key,
    this.member,
    required this.onSave,
  });

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  // ──────────────── مفاتيح النموذج ────────────────
  final _formKey = GlobalKey<FormState>();

  // ──────────────── هل نحن في وضع التعديل؟ ────────────────
  bool get _isEditing => widget.member != null;

  // ──────────────── متحكمات البيانات الشخصية ────────────────
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _emergencyContactCtrl;
  String? _selectedGender;

  // ──────────────── متحكمات بيانات الاشتراك ────────────────
  late final TextEditingController _memberIdCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _paidCtrl;
  late final TextEditingController _trainerCtrl;
  String _membershipType = 'شهري';
  DateTime? _startDate;
  DateTime? _endDate;

  // ──────────────── متحكم الملاحظات ────────────────
  late final TextEditingController _notesCtrl;

  // ──────────────── المبلغ المتبقي (محسوب تلقائياً) ────────────────
  double _remainingAmount = 0;

  // ──────────────── الباقات المخزنة بقاعدة البيانات ────────────────
  List<Membership> _memberships = [];
  bool _isLoadingMemberships = true;

  @override
  void initState() {
    super.initState();
    final m = widget.member;

    // تهيئة المتحكمات بالقيم الحالية أو الافتراضية
    _fullNameCtrl = TextEditingController(text: m?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: m?.phoneNumber ?? '');
    _addressCtrl = TextEditingController(text: m?.address ?? '');
    _emergencyContactCtrl =
        TextEditingController(text: m?.emergencyContact ?? '');
    _selectedGender = m?.gender;

    // توليد معرّف تلقائي للعميل الجديد
    _memberIdCtrl = TextEditingController(
      text: m?.memberId ??
          'MEM-${DateTime.now().millisecondsSinceEpoch}',
    );
    _membershipType = m?.membershipType ?? 'شهري';
    _priceCtrl = TextEditingController(
      text: m != null ? m.membershipPrice.toStringAsFixed(0) : '',
    );
    _discountCtrl = TextEditingController(
      text: m != null ? m.discount.toStringAsFixed(0) : '0',
    );
    _paidCtrl = TextEditingController(
      text: m != null ? m.paidAmount.toStringAsFixed(0) : '0',
    );
    _trainerCtrl = TextEditingController(text: m?.trainerName ?? '');
    _startDate = m != null ? DateTime.tryParse(m.startDate) : DateTime.now();
    _endDate = m != null
        ? DateTime.tryParse(m.endDate)
        : DateTime.now().add(const Duration(days: 30));

    _notesCtrl = TextEditingController(text: m?.notes ?? '');

    // حساب المبلغ المتبقي عند بدء التعديل
    _calculateRemaining();

    // الاستماع لتغييرات الحقول المالية
    _priceCtrl.addListener(_calculateRemaining);
    _discountCtrl.addListener(_calculateRemaining);
    _paidCtrl.addListener(_calculateRemaining);
    _loadMemberships();
  }

  Future<void> _loadMemberships() async {
    final result = await serviceLocator<GetAllMemberships>()(NoParams());
    result.fold(
      (failure) {
        setState(() {
          _isLoadingMemberships = false;
        });
      },
      (memberships) {
        setState(() {
          _memberships = memberships.where((m) => m.isActive).toList();
          _isLoadingMemberships = false;
          
          if (!_isEditing && _memberships.isNotEmpty) {
            final defaultM = _memberships.firstWhere(
              (m) => m.name == _membershipType,
              orElse: () => _memberships.first,
            );
            _selectMembership(defaultM);
          }
        });
      },
    );
  }

  void _selectMembership(Membership m) {
    setState(() {
      _membershipType = m.name;
      _priceCtrl.text = m.price.toStringAsFixed(0);
      
      if (_startDate != null) {
        _endDate = _startDate!.add(Duration(days: m.durationDays));
      }
      _calculateRemaining();
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _emergencyContactCtrl.dispose();
    _memberIdCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _paidCtrl.dispose();
    _trainerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// حساب المبلغ المتبقي تلقائياً
  void _calculateRemaining() {
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final discount = double.tryParse(_discountCtrl.text) ?? 0;
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    final remaining = (price - discount) - paid;
    setState(() {
      _remainingAmount = remaining < 0 ? 0 : remaining;
    });
  }

  /// اختيار تاريخ باستخدام DatePicker
  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) async {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: ColorPalette.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );
  }

  /// حفظ بيانات العميل
  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();

    final member = Member(
      id: widget.member?.id,
      memberId: _memberIdCtrl.text.trim(),
      fullName: _fullNameCtrl.text.trim(),
      phoneNumber:
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: widget.member?.email,
      gender: _selectedGender,
      birthDate: widget.member?.birthDate,
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      nationalId: widget.member?.nationalId,
      emergencyContact: _emergencyContactCtrl.text.trim().isEmpty
          ? null
          : _emergencyContactCtrl.text.trim(),
      membershipType: _membershipType,
      membershipPrice: double.tryParse(_priceCtrl.text) ?? 0,
      discount: double.tryParse(_discountCtrl.text) ?? 0,
      paidAmount: double.tryParse(_paidCtrl.text) ?? 0,
      remainingAmount: _remainingAmount,
      startDate:
          _startDate?.toIso8601String() ?? now.toIso8601String(),
      endDate: _endDate?.toIso8601String() ??
          now.add(const Duration(days: 30)).toIso8601String(),
      trainerName: _trainerCtrl.text.trim().isEmpty
          ? null
          : _trainerCtrl.text.trim(),
      notes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      memberPhotoPath: widget.member?.memberPhotoPath,
      createdAt:
          widget.member?.createdAt ?? now.toIso8601String(),
    );

    widget.onSave(member);
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
        child: SizedBox(
          width: 900,
          height: 700,
          child: Column(
            children: [
              // ──────────── شريط العنوان ────────────
              _buildHeader(theme, colorScheme),

              // ──────────── محتوى التبويبات ────────────
              Expanded(
                child: Form(
                  key: _formKey,
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        // شريط التبويبات
                        Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            border: Border(
                              bottom: BorderSide(
                                color: theme.dividerColor,
                              ),
                            ),
                          ),
                          child: TabBar(
                            labelColor: ColorPalette.primaryColor,
                            unselectedLabelColor:
                                theme.textTheme.bodyMedium?.color,
                            indicatorColor: ColorPalette.primaryColor,
                            indicatorWeight: 3,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            tabs: const [
                              Tab(
                                icon: Icon(Icons.person_outline, size: 20),
                                text: 'البيانات الشخصية',
                              ),
                              Tab(
                                icon:
                                    Icon(Icons.card_membership, size: 20),
                                text: 'بيانات الاشتراك',
                              ),
                              Tab(
                                icon:
                                    Icon(Icons.notes_outlined, size: 20),
                                text: 'ملاحظات',
                              ),
                            ],
                          ),
                        ),

                        // صفحات التبويبات
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildPersonalTab(theme),
                              _buildSubscriptionTab(theme),
                              _buildNotesTab(theme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ──────────── أزرار الإجراءات ────────────
              _buildFooter(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // شريط العنوان
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: ColorPalette.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit : Icons.person_add,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            _isEditing ? 'تعديل بيانات العميل' : 'إضافة عميل جديد',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'إغلاق',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تبويب 1: البيانات الشخصية
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPersonalTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // الصف الأول: الاسم + الهاتف
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _fullNameCtrl,
                  label: 'الاسم الكامل *',
                  icon: Icons.person,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'الاسم مطلوب';
                    }
                    return null;
                  },
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

          // الصف الثاني: الجنس + جهة اتصال الطوارئ
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _selectedGender,
                  label: 'الجنس',
                  icon: Icons.wc,
                  items: const ['ذكر', 'أنثى'],
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _emergencyContactCtrl,
                  label: 'جهة اتصال الطوارئ',
                  icon: Icons.emergency_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // الصف الثالث: العنوان
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _addressCtrl,
                  label: 'العنوان',
                  icon: Icons.location_on_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تبويب 2: بيانات الاشتراك
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSubscriptionTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // الصف الأول: رقم العضوية + نوع الاشتراك
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _memberIdCtrl,
                  label: 'رقم العضوية',
                  icon: Icons.confirmation_number_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isLoadingMemberships
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _memberships.any((m) => m.name == _membershipType)
                            ? _membershipType
                            : (_memberships.isNotEmpty ? _memberships.first.name : null),
                        decoration: InputDecoration(
                          labelText: 'نوع الاشتراك *',
                          prefixIcon: const Icon(Icons.card_membership),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _memberships.map((m) {
                          return DropdownMenuItem(
                            value: m.name,
                            child: Text('${m.name} (${m.durationDays} يوم)'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            final m = _memberships.firstWhere((element) => element.name == v);
                            _selectMembership(m);
                          }
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // الصف الثاني: السعر + الخصم
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _priceCtrl,
                  label: 'سعر الاشتراك',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _discountCtrl,
                  label: 'الخصم',
                  icon: Icons.discount_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // الصف الثالث: المبلغ المدفوع + المبلغ المتبقي
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _paidCtrl,
                  label: 'المبلغ المدفوع',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReadOnlyField(
                  label: 'المبلغ المتبقي',
                  icon: Icons.account_balance_wallet_outlined,
                  value: _remainingAmount.toStringAsFixed(0),
                  valueColor: _remainingAmount > 0
                      ? ColorPalette.debtStatus
                      : ColorPalette.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // الصف الرابع: تاريخ البدء + تاريخ الانتهاء
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'تاريخ البدء',
                  icon: Icons.calendar_today,
                  date: _startDate,
                  onTap: () async {
                    final picked =
                        await _pickDate(context, _startDate);
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                        final currentM = _memberships.firstWhere(
                          (m) => m.name == _membershipType,
                          orElse: () => const Membership(name: '', durationDays: 30, price: 0, freezeDays: 0, isActive: false, createdAt: ''),
                        );
                        if (currentM.name.isNotEmpty) {
                          _endDate = _startDate!.add(Duration(days: currentM.durationDays));
                        }
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  label: 'تاريخ الانتهاء',
                  icon: Icons.event_outlined,
                  date: _endDate,
                  onTap: () async {
                    final picked =
                        await _pickDate(context, _endDate);
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // الصف الخامس: اسم المدرب
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _trainerCtrl,
                  label: 'اسم المدرب',
                  icon: Icons.fitness_center,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تبويب 3: الملاحظات
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNotesTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: TextFormField(
        controller: _notesCtrl,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          labelText: 'ملاحظات',
          hintText: 'أدخل أي ملاحظات إضافية عن العميل...',
          alignLabelWithHint: true,
          prefixIcon: const Padding(
            padding: EdgeInsets.only(bottom: 200),
            child: Icon(Icons.notes_outlined),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: ColorPalette.primaryColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // أزرار التذييل
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFooter(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // زر الإلغاء
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('إلغاء'),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // زر الحفظ
          ElevatedButton.icon(
            onPressed: _save,
            icon: Icon(
              _isEditing ? Icons.save : Icons.add,
              size: 18,
            ),
            label: Text(_isEditing ? 'حفظ التعديلات' : 'إضافة العميل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primaryColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  مكونات الحقول المشتركة
  // ═══════════════════════════════════════════════════════════════════════════

  /// حقل نصي عام مع أيقونة وتسمية
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
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ColorPalette.primaryColor,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  /// قائمة منسدلة مع أيقونة وتسمية
  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ColorPalette.primaryColor,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
    );
  }

  /// حقل تاريخ (للقراءة فقط مع زر الاختيار)
  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final formatted =
        date != null ? DateFormat('yyyy/MM/dd').format(date) : '';
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: formatted),
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ColorPalette.primaryColor,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  /// حقل للقراءة فقط (مثل المبلغ المتبقي)
  Widget _buildReadOnlyField({
    required String label,
    required IconData icon,
    required String value,
    Color? valueColor,
  }) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: value),
      style: TextStyle(
        color: valueColor,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
