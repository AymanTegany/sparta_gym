import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/widgets/sidebar_layout.dart';
import '../../../../core/services/whatsapp_bot_service.dart';
import '../../../../init_dependencies.dart';
import '../../../members/domain/entities/member_entity.dart';
import '../../../members/presentation/cubit/members_cubit.dart';
import '../../../members/presentation/cubit/members_state.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// صفحة أداة إرسال واتساب
/// ترتبط بـ WhatsappBotService المركزي المستمر في الخلفية
/// تتيح إرسال الرسائل الفردية والجماعية، مع إمكانية إيقاف الاتصال أو تغيير الحساب
/// ──────────────────────────────────────────────────────────────────────────────
class WhatsappToolPage extends StatefulWidget {
  const WhatsappToolPage({super.key});

  @override
  State<WhatsappToolPage> createState() => _WhatsappToolPageState();
}

class _WhatsappToolPageState extends State<WhatsappToolPage> {
  late final WhatsappBotService _botService;

  // ─── إعدادات الواجهة ───
  final TextEditingController _chromePathCtrl = TextEditingController();

  // ─── إرسال فردي ───
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();

  // ─── إرسال جماعي ───
  String _bulkFilter = 'expired'; // expired, expiring_soon, debt, active, all
  String _bulkTemplate = 'expired'; // expired, expiring_soon, debt, active_reminder, welcome, custom
  final TextEditingController _customMsgCtrl = TextEditingController();

  // ─── سجل النشاط ───
  final ScrollController _logScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _botService = serviceLocator<WhatsappBotService>();
    _chromePathCtrl.text = _botService.chromePath;
    _botService.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _botService.removeListener(_onServiceUpdate);
    // ملاحظة مهمة: لا نغلق الاتصال هنا لأن الخدمة مصممة لتبقى نشطة في الخلفية
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    _chromePathCtrl.dispose();
    _customMsgCtrl.dispose();
    _logScrollCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // وظائف الاتصال والتحكم
  // ═══════════════════════════════════════════════════════════════════════════

  void _confirmSwitchAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.switch_account_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('تغيير حساب واتساب'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سيتم تسجيل الخروج من الحساب الحالي ومسح بيانات الجلسة السابقة بالكامل.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'بعد ذلك، سيتم تجهيز رمز QR جديد لربط الحساب أو الهاتف الجديد فوراً.\nهل أنت متأكد من رغبتك في المتابعة؟',
              style: TextStyle(height: 1.4, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('تسجيل خروج وتغيير الحساب'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _botService.switchAccount();
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إرسال رسالة فردية
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _sendSingleMessage() async {
    if (!_botService.isConnected) {
      _showSnackBar('يجب الاتصال بالواتساب أولاً!', isError: true);
      return;
    }

    final phone = _phoneCtrl.text.trim();
    final msg = _messageCtrl.text.trim();
    if (phone.isEmpty || msg.isEmpty) {
      _showSnackBar('يرجى إدخال رقم الهاتف والرسالة', isError: true);
      return;
    }

    try {
      await _botService.sendSingleMessage(phone, msg);
      _messageCtrl.clear();
      _showSnackBar('تم إرسال الرسالة بنجاح ✓');
    } catch (e) {
      _showSnackBar('فشل الإرسال: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إرسال تنبيهات جماعية
  // ═══════════════════════════════════════════════════════════════════════════

  List<Member> _getFilteredMembers(List<Member> allMembers) {
    switch (_bulkFilter) {
      case 'expired':
        return allMembers
            .where(
              (m) =>
                  !m.isActive &&
                  m.phoneNumber != null &&
                  m.phoneNumber!.isNotEmpty,
            )
            .toList();
      case 'expiring_soon':
        return allMembers
            .where(
              (m) =>
                  m.isExpiringSoon &&
                  m.phoneNumber != null &&
                  m.phoneNumber!.isNotEmpty,
            )
            .toList();
      case 'debt':
        return allMembers
            .where(
              (m) =>
                  m.hasDebt &&
                  m.phoneNumber != null &&
                  m.phoneNumber!.isNotEmpty,
            )
            .toList();
      case 'active':
        return allMembers
            .where(
              (m) =>
                  m.isActive &&
                  m.phoneNumber != null &&
                  m.phoneNumber!.isNotEmpty,
            )
            .toList();
      case 'all':
      default:
        return allMembers
            .where((m) => m.phoneNumber != null && m.phoneNumber!.isNotEmpty)
            .toList();
    }
  }

  String _buildMessageForMember(Member member) {
    switch (_bulkTemplate) {
      case 'welcome':
        return 'أهلاً بك كابتن ${member.fullName} في الجيم! 🎉\n\n'
            'سعداء جداً بانضمامك إلينا.\n'
            'إذا كان لديك أي استفسار لا تتردد في التواصل معنا. نتمنى لك تمرين ممتع! 💪';
      case 'active_reminder':
        return 'أهلاً كابتن ${member.fullName}،\n\n'
            'نذكرك بأن ميعاد تجديد اشتراكك القادم في باقة ${member.membershipType} هو يوم ${_formatDate(member.endDate)}.\n'
            'نتمنى لك يوم سعيد! 💪';
      case 'expired':
        return 'أهلاً كابتن ${member.fullName}،\n\n'
            'نود تذكيرك بأن اشتراكك في باقة ${member.membershipType} قد انتهى بتاريخ ${_formatDate(member.endDate)}.\n'
            'نتمنى رؤيتك قريباً في الجيم لتجديد الاشتراك! 💪';
      case 'expiring_soon':
        return 'مرحباً ${member.fullName}،\n\n'
            'اشتراكك في الجيم هينتهي خلال ${member.remainingDays} أيام.\n'
            'جدد اشتراكك دلوقتي عشان تكمل تدريبك من غير انقطاع! 💪';
      case 'debt':
        return 'أهلاً كابتن ${member.fullName}،\n\n'
            'نود تذكيرك بوجود مبلغ متبقي على اشتراكك بقيمة ${member.remainingAmount.toStringAsFixed(0)} ج.م.\n'
            'يرجى تسوية المبلغ في أقرب وقت. شكراً لك! 🙏';
      case 'custom':
        return _customMsgCtrl.text
            .trim()
            .replaceAll('{name}', member.fullName)
            .replaceAll('{membership}', member.membershipType)
            .replaceAll('{end_date}', _formatDate(member.endDate))
            .replaceAll(
              '{remaining}',
              member.remainingAmount.toStringAsFixed(0),
            )
            .replaceAll('{days}', member.remainingDays.toString());
      default:
        return '';
    }
  }

  Future<void> _sendBulkMessages(List<Member> members) async {
    if (!_botService.isConnected) {
      _showSnackBar('يجب الاتصال بالواتساب أولاً!', isError: true);
      return;
    }

    if (members.isEmpty) {
      _showSnackBar('لا يوجد أعضاء مطابقون للفلتر المحدد', isError: true);
      return;
    }

    // تأكيد الإرسال
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('تأكيد الإرسال الجماعي'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('سيتم إرسال رسائل إلى ${members.length} عضو.'),
            const SizedBox(height: 8),
            Text('التأخير بين كل رسالة: ${_botService.bulkDelay} ثواني'),
            const SizedBox(height: 8),
            Text(
              'الوقت المتوقع: ${(members.length * _botService.bulkDelay / 60).toStringAsFixed(1)} دقيقة',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ملاحظة: يمكنك التنقل في البرنامج ومتابعة عملك؛ سيستمر الإرسال تلقائياً في الخلفية.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('بدء الإرسال'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final items = members.map((m) {
      return {
        'phone': m.phoneNumber!,
        'message': _buildMessageForMember(m),
        'name': m.fullName,
      };
    }).toList();

    _botService.sendBulkMessages(items);
  }

  void _showSnackBar(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // مساعدات
  // ═══════════════════════════════════════════════════════════════════════════

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }

  String _filterLabel(String filter) {
    switch (filter) {
      case 'expired':
        return 'منتهي الاشتراك';
      case 'expiring_soon':
        return 'قريب الانتهاء';
      case 'debt':
        return 'عليه ديون';
      case 'active':
        return 'نشط';
      case 'all':
        return 'الكل';
      default:
        return filter;
    }
  }

  String _templateLabel(String template) {
    switch (template) {
      case 'expired':
        return 'تنبيه انتهاء';
      case 'expiring_soon':
        return 'تذكير تجديد';
      case 'debt':
        return 'تنبيه ديون';
      case 'active_reminder':
        return 'ميعاد التجديد';
      case 'welcome':
        return 'رسالة ترحيب';
      case 'custom':
        return 'رسالة مخصصة';
      default:
        return template;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // واجهة المستخدم
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return SidebarLayout(
      activePage: 'whatsapp_tool',
      title: 'أداة إرسال واتساب (تشغيل دائم في الخلفية)',
      actions: [
        if (_botService.isConnected)
          Chip(
            avatar: const Icon(Icons.circle, color: Colors.green, size: 12),
            label: const Text('متصل بالخلفية', style: TextStyle(fontSize: 12)),
            backgroundColor: Colors.green.withValues(alpha: 0.1),
          )
        else if (_botService.isConnecting)
          Chip(
            avatar: const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            label: const Text('جاري الاتصال...', style: TextStyle(fontSize: 12)),
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
          )
        else
          Chip(
            avatar: Icon(Icons.circle, color: Colors.grey[400], size: 12),
            label: const Text('غير متصل', style: TextStyle(fontSize: 12)),
            backgroundColor: Colors.grey.withValues(alpha: 0.1),
          ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════ تخطيط رئيسي ═══════
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // العمود الأيمن في RTL
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildConnectionSection(theme, isDark, primary),
                            const SizedBox(height: 20),
                            _buildSingleMessageSection(theme, isDark, primary),
                            const SizedBox(height: 20),
                            _buildBulkMessageSection(theme, isDark, primary),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // العمود الأيسر
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildSettingsSection(theme, isDark, primary),
                            const SizedBox(height: 20),
                            _buildLogSection(theme, isDark, primary),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                // شاشة صغيرة
                return Column(
                  children: [
                    _buildConnectionSection(theme, isDark, primary),
                    const SizedBox(height: 20),
                    _buildSettingsSection(theme, isDark, primary),
                    const SizedBox(height: 20),
                    _buildSingleMessageSection(theme, isDark, primary),
                    const SizedBox(height: 20),
                    _buildBulkMessageSection(theme, isDark, primary),
                    const SizedBox(height: 20),
                    _buildLogSection(theme, isDark, primary),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── قسم الاتصال ─────────────────────────────────────────────────────────
  Widget _buildConnectionSection(ThemeData theme, bool isDark, Color primary) {
    final isConnected = _botService.isConnected;
    final isConnecting = _botService.isConnecting;

    return _buildCard(
      theme: theme,
      isDark: isDark,
      title: 'الاتصال بـ WhatsApp',
      icon: Icons.link_rounded,
      iconColor: isConnected ? Colors.green : primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // حالة الاتصال
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.green.withValues(alpha: 0.08)
                  : (isDark
                      ? Colors.grey[800]!.withValues(alpha: 0.5)
                      : Colors.grey[100]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isConnected
                      ? Icons.check_circle_rounded
                      : (isConnecting
                          ? Icons.sync_rounded
                          : Icons.info_outline_rounded),
                  color: isConnected ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _botService.connectionStatus,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isConnected ? Colors.green : null,
                    ),
                  ),
                ),
                if (isConnecting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // QR Code عند الحاجة
          if (_botService.qrCodeBytes != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Image.memory(_botService.qrCodeBytes!, width: 220, height: 220),
                    const SizedBox(height: 12),
                    const Text(
                      'امسح الكود من تطبيق واتساب على هاتفك',
                      style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'الإعدادات ← الأجهزة المرتبطة ← ربط جهاز',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // أزرار التحكم في الاتصال والحساب
          Row(
            children: [
              // حالة غير متصل
              if (!isConnected && !isConnecting) ...[
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.power_settings_new_rounded, size: 20),
                    label: const Text('بدء الاتصال'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _botService.connect(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.switch_account_rounded, size: 18, color: Colors.orange),
                    label: const Text('تغيير الحساب', style: TextStyle(color: Colors.orange)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _confirmSwitchAccount(context),
                  ),
                ),
              ],

              // حالة متصل
              if (isConnected) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.pause_circle_outline_rounded, size: 20),
                    label: const Text('إيقاف مؤقت'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _botService.disconnect(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.switch_account_rounded, size: 20, color: Colors.orange),
                    label: const Text('تغيير الحساب', style: TextStyle(color: Colors.orange)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _confirmSwitchAccount(context),
                  ),
                ),
              ],

              // حالة جاري الاتصال
              if (isConnecting) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    label: const Text('جاري الاتصال...'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── قسم الإرسال الفردي ───────────────────────────────────────────────────
  Widget _buildSingleMessageSection(
    ThemeData theme,
    bool isDark,
    Color primary,
  ) {
    return _buildCard(
      theme: theme,
      isDark: isDark,
      title: 'إرسال رسالة فردية',
      icon: Icons.chat_bubble_outline_rounded,
      iconColor: Colors.blue,
      child: Column(
        children: [
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: 'رقم الهاتف (مع كود الدولة)',
              hintText: 'مثال: 01012345678 أو 201012345678',
              hintTextDirection: TextDirection.ltr,
              prefixIcon: const Icon(Icons.phone_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'نص الرسالة',
              hintText: 'اكتب رسالتك هنا...',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.message_rounded, size: 20),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('إرسال الآن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _botService.isConnected ? _sendSingleMessage : null,
            ),
          ),
        ],
      ),
    );
  }

  // ─── قسم الإرسال الجماعي ──────────────────────────────────────────────────
  Widget _buildBulkMessageSection(ThemeData theme, bool isDark, Color primary) {
    return BlocBuilder<MembersCubit, MembersState>(
      builder: (context, membersState) {
        List<Member> allMembers = [];
        if (membersState is MembersLoaded) {
          allMembers = membersState.allMembers;
        }
        final filteredMembers = _getFilteredMembers(allMembers);

        return _buildCard(
          theme: theme,
          isDark: isDark,
          title: 'إرسال تنبيهات جماعية في الخلفية',
          icon: Icons.campaign_rounded,
          iconColor: Colors.orange,
          badge: '${filteredMembers.length} عضو',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // فلتر الأعضاء
              const Text(
                'فلترة الأعضاء:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['expired', 'expiring_soon', 'debt', 'active', 'all']
                    .map((filter) {
                      final isSelected = _bulkFilter == filter;
                      return ChoiceChip(
                        label: Text(_filterLabel(filter)),
                        selected: isSelected,
                        selectedColor: primary.withValues(alpha: 0.2),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _bulkFilter = filter;
                              if (filter == 'expired') _bulkTemplate = 'expired';
                              if (filter == 'expiring_soon') _bulkTemplate = 'expiring_soon';
                              if (filter == 'debt') _bulkTemplate = 'debt';
                              if (filter == 'active') _bulkTemplate = 'active_reminder';
                              if (filter == 'all') _bulkTemplate = 'welcome';
                            });
                          }
                        },
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 16),

              // قالب الرسالة
              const Text(
                'قالب الرسالة:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'welcome',
                  'expired',
                  'expiring_soon',
                  'debt',
                  'active_reminder',
                  'custom',
                ].map((template) {
                  final isSelected = _bulkTemplate == template;
                  return ChoiceChip(
                    label: Text(_templateLabel(template)),
                    selected: isSelected,
                    selectedColor: primary.withValues(alpha: 0.2),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _bulkTemplate = template);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // حقل الرسالة المخصصة
              if (_bulkTemplate == 'custom') ...[
                TextField(
                  controller: _customMsgCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'الرسالة المخصصة',
                    hintText: 'مرحباً {name}، اشتراكك في {membership} ...',
                    helperText:
                        'المتغيرات المتاحة: {name} {membership} {end_date} {remaining} {days}',
                    helperMaxLines: 2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // معاينة الرسالة
              if (filteredMembers.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[800]!.withValues(alpha: 0.5)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معاينة الرسالة (${filteredMembers.first.fullName}):',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _buildMessageForMember(filteredMembers.first),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // شريط تقدم الإرسال
              if (_botService.isSendingBulk) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: _botService.bulkTotal > 0
                          ? (_botService.bulkSent + _botService.bulkFailed) /
                              _botService.bulkTotal
                          : 0,
                      backgroundColor: isDark
                          ? Colors.grey[700]
                          : Colors.grey[200],
                      color: Colors.green,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'نجح: ${_botService.bulkSent} | فشل: ${_botService.bulkFailed} | إجمالي: ${_botService.bulkTotal}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${((_botService.bulkSent + _botService.bulkFailed) / (_botService.bulkTotal == 0 ? 1 : _botService.bulkTotal) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // أزرار الإرسال
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(
                        _botService.isSendingBulk
                            ? Icons.stop_rounded
                            : Icons.send_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _botService.isSendingBulk
                            ? 'إيقاف الإرسال الجماعي'
                            : 'إرسال لـ ${filteredMembers.length} عضو',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _botService.isSendingBulk
                            ? Colors.red
                            : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: !_botService.isConnected
                          ? null
                          : _botService.isSendingBulk
                              ? () => _botService.stopBulkSending()
                              : () => _sendBulkMessages(filteredMembers),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── قسم الإعدادات ────────────────────────────────────────────────────────
  Widget _buildSettingsSection(ThemeData theme, bool isDark, Color primary) {
    return _buildCard(
      theme: theme,
      isDark: isDark,
      title: 'إعدادات الخدمة الخلفية',
      icon: Icons.tune_rounded,
      iconColor: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اتصال تلقائي عند فتح التطبيق
          SwitchListTile(
            title: const Text(
              'اتصال تلقائي عند بدء البرنامج',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'يبدأ الاتصال بالواتساب فور فتح التطبيق في الخلفية دون الحاجة للضغط يدوياً',
              style: TextStyle(fontSize: 12),
            ),
            value: _botService.autoConnect,
            onChanged: (val) => _botService.setAutoConnect(val),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),

          // Headless toggle
          SwitchListTile(
            title: const Text(
              'تشغيل مخفي (Headless)',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: const Text(
              'إخفاء نافذة متصفح Chrome أثناء العمل والاتصال',
              style: TextStyle(fontSize: 12),
            ),
            value: _botService.headless,
            onChanged: _botService.isConnected
                ? null
                : (val) => _botService.setHeadless(val),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),

          // مسار Chrome
          TextField(
            controller: _chromePathCtrl,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 13),
            onChanged: (val) => _botService.setChromePath(val),
            decoration: InputDecoration(
              labelText: 'مسار متصفح Chrome/Edge (اختياري)',
              hintText: r'C:\Program Files\Google\Chrome\Application\chrome.exe',
              hintTextDirection: TextDirection.ltr,
              hintStyle: const TextStyle(fontSize: 11),
              prefixIcon: const Icon(Icons.folder_open_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              helperText: 'اتركه فارغاً للاكتشاف التلقائي لـ Chrome أو Edge',
            ),
          ),
          const SizedBox(height: 16),

          // تأخير الإرسال الجماعي
          Row(
            children: [
              const Expanded(
                child: Text(
                  'التأخير بين الرسائل الجماعية (ثواني):',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              SizedBox(
                width: 80,
                child: DropdownButtonFormField<int>(
                  initialValue: _botService.bulkDelay,
                  items: [3, 5, 8, 10, 15, 20, 30].map((val) {
                    return DropdownMenuItem(value: val, child: Text('$val'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _botService.setBulkDelay(val);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── قسم سجل النشاط ──────────────────────────────────────────────────────
  Widget _buildLogSection(ThemeData theme, bool isDark, Color primary) {
    final logs = _botService.logs;

    return _buildCard(
      theme: theme,
      isDark: isDark,
      title: 'سجل النشاط المستمر',
      icon: Icons.terminal_rounded,
      iconColor: Colors.teal,
      trailing: logs.isNotEmpty
          ? TextButton.icon(
              icon: const Icon(Icons.delete_sweep_rounded, size: 16),
              label: const Text('مسح', style: TextStyle(fontSize: 12)),
              onPressed: () => _botService.clearLogs(),
            )
          : null,
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        child: logs.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد سجلات حالياً...',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              )
            : ListView.builder(
                controller: _logScrollCtrl,
                padding: const EdgeInsets.all(12),
                itemCount: logs.length,
                itemBuilder: (ctx, idx) {
                  final log = logs[idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(log.type.icon, size: 14, color: log.type.color),
                        const SizedBox(width: 8),
                        Text(
                          '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            log.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: log.type.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  // ─── بطاقة عامة ──────────────────────────────────────────────────────────
  Widget _buildCard({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    String? badge,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11,
                        color: iconColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                ?trailing,
              ],
            ),
          ),
          Divider(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            height: 1,
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}
