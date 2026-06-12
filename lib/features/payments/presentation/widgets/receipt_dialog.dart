import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/payment_entity.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';
import '../../../settings/domain/entities/gym_settings_entity.dart';

class ReceiptDialog extends StatelessWidget {
  final Payment payment;

  const ReceiptDialog({super.key, required this.payment});

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('yyyy/MM/dd hh:mm a').format(date);
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'ar').format(amount);
  }

  /// طباعة الإيصال عبر طابعة الويندوز باستخدام مكتبة PDF و Printing
  Future<void> _printReceipt(BuildContext context, GymSettings settings) async {
    try {
      final doc = pw.Document();

      // تحميل خط عربي من Google Fonts لدعم اللغة العربية في ملف الـ PDF
      final arabicFont = await PdfGoogleFonts.cairoRegular();

      final formattedDate = _formatDate(payment.paymentDate);
      final formattedAmount = _formatCurrency(payment.amount);

      // البيانات المخزنة داخل الـ QR Code للتحقق
      final qrData = 'ReceiptID: ${payment.receiptId}\n'
          'Gym: ${settings.gymName}\n'
          'Member: ${payment.memberName ?? payment.memberId}\n'
          'Amount: $formattedAmount EGP\n'
          'Date: $formattedDate';

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80, // قياس طابعة الإيصالات الحرارية (80mm)
          build: (pw.Context context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // اسم الجيم
                    pw.Text(
                      settings.gymName,
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (settings.gymAddress.isNotEmpty)
                      pw.Text(
                        settings.gymAddress,
                        style: pw.TextStyle(font: arabicFont, fontSize: 10),
                      ),
                    if (settings.gymPhone.isNotEmpty)
                      pw.Text(
                        'هاتف: ${settings.gymPhone}',
                        style: pw.TextStyle(font: arabicFont, fontSize: 10),
                      ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      '------------------------------------------',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'إيصال استلام نقدية',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),

                    // تفاصيل الإيصال
                    _pdfRow(arabicFont, 'رقم الإيصال:', payment.receiptId),
                    _pdfRow(arabicFont, 'اسم العميل:', payment.memberName ?? '—'),
                    _pdfRow(arabicFont, 'رقم العضوية:', payment.memberId),
                    _pdfRow(arabicFont, 'طريقة الدفع:', payment.paymentMethod),
                    _pdfRow(arabicFont, 'التاريخ:', formattedDate),
                    _pdfRow(arabicFont, 'الموظف:', payment.employeeName),

                    pw.SizedBox(height: 10),
                    pw.Text(
                      '------------------------------------------',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 5),

                    // المبلغ الإجمالي
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'المبلغ المدفوع:',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '$formattedAmount ج.م',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    if (payment.notes != null) ...[
                      pw.SizedBox(height: 10),
                      pw.Align(
                        alignment: pw.Alignment.topRight,
                        child: pw.Text(
                          'ملاحظات: ${payment.notes!}',
                          style: pw.TextStyle(font: arabicFont, fontSize: 9),
                        ),
                      ),
                    ],

                    pw.SizedBox(height: 20),
                    // كود الـ QR
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: qrData,
                      width: 80,
                      height: 80,
                    ),
                    pw.SizedBox(height: 15),
                    pw.Text(
                      'شكراً لثقتكم بنا!',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // إرسال المستند مباشرة للطباعة
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'إيصال_${payment.receiptId}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الطباعة: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: ColorPalette.errorColor,
        ),
      );
    }
  }

  pw.Widget _pdfRow(pw.Font font, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          GymSettings settings = GymSettings.empty();
          if (settingsState is SettingsLoaded) {
            settings = settingsState.settings;
          }

          final formattedDate = _formatDate(payment.paymentDate);
          final formattedAmount = _formatCurrency(payment.amount);

          // بيانات الـ QR Code
          final qrData = 'ReceiptID: ${payment.receiptId}\n'
              'Gym: ${settings.gymName}\n'
              'Member: ${payment.memberName ?? payment.memberId}\n'
              'Amount: $formattedAmount EGP\n'
              'Date: $formattedDate';

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Container(
              width: 380,
              decoration: BoxDecoration(
                color: isDark ? ColorPalette.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long, color: ColorPalette.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'معاينة إيصال الدفع',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Receipt Thermal Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // اسم الجيم والترويسة
                            Text(
                              settings.gymName,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (settings.gymAddress.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(settings.gymAddress, style: theme.textTheme.bodySmall),
                            ],
                            if (settings.gymPhone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text('هاتف: ${settings.gymPhone}', style: theme.textTheme.bodySmall),
                            ],
                            const SizedBox(height: 12),
                            const Text('------------------------------------------', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            const Text(
                              'إيصال استلام نقدية',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 16),

                            // تفاصيل الفاتورة
                            _receiptRow('رقم الإيصال:', payment.receiptId),
                            _receiptRow('اسم العميل:', payment.memberName ?? '—'),
                            _receiptRow('رقم العضوية:', payment.memberId),
                            _receiptRow('طريقة الدفع:', payment.paymentMethod),
                            _receiptRow('التاريخ:', formattedDate),
                            _receiptRow('الموظف:', payment.employeeName),

                            const SizedBox(height: 12),
                            const Text('------------------------------------------', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),

                            // المبلغ الكلي
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'المبلغ المدفوع:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '$formattedAmount ج.م',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isDark ? ColorPalette.primaryColorDarkMode : ColorPalette.primaryColor,
                                  ),
                                ),
                              ],
                            ),

                            if (payment.notes != null) ...[
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'ملاحظات: ${payment.notes!}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),
                            // QR Code
                            QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 110.0,
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'شكراً لثقتكم بنا!',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer Actions
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('إغلاق'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _printReceipt(context, settings),
                            icon: const Icon(Icons.print, color: Colors.white),
                            label: const Text('طباعة الإيصال'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorPalette.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
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

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
