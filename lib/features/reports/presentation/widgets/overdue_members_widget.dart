import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/comprehensive_report_data.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/services/whatsapp_api_service.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OverdueMembersWidget extends StatelessWidget {
  final List<OverdueMemberItem> overdueMembers;

  const OverdueMembersWidget({
    super.key,
    required this.overdueMembers,
  });

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _sendWhatsapp(BuildContext context, String phone, String name, double amount) async {
    // تنسيق رسالة تذكير باللغة العربية
    final text = 'السلام عليكم يا أستاذ $name، تذكير لطيف من Sparta Gym بأن هناك مبلغ متبقي من اشتراكك وقدره $amount ج.م. نسعد بتواجدك معنا دائماً.';
    
    final settingsState = context.read<SettingsCubit>().state;
    String accessToken = '';
    String phoneNumberId = '';
    if (settingsState is SettingsLoaded) {
      accessToken = settingsState.settings.whatsappAccessToken;
      phoneNumberId = settingsState.settings.whatsappPhoneNumberId;
    }

    if (accessToken.isNotEmpty && phoneNumberId.isNotEmpty) {
      final errorMsg = await WhatsappApiService().sendMessage(
        phoneNumber: phone,
        message: text,
        accessToken: accessToken,
        phoneNumberId: phoneNumberId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg ?? 'تم إرسال تذكير واتساب بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: errorMsg == null ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      final whatsappUrl = Uri.parse('https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(text)}');
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن فتح تطبيق واتساب', style: TextStyle(fontFamily: 'Cairo'))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final numberFormat = intl.NumberFormat('#,##0', 'ar');
    final dateFormat = intl.DateFormat('yyyy/MM/dd', 'ar');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تقرير المستحقات والمديونيات المتأخرة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorPalette.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'إجمالي المتأخرات: ${numberFormat.format(overdueMembers.fold(0.0, (sum, item) => sum + item.remainingAmount))} ج',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.errorColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (overdueMembers.isEmpty)
            SizedBox(
              height: 150,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 48,
                      color: ColorPalette.activeStatus.withOpacity(0.6),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'لا توجد مديونيات متأخرة على الأعضاء حالياً',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowColor: MaterialStateProperty.all(
                      isDark ? ColorPalette.tableHeaderDark : Colors.grey.shade100,
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'الاسم',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'نوع الباقة',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'المبلغ المتبقي',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'تاريخ البدء',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'إجراءات',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: overdueMembers.map((member) {
                      final parsedDate = DateTime.tryParse(member.startDate);
                      final formattedDate = parsedDate != null ? dateFormat.format(parsedDate) : member.startDate;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              member.fullName,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              member.membershipType,
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${numberFormat.format(member.remainingAmount)} ج',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                color: ColorPalette.errorColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              formattedDate,
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (member.phoneNumber.isNotEmpty) ...[
                                  IconButton(
                                    icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 18),
                                    onPressed: () => _makeCall(member.phoneNumber),
                                    tooltip: 'اتصال هاتفى',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.teal, size: 18),
                                    onPressed: () => _sendWhatsapp(
                                      context,
                                      member.phoneNumber,
                                      member.fullName,
                                      member.remainingAmount,
                                    ),
                                    tooltip: 'تذكير واتساب',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ] else
                                  const Text(
                                    'بدون هاتف',
                                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
