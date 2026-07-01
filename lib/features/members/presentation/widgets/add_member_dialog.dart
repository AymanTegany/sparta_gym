import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../cubit/members_cubit.dart';
import '../cubit/members_state.dart';

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/member_entity.dart';
import '../../../../init_dependencies.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../memberships/domain/entities/membership_entity.dart';
import '../../../memberships/domain/usecases/get_all_memberships.dart';
import '../../../diets/domain/entities/diet_plan.dart';
import '../../../diets/domain/usecases/get_diet_plans.dart';
import '../../../trainers/domain/entities/trainer_entity.dart';
import '../../../trainers/domain/usecases/get_all_trainers.dart';
import 'package:sparta_gym/features/discount_codes/domain/entities/discount_code.dart';
import 'package:sparta_gym/features/discount_codes/domain/repositories/discount_codes_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparta_gym/features/additional_services/domain/entities/additional_service.dart';
import 'package:sparta_gym/features/additional_services/domain/usecases/additional_services_usecases.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// ديالوج إضافة / تعديل عميل
/// ──────────────────────────────────────────────────────────────────────────────
/// يُستخدم لإنشاء عميل جديد أو تعديل بيانات عميل حالي.
/// يحتوي على 3 تبويبات: البيانات الشخصية، بيانات الاشتراك، والشروط والأحكام.
class AddMemberDialog extends StatefulWidget {
  /// العميل المراد تعديله (null = إضافة جديد)
  final Member? member;

  /// دالة الحفظ تُستدعى بكائن [Member] الجديد أو المعدّل وطريقة الدفع
  final Function(
    Member member,
    String paymentMethod, {
    bool printInvoice,
    bool shareWhatsapp,
  })
  onSave;

  const AddMemberDialog({super.key, this.member, required this.onSave});

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
  late final TextEditingController _ageCtrl;
  String? _selectedGender;

  // ──────────────── متحكمات بيانات الاشتراك ────────────────
  late final TextEditingController _memberIdCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _paidCtrl;
  late final TextEditingController _trainerCtrl;
  late final TextEditingController _startDateCtrl;
  late final TextEditingController _endDateCtrl;
  late final TextEditingController _remainingCtrl;
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

  // ──────────────── المدربون والأنظمة الغذائية ────────────────
  List<Trainer> _trainers = [];
  bool _isLoadingTrainers = true;
  String? _selectedTrainerName;

  List<DietPlan> _dietPlans = [];
  bool _isLoadingDietPlans = true;
  int? _selectedDietPlanId;

  // ──────────────── أكواد الخصم ────────────────
  List<DiscountCode> _discountCodes = [];
  bool _isLoadingDiscountCodes = true;
  DiscountCode? _selectedDiscountCode;

  String _paymentMethod = 'نقدي';

  // ──────────────── الخدمات الإضافية ────────────────
  List<AdditionalService> _additionalServices = [];
  List<AdditionalService> _selectedAdditionalServices = [];
  bool _isLoadingAdditionalServices = true;

  @override
  void initState() {
    super.initState();
    final m = widget.member;

    // تهيئة المتحكمات بالقيم الحالية أو الافتراضية
    _fullNameCtrl = TextEditingController(text: m?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: m?.phoneNumber ?? '');
    _addressCtrl = TextEditingController(text: m?.address ?? '');
    _ageCtrl = TextEditingController(text: m?.birthDate ?? '');
    _selectedGender = m?.gender;

    // توليد معرّف تلقائي للعميل الجديد
    _memberIdCtrl = TextEditingController(
      text: m?.memberId ?? 'MEM-${DateTime.now().millisecondsSinceEpoch}',
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

    _startDateCtrl = TextEditingController(
      text: _startDate != null
          ? DateFormat('yyyy/MM/dd').format(_startDate!)
          : '',
    );
    _endDateCtrl = TextEditingController(
      text: _endDate != null ? DateFormat('yyyy/MM/dd').format(_endDate!) : '',
    );
    _remainingCtrl = TextEditingController(text: '0');

    _notesCtrl = TextEditingController(text: m?.notes ?? '');
    
    if (!_isEditing && _notesCtrl.text.isEmpty) {
      _loadDefaultTerms();
    }

    _selectedTrainerName = m?.trainerName;
    _selectedDietPlanId = m?.dietPlanId;

    // حساب المبلغ المتبقي عند بدء التعديل
    _calculateRemaining();

    // الاستماع لتغييرات الحقول المالية
    _priceCtrl.addListener(_calculateRemaining);
    _discountCtrl.addListener(_calculateRemaining);
    _paidCtrl.addListener(_calculateRemaining);
    _loadMemberships();
    _loadTrainers();
    _loadDietPlans();
    _loadDiscountCodes();
    _loadAdditionalServices();
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
          final uniqueMemberships = <String, Membership>{};
          for (final m in memberships.where((m) => m.isActive)) {
            uniqueMemberships[m.name] = m;
          }
          _memberships = uniqueMemberships.values.toList();
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

  Future<void> _loadTrainers() async {
    final result = await serviceLocator<GetAllTrainers>()(NoParams());
    result.fold(
      (failure) {
        setState(() {
          _isLoadingTrainers = false;
        });
      },
      (trainers) {
        setState(() {
          final uniqueTrainers = <String, Trainer>{};
          for (final t in trainers.where((t) => t.isActive)) {
            uniqueTrainers[t.fullName] = t;
          }
          _trainers = uniqueTrainers.values.toList();
          _isLoadingTrainers = false;
        });
      },
    );
  }

  Future<void> _loadDietPlans() async {
    final result = await serviceLocator<GetDietPlans>()(NoParams());
    result.fold(
      (failure) {
        setState(() {
          _isLoadingDietPlans = false;
        });
      },
      (dietPlans) {
        setState(() {
          _dietPlans = dietPlans;
          _isLoadingDietPlans = false;
        });
      },
    );
  }

  Future<void> _loadAdditionalServices() async {
    final result = await serviceLocator<GetAllAdditionalServices>()(NoParams());
    result.fold(
      (failure) {
        setState(() {
          _isLoadingAdditionalServices = false;
        });
      },
      (services) {
        setState(() {
          _additionalServices = services.where((s) => s.isActive).toList();
          
          if (_isEditing && widget.member!.additionalServicesIds != null) {
            final ids = widget.member!.additionalServicesIds!.split(',').map((e) => int.tryParse(e)).where((e) => e != null).toList();
            _selectedAdditionalServices = _additionalServices.where((s) => ids.contains(s.id)).toList();
          }
          
          _isLoadingAdditionalServices = false;
        });
      },
    );
  }

  Future<void> _loadDefaultTerms() async {
    final prefs = serviceLocator<SharedPreferences>();
    final defaultTerms = prefs.getString('gym_default_terms') ?? '';
    if (defaultTerms.isNotEmpty && mounted) {
      setState(() {
        _notesCtrl.text = defaultTerms;
      });
    }
  }

  Future<void> _saveDefaultTerms() async {
    final prefs = serviceLocator<SharedPreferences>();
    await prefs.setString('gym_default_terms', _notesCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الشروط والأحكام الافتراضية بنجاح')),
      );
    }
  }

  void _selectMembership(Membership m) {
    setState(() {
      _membershipType = m.name;

      if (_startDate != null) {
        _endDate = _startDate!.add(Duration(days: m.durationDays));
        _endDateCtrl.text = DateFormat('yyyy/MM/dd').format(_endDate!);
      }
      _updateTotalPrice();
    });
  }

  void _updateTotalPrice() {
    if (_memberships.isEmpty) return;

    final m = _memberships.firstWhere(
      (element) => element.name == _membershipType,
      orElse: () => _memberships.first,
    );

    double total = m.price;

    if (_selectedTrainerName != null) {
      final t = _trainers.cast<Trainer>().firstWhere(
        (t) => t.fullName == _selectedTrainerName,
        orElse: () => const Trainer(
          fullName: '',
          phoneNumber: '',
          isActive: false,
          createdAt: '',
        ),
      );
      if (t.price != null) total += t.price!;
    }

    if (_selectedDietPlanId != null) {
      final d = _dietPlans.cast<DietPlan>().firstWhere(
        (d) => d.id == _selectedDietPlanId,
        orElse: () => DietPlan(name: '', meals: '', createdAt: DateTime.now()),
      );
      total += d.price;
    }
    
    for (var s in _selectedAdditionalServices) {
      total += s.monthlyPrice;
    }

    // تأخير التحديث لتجنب تعارض الـ setState مع Dropdown listeners
    Future.microtask(() {
      if (mounted) {
        _priceCtrl.text = total.toStringAsFixed(0);
        _applyDiscountCode();
        _calculateRemaining();
      }
    });
  }

  void _applyDiscountCode() {
    if (_selectedDiscountCode == null) {
      // لا تفعل شيء إذا كان تم مسح الكود وكان هناك خصم مخصص
      return;
    }
    final code = _selectedDiscountCode!;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    double discount = 0;
    if (code.type == 'percentage') {
      discount = price * (code.value / 100);
    } else {
      discount = code.value;
    }
    _discountCtrl.text = discount.toStringAsFixed(0);
  }

  Future<void> _loadDiscountCodes() async {
    try {
      final repository = serviceLocator<DiscountCodesRepository>();
      final result = await repository.getDiscountCodes();
      result.fold((failure) {}, (codes) {
        if (mounted) {
          setState(() {
            _discountCodes = codes;
            _isLoadingDiscountCodes = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDiscountCodes = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _ageCtrl.dispose();
    _memberIdCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _paidCtrl.dispose();
    _trainerCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _remainingCtrl.dispose();
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
      _remainingCtrl.text = _remainingAmount.toStringAsFixed(0);
    });
  }

  /// اختيار تاريخ باستخدام DatePicker
  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) async {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: ColorPalette.primaryColor),
          ),
          child: child!,
        );
      },
    );
  }

  /// حفظ بيانات العميل
  void _save({bool printInvoice = false, bool shareWhatsapp = false}) {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();

    final member = Member(
      id: widget.member?.id,
      memberId: _memberIdCtrl.text.trim(),
      fullName: _fullNameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim().isEmpty
          ? null
          : _phoneCtrl.text.trim(),
      email: widget.member?.email,
      gender: _selectedGender,
      birthDate: _ageCtrl.text.trim().isEmpty ? null : _ageCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      nationalId: widget.member?.nationalId,
      emergencyContact: widget.member?.emergencyContact,
      membershipType: _membershipType,
      membershipPrice: double.tryParse(_priceCtrl.text) ?? 0,
      discount: double.tryParse(_discountCtrl.text) ?? 0,
      paidAmount: double.tryParse(_paidCtrl.text) ?? 0,
      remainingAmount: _remainingAmount,
      startDate: _startDate?.toIso8601String() ?? now.toIso8601String(),
      endDate:
          _endDate?.toIso8601String() ??
          now.add(const Duration(days: 30)).toIso8601String(),
      trainerName: _selectedTrainerName,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      memberPhotoPath: widget.member?.memberPhotoPath,
      dietPlanId: _selectedDietPlanId,
      additionalServicesIds: _selectedAdditionalServices.isEmpty 
          ? null 
          : _selectedAdditionalServices.map((e) => e.id).join(','),
      createdAt: widget.member?.createdAt ?? now.toIso8601String(),
    );

    widget.onSave(
      member,
      _paymentMethod,
      printInvoice: printInvoice,
      shareWhatsapp: shareWhatsapp,
    );
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
                              bottom: BorderSide(color: theme.dividerColor),
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
                                icon: Icon(Icons.card_membership, size: 20),
                                text: 'بيانات الاشتراك',
                              ),
                              Tab(
                                icon: Icon(Icons.gavel_outlined, size: 20),
                                text: 'الشروط والأحكام',
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

          // الصف الثاني: الجنس + العمر
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
                  controller: _ageCtrl,
                  label: 'العمر',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
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
                  label: 'رقم العضوية (الباركود) *',
                  icon: Icons.confirmation_number_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'رقم العضوية مطلوب';
                    }
                    final state = context.read<MembersCubit>().state;
                    if (state is MembersLoaded) {
                      final exists = state.allMembers.any((m) {
                        if (_isEditing && m.id == widget.member?.id) {
                          return false;
                        }
                        return m.memberId.trim().toLowerCase() ==
                            v.trim().toLowerCase();
                      });
                      if (exists) {
                        return 'هذا الباركود/رقم العضوية مسجل لعميل آخر بالفعل';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isLoadingMemberships
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value:
                            _memberships.any((m) => m.name == _membershipType)
                            ? _membershipType
                            : (_memberships.isNotEmpty
                                  ? _memberships.first.name
                                  : null),
                        decoration: InputDecoration(
                          labelText: 'نوع الاشتراك *',
                          prefixIcon: const Icon(Icons.card_membership),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _memberships.map((m) {
                          return DropdownMenuItem(
                            value: m.name,
                            child: Text('${m.name} (${m.durationDays} يوم)'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            final m = _memberships.firstWhere(
                              (element) => element.name == v,
                            );
                            _selectMembership(m);
                          }
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // الصف الثاني: السعر + كود الخصم + قيمة الخصم
          Row(
            children: [
              Expanded(
                flex: 2,
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
                flex: 3,
                child: _isLoadingDiscountCodes
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<DiscountCode?>(
                        value: _selectedDiscountCode,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'كود الخصم',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_offer_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<DiscountCode?>(
                            value: null,
                            child: Text('بدون كود (أو خصم يدوي)'),
                          ),
                          ..._discountCodes.map((code) {
                            return DropdownMenuItem<DiscountCode?>(
                              value: code,
                              child: Text(
                                '${code.name} (${code.type == 'percentage' ? '${code.value.toStringAsFixed(0)}%' : '${code.value.toStringAsFixed(0)} ج'})',
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedDiscountCode = val;
                            if (val != null) {
                              _applyDiscountCode();
                              _calculateRemaining();
                            }
                          });
                        },
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _discountCtrl,
                  label: 'قيمة الخصم',
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
                  controller: _remainingCtrl,
                  valueColor: _remainingAmount > 0
                      ? ColorPalette.debtStatus
                      : ColorPalette.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // صف طريقة الدفع في حال وجود مبلغ مدفوع
          if ((double.tryParse(_paidCtrl.text) ?? 0) > 0) ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: InputDecoration(
                      labelText: 'طريقة الدفع *',
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'نقدي',
                        child: Text('نقدي (كاش)'),
                      ),
                      DropdownMenuItem(
                        value: 'فودافون كاش',
                        child: Text('فودافون كاش'),
                      ),
                      DropdownMenuItem(
                        value: 'إنستاباي',
                        child: Text('إنستاباي'),
                      ),
                      DropdownMenuItem(
                        value: 'تحويل بنكي',
                        child: Text('تحويل بنكي'),
                      ),
                      DropdownMenuItem(value: 'بطاقة', child: Text('بطاقة')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _paymentMethod = v;
                        });
                      }
                    },
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // الصف الرابع: تاريخ البدء + تاريخ الانتهاء
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'تاريخ البدء',
                  icon: Icons.calendar_today,
                  controller: _startDateCtrl,
                  onTap: () async {
                    final picked = await _pickDate(context, _startDate);
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                        _startDateCtrl.text = DateFormat(
                          'yyyy/MM/dd',
                        ).format(picked);
                        final currentM = _memberships
                            .cast<Membership>()
                            .firstWhere(
                              (m) => m.name == _membershipType,
                              orElse: () => const Membership(
                                name: '',
                                durationDays: 30,
                                price: 0,
                                freezeDays: 0,
                                isActive: false,
                                createdAt: '',
                              ),
                            );
                        if (currentM.name.isNotEmpty) {
                          _endDate = _startDate!.add(
                            Duration(days: currentM.durationDays),
                          );
                          _endDateCtrl.text = DateFormat(
                            'yyyy/MM/dd',
                          ).format(_endDate!);
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
                  controller: _endDateCtrl,
                  onTap: () async {
                    final picked = await _pickDate(context, _endDate);
                    if (picked != null) {
                      setState(() {
                        _endDate = picked;
                        _endDateCtrl.text = DateFormat(
                          'yyyy/MM/dd',
                        ).format(picked);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // الصف الخامس: اسم المدرب والنظام الغذائي
          Row(
            children: [
              Expanded(
                child: _isLoadingTrainers
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value:
                            _trainers.any(
                              (t) => t.fullName == _selectedTrainerName,
                            )
                            ? _selectedTrainerName
                            : null,
                        decoration: InputDecoration(
                          labelText: 'المدرب المسؤول',
                          prefixIcon: const Icon(Icons.fitness_center),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('بدون مدرب (شخصي)'),
                          ),
                          ..._trainers.map((t) {
                            return DropdownMenuItem<String>(
                              value: t.fullName,
                              child: Text(t.fullName),
                            );
                          }),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedTrainerName = v;
                            _updateTotalPrice();
                          });
                        },
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isLoadingDietPlans
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<int>(
                        value:
                            _dietPlans.any((d) => d.id == _selectedDietPlanId)
                            ? _selectedDietPlanId
                            : null,
                        decoration: InputDecoration(
                          labelText: 'النظام الغذائي',
                          prefixIcon: const Icon(Icons.restaurant_menu),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('بدون نظام غذائي'),
                          ),
                          ..._dietPlans.map((d) {
                            return DropdownMenuItem<int>(
                              value: d.id,
                              child: Text(d.name),
                            );
                          }),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedDietPlanId = v;
                            _updateTotalPrice();
                          });
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoadingAdditionalServices)
            const Center(child: CircularProgressIndicator())
          else if (_additionalServices.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'خدمات أخرى (معدات إضافية):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _additionalServices.map((service) {
                    final isSelected = _selectedAdditionalServices.any((s) => s.id == service.id);
                    return FilterChip(
                      label: Text('${service.name} (${service.monthlyPrice.toStringAsFixed(0)} ج.م)'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAdditionalServices.add(service);
                          } else {
                            _selectedAdditionalServices.removeWhere((s) => s.id == service.id);
                          }
                          _updateTotalPrice();
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════════════════
  // تبويب 3: الشروط والأحكام
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNotesTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الشروط والأحكام الخاصة بالاشتراك',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _saveDefaultTerms,
                icon: const Icon(Icons.save),
                label: const Text('حفظ كشروط افتراضية'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextFormField(
              controller: _notesCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                labelText: 'الشروط والأحكام',
                hintText: 'أدخل الشروط والأحكام للعميل...',
                alignLabelWithHint: true,
                prefixIcon: const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Icon(Icons.gavel_outlined),
                    ),
                  ],
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: ColorPalette.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // زر الحفظ وطباعة (فقط للإضافة)
          if (!_isEditing) ...[
            ElevatedButton.icon(
              onPressed: () => _save(printInvoice: true),
              icon: const Icon(Icons.print, size: 18),
              label: const Text('اضافة وطباعة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _save(shareWhatsapp: true),
              icon: const Icon(Icons.share, size: 18),
              label: const Text(' اضافة و مشاركةواتساب'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
            const SizedBox(width: 12),
          ],

          // زر الحفظ
          ElevatedButton.icon(
            onPressed: () => _save(printInvoice: false),
            icon: Icon(_isEditing ? Icons.save : Icons.add, size: 18),
            label: Text(_isEditing ? 'حفظ التعديلات' : 'إضافة فقط'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ColorPalette.primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ColorPalette.primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      readOnly: true,
      controller: controller,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ColorPalette.primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  /// حقل للقراءة فقط (مثل المبلغ المتبقي)
  Widget _buildReadOnlyField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    Color? valueColor,
  }) {
    return TextFormField(
      readOnly: true,
      controller: controller,
      style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
