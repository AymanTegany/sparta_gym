import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../core/common/widgets/sidebar_layout.dart';
import '../../domain/entities/member_entity.dart';
import '../cubit/members_cubit.dart';
import '../cubit/members_state.dart';
import '../widgets/add_member_dialog.dart';
import '../widgets/member_details_dialog.dart';
import '../widgets/renew_subscription_dialog.dart';
import '../../../payments/presentation/cubit/payments_cubit.dart';
import '../../../payments/domain/entities/payment_entity.dart';
import '../../../payments/presentation/widgets/receipt_dialog.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../widgets/members_data_table.dart';
import '../widgets/members_filter_bar.dart';
import '../widgets/members_stats_cards.dart';
import '../widgets/print_member_invoice.dart';
import '../../../payments/presentation/widgets/add_payment_dialog.dart';
import '../widgets/member_card_print.dart';
import '../../../diets/presentation/cubit/diet_plans_cubit.dart';
import '../../../expenses/presentation/cubit/expenses_cubit.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../shifts/presentation/cubit/shifts_cubit.dart';
import '../../../../core/services/whatsapp_api_service.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// شاشة إدارة العملاء (Members Management Page)
/// ──────────────────────────────────────────────────────────────────────────────
/// الصفحة الرئيسية لعرض وتصفية وإدارة المشتركين في الجيم.
class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // تحميل المشتركين والأنظمة الغذائية عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MembersCubit>().loadMembers();
      context.read<DietPlansCubit>().fetchDietPlans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddMemberDialog(
        onSave:
            (
              newMember,
              paymentMethod, {
              bool printInvoice = false,
              bool shareWhatsapp = false,
            }) async {
              // الحصول على اسم الموظف الحالي
              String employeeName = 'موظف';
              final authState = context.read<AuthCubit>().state;
              if (authState is AuthAuthenticated) {
                employeeName = authState.user.fullName.isNotEmpty
                    ? authState.user.fullName
                    : authState.user.username;
              }

              // 1. حفظ العضو مؤقتاً بمدفوع = 0 ومتبقي = الصافي كامل
              final memberToSave = newMember.copyWith(
                paidAmount: 0,
                remainingAmount: newMember.netPrice,
              );

              final success = await context.read<MembersCubit>().addMember(
                memberToSave,
                refreshList: newMember.paidAmount == 0,
              );

              // 2. إذا نجح الحفظ وكان هناك مبلغ مدفوع، نسجل الدفعة لإنشاء إيصال وتحديث الأرصدة
              Payment? generatedPayment;
              if (success && newMember.paidAmount > 0) {
                generatedPayment = await context
                    .read<PaymentsCubit>()
                    .recordPayment(
                      memberId: newMember.memberId,
                      amount: newMember.paidAmount,
                      paymentMethod: paymentMethod,
                      employeeName: employeeName,
                      notes: 'دفعة أولى عند الاشتراك',
                    );
                if (context.mounted) {
                  await context.read<MembersCubit>().loadMembers();
                }
              }

              if (shareWhatsapp && context.mounted) {
                // إنشاء كائن Payment للمعاينة حتى لو لم يكن هناك مدفوعات
                final paymentToShare =
                    generatedPayment ??
                    Payment(
                      receiptId: 'REC-${DateTime.now().millisecondsSinceEpoch}',
                      memberId: newMember.memberId,
                      memberName: newMember.fullName,
                      memberPhone: newMember.phoneNumber,
                      amount: newMember.paidAmount,
                      paymentMethod: paymentMethod,
                      paymentDate: DateTime.now().toIso8601String(),
                      employeeName: employeeName,
                      notes: 'اشتراك باقة ${newMember.membershipType}',
                    );
                // لضمان وجود البيانات في المعاينة (الاسم ورقم الهاتف)
                final previewPayment = Payment(
                  id: paymentToShare.id,
                  receiptId: paymentToShare.receiptId,
                  memberId: paymentToShare.memberId,
                  memberName: paymentToShare.memberName ?? newMember.fullName,
                  memberPhone:
                      paymentToShare.memberPhone ?? newMember.phoneNumber,
                  amount: paymentToShare.amount,
                  paymentMethod: paymentToShare.paymentMethod,
                  paymentDate: paymentToShare.paymentDate,
                  employeeName: paymentToShare.employeeName,
                  notes: paymentToShare.notes,
                );
                showDialog(
                  context: context,
                  builder: (_) => ReceiptDialog(payment: previewPayment),
                );
              }

              if (printInvoice && context.mounted) {
                await printMemberA4Invoice(context, newMember);
              }
            },
      ),
    );
  }

  /// فتح ديالوج تعديل بيانات مشترك حالي
  void _showEditMemberDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddMemberDialog(
        member: member,
        onSave:
            (
              updatedMember,
              paymentMethod, {
              bool printInvoice = false,
              bool shareWhatsapp = false,
            }) {
              context.read<MembersCubit>().updateMember(updatedMember);
            },
      ),
    );
  }

  /// فتح ديالوج تعديل رقم العضوية فقط
  void _showEditMemberIdDialog(BuildContext context, Member member) {
    final ctrl = TextEditingController(text: member.memberId);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.tag_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text('تعديل رقم العضوية'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'العميل: ${member.fullName}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'رقم العضوية (الباركود)',
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'رقم العضوية مطلوب';
                    }
                    final state = context.read<MembersCubit>().state;
                    if (state is MembersLoaded) {
                      final exists = state.allMembers.any((m) {
                        if (m.id == member.id) return false;
                        return m.memberId.trim().toLowerCase() ==
                            v.trim().toLowerCase();
                      });
                      if (exists) {
                        return 'هذا الرقم مسجل لعضو آخر بالفعل';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final updatedMember = member.copyWith(
                    memberId: ctrl.text.trim(),
                  );
                  context.read<MembersCubit>().updateMember(updatedMember);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم تحديث رقم العضوية بنجاح'),
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  /// فتح ديالوج تفاصيل المشترك
  void _showDetailsDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (dialogContext) => MemberDetailsDialog(
        member: member,
        onEdit: () {
          _showEditMemberDialog(context, member);
        },
        onDelete: () {
          _showDeleteConfirmDialog(context, member);
        },
        onRenew: () {
          _showRenewDialog(context, member);
        },
        onAddPayment: () {
          _showAddPaymentDialog(context, member);
        },
      ),
    );
  }

  /// فتح ديالوج تأكيد الحذف
  void _showDeleteConfirmDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('حذف العميل', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في حذف العميل "${member.fullName}"؟\nلا يمكن التراجع عن هذا الإجراء وسيتم حذف جميع سجلاته نهائياً.',
            style: const TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<MembersCubit>().deleteMember(member.id!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف نهائي'),
            ),
          ],
        );
      },
    );
  }

  /// فتح ديالوج ارجاع مبلغ الاشتراك وحذف العميل
  void _showRefundAndDeleteDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.money_off_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                'ارجاع اشتراك وحذف العميل',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في الغاء اشتراك العميل "${member.fullName}" وحذفه؟\nسيتم حذف العميل وكل مدفوعاته نهائياً، وكأنها لم تسجل.',
            style: const TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                // Delete member (and cascade delete payments)
                context.read<MembersCubit>().deleteMember(member.id!);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم الغاء الاشتراك وحذف العميل بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('الغاء الاشتراك وحذف'),
            ),
          ],
        );
      },
    );
  }

  /// فتح ديالوج تجديد الاشتراك
  void _showRenewDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RenewSubscriptionDialog(
        member: member,
        onRenew:
            ({
              required membershipType,
              required price,
              required discount,
              required paidAmount,
              required startDate,
              required endDate,
              required paymentMethod,
            }) async {
              // الحصول على اسم الموظف الحالي
              String employeeName = 'موظف';
              final authState = context.read<AuthCubit>().state;
              if (authState is AuthAuthenticated) {
                employeeName = authState.user.fullName.isNotEmpty
                    ? authState.user.fullName
                    : authState.user.username;
              }

              // 1. تجديد الاشتراك بوضع مبلغ مدفوع = 0، ومتبقي = الصافي الجديد
              final success = await context
                  .read<MembersCubit>()
                  .renewSubscription(
                    member: member,
                    newMembershipType: membershipType,
                    newPrice: price,
                    newDiscount: discount,
                    newPaidAmount: 0,
                    newStartDate: startDate,
                    newEndDate: endDate,
                    refreshList: paidAmount == 0,
                  );

              // 2. إذا تم التجديد بنجاح وكان هناك مبلغ مدفوع، سجل الدفعة
              if (success && paidAmount > 0) {
                await context.read<PaymentsCubit>().recordPayment(
                  memberId: member.memberId,
                  amount: paidAmount,
                  paymentMethod: paymentMethod,
                  employeeName: employeeName,
                  notes: 'تجديد اشتراك: $membershipType',
                );
                if (context.mounted) {
                  await context.read<MembersCubit>().loadMembers();
                }
              }
            },
      ),
    );
  }

  /// فتح ديالوج إضافة دفعة
  void _showAddPaymentDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddPaymentDialog(member: member),
    );
  }

  /// فتح معاينة وطباعة بطاقة العضوية
  void _showPrintCardDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (dialogContext) => MemberCardPrint(member: member),
    );
  }

  /// إرسال تنبيه عبر واتساب
  Future<void> _sendWhatsAppAlert(Member member) async {
    if (member.phoneNumber == null || member.phoneNumber!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم الهاتف غير متوفر للعميل')),
        );
      }
      return;
    }

    String phone = member.phoneNumber!;
    // تأكد من أن الرقم يبدأ برمز الدولة، يمكنك تعديل هذا حسب الدولة الافتراضية
    if (phone.startsWith('0')) {
      phone = '+20${phone.substring(1)}'; // افتراض أن الدولة مصر
    } else if (!phone.startsWith('+')) {
      phone = '+20$phone';
    }

    // تجهيز الرسالة
    String message = 'أهلاً كابتن ${member.fullName}،\n\n';

    if (!member.isActive) {
      message +=
          'نود تذكيرك بأن اشتراكك في باقة ${member.membershipType} قد انتهى بتاريخ ${_formatDate(member.endDate)}.\n';
      message += 'نتمنى رؤيتك قريباً في الجيم لتجديد الاشتراك! 💪';
    } else if (member.isExpiringSoon) {
      message =
          'مرحباً ${member.fullName}، اشتراكك في الجيم هينتهي خلال ${member.remainingDays} أيام. جدد اشتراكك دلوقتي عشان تكمل تدريبك من غير انقطاع.';
    } else if (member.hasDebt) {
      message +=
          'نود تذكيرك بوجود مبلغ متبقي على اشتراكك بقيمة ${member.remainingAmount.toStringAsFixed(0)} ج.م.\n';
      message += 'يرجى تسوية المبلغ في أقرب وقت. شكراً لك! 🙏';
    } else {
      message += 'نتمنى لك يوماً رياضياً سعيداً في الجيم! 💪\n\n';
      message +=
          'تفاصيل اشتراكك:\n- الباقة: ${member.membershipType}\n- تاريخ الانتهاء: ${_formatDate(member.endDate)}';
    }

    if (!context.mounted) return;

    final TextEditingController messageController = TextEditingController(
      text: message,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.chat_rounded, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text(
                'رسالة واتساب',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'يمكنك تعديل محتوى الرسالة قبل الإرسال:',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'في حال تفعيل الـ API، سيتم استخدام قالب (Template) معتمد ولن يتم تطبيق أي تعديل يدوي هنا.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 8,
                  minLines: 4,
                  readOnly: true,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final finalMessage = messageController.text;

                final settingsState = context.read<SettingsCubit>().state;
                String accessToken = '';
                String phoneNumberId = '';
                if (settingsState is SettingsLoaded) {
                  accessToken = settingsState.settings.whatsappAccessToken;
                  phoneNumberId = settingsState.settings.whatsappPhoneNumberId;
                }

                if (accessToken.isNotEmpty && phoneNumberId.isNotEmpty) {
                  String? errorMsg;
                  if (!member.isActive) {
                    errorMsg = await WhatsappApiService().sendTemplateMessage(
                      phoneNumber: phone,
                      templateName: 'subscription_expired',
                      parameters: [
                        member.fullName,
                        member.membershipType,
                        _formatDate(member.endDate),
                      ],
                      accessToken: accessToken,
                      phoneNumberId: phoneNumberId,
                      languageCode: 'ar_EG', // Uses Arabic (Egypt)
                    );
                  } else if (member.isExpiringSoon) {
                    errorMsg = await WhatsappApiService().sendTemplateMessage(
                      phoneNumber: phone,
                      templateName: 'gym_management_system',
                      parameters: [
                        member.fullName,
                        member.remainingDays.toString(),
                      ],
                      accessToken: accessToken,
                      phoneNumberId: phoneNumberId,
                    );
                  } else if (member.hasDebt) {
                    errorMsg = await WhatsappApiService().sendTemplateMessage(
                      phoneNumber: phone,
                      templateName: 'debt_alert',
                      parameters: [
                        member.fullName,
                        member.remainingAmount.toStringAsFixed(0),
                      ],
                      accessToken: accessToken,
                      phoneNumberId: phoneNumberId,
                    );
                  } else {
                    errorMsg = await WhatsappApiService().sendTemplateMessage(
                      phoneNumber: phone,
                      templateName: 'active_subscription_info',
                      parameters: [
                        member.fullName,
                        member.membershipType,
                        _formatDate(member.endDate),
                      ],
                      accessToken: accessToken,
                      phoneNumberId: phoneNumberId,
                    );
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          errorMsg ?? 'تم إرسال رسالة واتساب بنجاح',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: errorMsg == null
                            ? Colors.green
                            : Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                } else {
                  final url = Uri.parse(
                    'https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(finalMessage)}',
                  );

                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('لا يمكن فتح تطبيق واتساب'),
                        ),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('إرسال الآن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// إرسال جماعي للمشتركين حسب الفلتر
  Future<void> _sendBulkWhatsAppAlert(
    List<Member> members,
    MemberFilterType filterType,
  ) async {
    final settingsState = context.read<SettingsCubit>().state;
    String accessToken = '';
    String phoneNumberId = '';
    if (settingsState is SettingsLoaded) {
      accessToken = settingsState.settings.whatsappAccessToken;
      phoneNumberId = settingsState.settings.whatsappPhoneNumberId;
    }

    if (accessToken.isEmpty || phoneNumberId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'يجب إعداد بيانات WhatsApp API في الإعدادات للإرسال الجماعي.',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
      return;
    }

    // Show confirmation
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.group_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('تأكيد الإرسال الجماعي'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من إرسال رسائل واتساب إلى (${members.length}) مشترك؟ .',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('نعم، أرسل للكل'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    // Show progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(
              'جاري الإرسال... يرجى الانتظار وعدم إغلاق النافذة.',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ],
        ),
      ),
    );

    int successCount = 0;
    int failCount = 0;

    for (final member in members) {
      if (member.phoneNumber == null || member.phoneNumber!.isEmpty) {
        failCount++;
        continue;
      }

      String phone = member.phoneNumber!;
      if (phone.startsWith('0')) {
        phone = '+20${phone.substring(1)}';
      } else if (!phone.startsWith('+')) {
        phone = '+20$phone';
      }

      String? errorMsg;
      if (filterType == MemberFilterType.expired) {
        errorMsg = await WhatsappApiService().sendTemplateMessage(
          phoneNumber: phone,
          templateName: 'subscription_expired',
          parameters: [
            member.fullName,
            member.membershipType,
            _formatDate(member.endDate),
          ],
          accessToken: accessToken,
          phoneNumberId: phoneNumberId,
          languageCode: 'ar_EG',
        );
      } else if (filterType == MemberFilterType.expiringSoon) {
        errorMsg = await WhatsappApiService().sendTemplateMessage(
          phoneNumber: phone,
          templateName: 'gym_management_system',
          parameters: [member.fullName, member.remainingDays.toString()],
          accessToken: accessToken,
          phoneNumberId: phoneNumberId,
        );
      }

      if (errorMsg == null) {
        successCount++;
      } else {
        failCount++;
      }

      // Small delay to avoid API rate limiting (10-15 messages per second is Meta's limit, we'll do ~3 per second)
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (context.mounted) {
      Navigator.pop(context); // close progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'اكتمل الإرسال الجماعي: $successCount نجاح، $failCount فشل.',
          ),
          backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// إرسال رسالة ترحيب عبر واتساب
  Future<void> _sendWelcomeMessage(Member member) async {
    if (member.phoneNumber == null || member.phoneNumber!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم الهاتف غير متوفر للعميل')),
        );
      }
      return;
    }

    String phone = member.phoneNumber!;
    if (phone.startsWith('0')) {
      phone = '+20${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      phone = '+20$phone';
    }

    String message = 'أهلاً بك كابتن ${member.fullName} في عائلة الجيم! 🎉\n\n';
    message += 'يسعدنا انضمامك إلينا في باقة ${member.membershipType}.\n';
    message += 'تاريخ بداية الاشتراك: ${_formatDate(member.startDate)}\n';
    message += 'تاريخ نهاية الاشتراك: ${_formatDate(member.endDate)}\n\n';
    message += 'نتمنى لك تجربة رياضية ممتعة وتحقيق كل أهدافك! 💪🏋️‍♂️';

    if (!context.mounted) return;

    final TextEditingController messageController = TextEditingController(
      text: message,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.waving_hand_rounded, color: Colors.blue, size: 28),
              SizedBox(width: 10),
              Text(
                'رسالة ترحيب',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'يمكنك تعديل محتوى الرسالة قبل الإرسال:',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'في حال تفعيل الـ API، سيتم استخدام قالب (Template) معتمد ولن يتم تطبيق أي تعديل يدوي هنا.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 8,
                  minLines: 4,
                  readOnly: true,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final finalMessage = messageController.text;

                final settingsState = context.read<SettingsCubit>().state;
                String accessToken = '';
                String phoneNumberId = '';
                if (settingsState is SettingsLoaded) {
                  accessToken = settingsState.settings.whatsappAccessToken;
                  phoneNumberId = settingsState.settings.whatsappPhoneNumberId;
                }

                if (accessToken.isNotEmpty && phoneNumberId.isNotEmpty) {
                  final errorMsg = await WhatsappApiService()
                      .sendTemplateMessage(
                        phoneNumber: phone,
                        templateName: 'welcome_new_member',
                        parameters: [
                          member.fullName,
                          member.membershipType,
                          _formatDate(member.startDate),
                          _formatDate(member.endDate),
                        ],
                        accessToken: accessToken,
                        phoneNumberId: phoneNumberId,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          errorMsg ?? 'تم إرسال رسالة واتساب بنجاح',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: errorMsg == null
                            ? Colors.green
                            : Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                } else {
                  final url = Uri.parse(
                    'https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(finalMessage)}',
                  );

                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('لا يمكن فتح تطبيق واتساب'),
                        ),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('إرسال الآن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// تنسيق التاريخ
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy/MM/dd').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// حساب عدد العناصر لكل نوع فلترة
  Map<MemberFilterType, int> _calculateFilterCounts(List<Member> members) {
    return {
      MemberFilterType.all: members.length,
      MemberFilterType.active: members.where((m) => m.isActive).length,
      MemberFilterType.expired: members
          .where((m) => !m.isActive && m.membershipType != 'تمرينة واحدة')
          .length,
      MemberFilterType.expiringSoon: members
          .where((m) => m.isExpiringSoon)
          .length,
      MemberFilterType.inDebt: members.where((m) => m.hasDebt).length,
      MemberFilterType.singleSession: members
          .where((m) => m.membershipType == 'تمرينة واحدة')
          .length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SidebarLayout(
      activePage: 'members',
      title: 'إدارة العملاء والمشتركين',
      actions: [
        // زر إضافة مشترك جديد
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAddMemberDialog(context),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('إضافة مشترك جديد'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        // زر تحديث البيانات
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'تحديث البيانات',
          onPressed: () => context.read<MembersCubit>().loadMembers(),
        ),
      ],
      body: BlocConsumer<MembersCubit, MembersState>(
        listener: (context, state) {
          // عرض رسائل النجاح
          if (state is MemberActionSuccess) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: ColorPalette.activeStatus,
                ),
              );
          }
          // عرض رسائل الخطأ
          if (state is MembersError) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
          }
        },
        builder: (context, state) {
          // جلب البيانات من حالة loaded الفعالة
          MembersLoaded? loadedState;
          if (state is MembersLoaded) {
            loadedState = state;
          } else if (context.read<MembersCubit>().state is MembersLoaded) {
            loadedState = context.read<MembersCubit>().state as MembersLoaded;
          }

          if (state is MembersLoading && loadedState == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (loadedState == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('لا توجد بيانات عملاء بعد'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<MembersCubit>().loadMembers(),
                    child: const Text('تحميل البيانات'),
                  ),
                ],
              ),
            );
          }

          final counts = _calculateFilterCounts(loadedState.allMembers);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. بطاقات الإحصائيات الفعالة
                  MembersStatsCards(stats: loadedState.stats),
                  const SizedBox(height: 20),

                  // 2. شريط الأدوات: البحث والفلترة
                  Row(
                    children: [
                      // حقل البحث
                      Expanded(
                        child: Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => context
                                  .read<MembersCubit>()
                                  .searchMembers(val),
                              decoration: InputDecoration(
                                hintText:
                                    'البحث عن طريق الاسم، رقم الهاتف، أو رقم العضوية...',
                                border: InputBorder.none,
                                icon: Icon(
                                  Icons.search_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded),
                                        onPressed: () {
                                          _searchController.clear();
                                          context
                                              .read<MembersCubit>()
                                              .searchMembers('');
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // شريط الفلاتر الدائري
                  MembersFilterBar(
                    currentFilter: loadedState.filterType,
                    filterCounts: counts,
                    onFilterChanged: (filter) {
                      context.read<MembersCubit>().filterMembers(filter);
                    },
                  ),

                  if ((loadedState.filterType == MemberFilterType.expired ||
                          loadedState.filterType ==
                              MemberFilterType.expiringSoon) &&
                      loadedState.displayedMembers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _sendBulkWhatsAppAlert(
                              loadedState!.displayedMembers,
                              loadedState!.filterType,
                            ),
                            icon: const Icon(Icons.group_rounded, size: 18),
                            label: Text(
                              'إرسال تنبيه للكل (${loadedState.displayedMembers.length})',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 3. جدول البيانات الرئيسي
                  Expanded(
                    child: Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: MembersDataTable(
                        members: loadedState.displayedMembers,
                        onEdit: (m) => _showEditMemberDialog(context, m),
                        onDelete: (m) => _showDeleteConfirmDialog(context, m),
                        onViewDetails: (m) => _showDetailsDialog(context, m),
                        onRenew: (m) => _showRenewDialog(context, m),
                        onAddPayment: (m) => _showAddPaymentDialog(context, m),
                        onPrintCard: (m) => _showPrintCardDialog(context, m),
                        onWhatsAppAlert: (m) => _sendWhatsAppAlert(m),
                        onWelcomeMessage: (m) => _sendWelcomeMessage(m),
                        onRefundAndDelete: (m) =>
                            _showRefundAndDeleteDialog(context, m),
                        onEditMemberId: (m) =>
                            _showEditMemberIdDialog(context, m),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
