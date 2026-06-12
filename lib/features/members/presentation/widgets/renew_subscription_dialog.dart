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
/// ديالوج تجديد الاشتراك
/// ──────────────────────────────────────────────────────────────────────────────
/// يتيح تجديد اشتراك العميل مع حساب تلقائي لتاريخ الانتهاء والمبلغ المتبقي.
class RenewSubscriptionDialog extends StatefulWidget {
  /// بيانات العميل الحالي
  final Member member;

  /// دالة التجديد — تُستدعى بمعاملات الاشتراك الجديد
  final Function({
    required String membershipType,
    required double price,
    required double discount,
    required double paidAmount,
    required String startDate,
    required String endDate,
  }) onRenew;

  const RenewSubscriptionDialog({
    super.key,
    required this.member,
    required this.onRenew,
  });

  @override
  State<RenewSubscriptionDialog> createState() =>
      _RenewSubscriptionDialogState();
}

class _RenewSubscriptionDialogState extends State<RenewSubscriptionDialog> {
  // ──────────────── مفتاح النموذج ────────────────
  final _formKey = GlobalKey<FormState>();

  // ──────────────── متحكمات الحقول ────────────────
  late final TextEditingController _priceCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _paidCtrl;

  // ──────────────── بيانات الاشتراك الجديد ────────────────
  String _membershipType = 'شهري';
  late DateTime _startDate;
  late DateTime _endDate;
  double _remainingAmount = 0;

  // ──────────────── الباقات المخزنة بقاعدة البيانات ────────────────
  List<Membership> _memberships = [];
  bool _isLoadingMemberships = true;

  @override
  void initState() {
    super.initState();

    _priceCtrl = TextEditingController();
    _discountCtrl = TextEditingController(text: '0');
    _paidCtrl = TextEditingController(text: '0');

    // تاريخ البدء = اليوم
    _startDate = DateTime.now();
    _endDate = _startDate.add(const Duration(days: 30));

    // الاستماع لتغييرات الحقول المالية
    _priceCtrl.addListener(_calculateRemaining);
    _discountCtrl.addListener(_calculateRemaining);
    _paidCtrl.addListener(_calculateRemaining);
    _loadMemberships();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _paidCtrl.dispose();
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
          
          if (_memberships.isNotEmpty) {
            final defaultM = _memberships.firstWhere(
              (m) => m.name == widget.member.membershipType,
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
      _endDate = _startDate.add(Duration(days: m.durationDays));
      _calculateRemaining();
    });
  }

  /// تحديث تاريخ الانتهاء بناءً على نوع الاشتراك وتاريخ البدء
  void _updateEndDate() {
    final currentM = _memberships.firstWhere(
      (m) => m.name == _membershipType,
      orElse: () => const Membership(name: '', durationDays: 30, price: 0, freezeDays: 0, isActive: false, createdAt: ''),
    );
    if (currentM.name.isNotEmpty) {
      setState(() {
        _endDate = _startDate.add(Duration(days: currentM.durationDays));
      });
    }
  }

  /// اختيار تاريخ
  Future<DateTime?> _pickDate(DateTime initial) async {
    return showDatePicker(
      context: context,
      initialDate: initial,
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

  /// تنسيق التاريخ للعرض
  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  /// تنسيق المبلغ المالي
  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'ar').format(amount);
  }

  /// تأكيد التجديد
  void _renew() {
    if (!_formKey.currentState!.validate()) return;

    widget.onRenew(
      membershipType: _membershipType,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      discount: double.tryParse(_discountCtrl.text) ?? 0,
      paidAmount: double.tryParse(_paidCtrl.text) ?? 0,
      startDate: _startDate.toIso8601String(),
      endDate: _endDate.toIso8601String(),
    );
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ──────────── العنوان ────────────
              _buildHeader(),

              // ──────────── المحتوى ────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // معلومات الاشتراك الحالي
                        _buildCurrentSubscription(theme),
                        const SizedBox(height: 24),

                        // بيانات الاشتراك الجديد
                        _buildSectionTitle(theme, 'بيانات الاشتراك الجديد',
                            Icons.autorenew),
                        const SizedBox(height: 16),

                        // نوع الاشتراك
                        _buildDropdown(theme),
                        const SizedBox(height: 16),

                        // السعر والخصم
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _priceCtrl,
                                label: 'سعر الاشتراك',
                                icon: Icons.attach_money,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'السعر مطلوب';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _discountCtrl,
                                label: 'الخصم',
                                icon: Icons.discount_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // المدفوع والمتبقي
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _paidCtrl,
                                label: 'المبلغ المدفوع',
                                icon: Icons.payments_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildReadOnlyBox(
                                label: 'المبلغ المتبقي',
                                value:
                                    '${_formatCurrency(_remainingAmount)} ج.م',
                                color: _remainingAmount > 0
                                    ? ColorPalette.debtStatus
                                    : ColorPalette.successColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // تواريخ البدء والانتهاء
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                label: 'تاريخ البدء',
                                date: _startDate,
                                onTap: () async {
                                  final picked =
                                      await _pickDate(_startDate);
                                  if (picked != null) {
                                    setState(() {
                                      _startDate = picked;
                                    });
                                    _updateEndDate();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                label: 'تاريخ الانتهاء',
                                date: _endDate,
                                onTap: () async {
                                  final picked =
                                      await _pickDate(_endDate);
                                  if (picked != null) {
                                    setState(() => _endDate = picked);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ──────────── الأزرار ────────────
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // العنوان
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: ColorPalette.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.autorenew, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Text(
            'تجديد الاشتراك',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // بطاقة الاشتراك الحالي
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCurrentSubscription(ThemeData theme) {
    final statusColor = !widget.member.isActive
        ? ColorPalette.expiredStatus
        : widget.member.isExpiringSoon
            ? ColorPalette.expiringSoonStatus
            : ColorPalette.activeStatus;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: statusColor),
              const SizedBox(width: 8),
              Text(
                'الاشتراك الحالي — ${widget.member.fullName}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 24,
            runSpacing: 6,
            children: [
              _currentInfoChip('النوع', widget.member.membershipType),
              _currentInfoChip('الحالة', widget.member.statusText),
              _currentInfoChip('ينتهي في',
                  _formatDate(DateTime.tryParse(widget.member.endDate) ?? DateTime.now())),
              _currentInfoChip(
                  'المتبقي', '${widget.member.remainingDays} يوم'),
            ],
          ),
        ],
      ),
    );
  }

  /// شريحة معلومة في بطاقة الاشتراك الحالي
  Widget _currentInfoChip(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // عنوان قسم
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ColorPalette.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleMedium?.color,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الأزرار السفلية
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFooter(ThemeData theme) {
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
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('إلغاء'),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _renew,
            icon: const Icon(Icons.autorenew, size: 18),
            label: const Text('تجديد الاشتراك'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primaryColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
  //  مكونات الحقول
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: ColorPalette.primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown(ThemeData theme) {
    if (_isLoadingMemberships) {
      return const Center(child: CircularProgressIndicator());
    }
    return DropdownButtonFormField<String>(
      value: _memberships.any((m) => m.name == _membershipType)
          ? _membershipType
          : (_memberships.isNotEmpty ? _memberships.first.name : null),
      onChanged: (v) {
        if (v != null) {
          final m = _memberships.firstWhere((element) => element.name == v);
          _selectMembership(m);
        }
      },
      decoration: InputDecoration(
        labelText: 'نوع الاشتراك',
        prefixIcon: const Icon(Icons.card_membership, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: ColorPalette.primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: _memberships
          .map((m) => DropdownMenuItem(value: m.name, child: Text(m.name)))
          .toList(),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: _formatDate(date)),
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today, size: 20),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: ColorPalette.primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildReadOnlyBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            const Icon(Icons.account_balance_wallet_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
