import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/member_entity.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';
import '../../../settings/domain/entities/gym_settings_entity.dart';

Future<void> printMemberA4Invoice(BuildContext context, Member member) async {
  try {
    final settingsState = context.read<SettingsCubit>().state;
    GymSettings settings = GymSettings.empty();
    if (settingsState is SettingsLoaded) {
      settings = settingsState.settings;
    }

    final doc = pw.Document();
    final primaryColor = PdfColor.fromHex('#ff6b00');
    final secondaryColor = PdfColor.fromHex('#fff4ec');
    
    // تحميل الخطوط من الملفات المحلية
    final regularFontData = await rootBundle.load('lib/core/fonts/Cairo-Regular.ttf');
    final boldFontData = await rootBundle.load('lib/core/fonts/Cairo-Bold.ttf');
    
    final arabicFont = pw.Font.ttf(regularFontData);
    final arabicFontBold = pw.Font.ttf(boldFontData);

    pw.ImageProvider? logoImage;
    if (settings.logoPath.isNotEmpty) {
      try {
        final file = File(settings.logoPath);
        if (file.existsSync()) {
          final bytes = await file.readAsBytes();
          logoImage = pw.MemoryImage(bytes);
        }
      } catch (e) {
        // Handle error loading logo silently
      }
    }

    final startDateStr = DateFormat('yyyy/MM/dd').format(DateTime.parse(member.startDate));
    final endDateStr = DateFormat('yyyy/MM/dd').format(DateTime.parse(member.endDate));

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header: Logo and Gym Info
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            settings.gymName,
                            style: pw.TextStyle(
                              font: arabicFontBold,
                              fontSize: 28,
                              color: primaryColor,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          if (settings.gymPhone.isNotEmpty)
                            pw.Text('هاتف: ${settings.gymPhone}', style: pw.TextStyle(font: arabicFont, fontSize: 14, color: PdfColors.grey700)),
                          if (settings.gymAddress.isNotEmpty)
                            pw.Text('العنوان: ${settings.gymAddress}', style: pw.TextStyle(font: arabicFont, fontSize: 14, color: PdfColors.grey700)),
                          if (settings.commercialRegister.isNotEmpty)
                            pw.Text('سجل تجاري: ${settings.commercialRegister}', style: pw.TextStyle(font: arabicFont, fontSize: 14, color: PdfColors.grey700)),
                        ],
                      ),
                      if (logoImage != null)
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(color: primaryColor, width: 2),
                          ),
                          child: pw.Image(logoImage, width: 80, height: 80),
                        )
                      else
                        pw.SizedBox(width: 100, height: 100),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(color: primaryColor, thickness: 2),
                  pw.SizedBox(height: 20),

                  // Title
                  pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: secondaryColor,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: primaryColor),
                      ),
                      child: pw.Text(
                        'إيصال اشتراك',
                        style: pw.TextStyle(
                          font: arabicFontBold,
                          fontSize: 22,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 30),

                  // Member & Subscription Info
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(16),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey50,
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('بيانات العضو', style: pw.TextStyle(font: arabicFontBold, fontSize: 16, color: primaryColor)),
                              pw.Divider(color: PdfColors.grey300),
                              pw.SizedBox(height: 8),
                              _buildInfoRow(arabicFont, arabicFontBold, 'اسم العميل:', member.fullName, primaryColor),
                              _buildInfoRow(arabicFont, arabicFontBold, 'رقم الهاتف:', member.phoneNumber ?? '—', primaryColor),
                              _buildInfoRow(arabicFont, arabicFontBold, 'تاريخ البداية:', startDateStr, primaryColor),
                              _buildInfoRow(arabicFont, arabicFontBold, 'تاريخ الانتهاء:', endDateStr, primaryColor),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(16),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey50,
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('بيانات الاشتراك', style: pw.TextStyle(font: arabicFontBold, fontSize: 16, color: primaryColor)),
                              pw.Divider(color: PdfColors.grey300),
                              pw.SizedBox(height: 8),
                              _buildInfoRow(arabicFont, arabicFontBold, 'نوع الاشتراك:', member.membershipType, primaryColor),
                              _buildInfoRow(arabicFont, arabicFontBold, 'سعر الاشتراك:', '${member.membershipPrice.toStringAsFixed(0)} ج.م', primaryColor),
                              _buildInfoRow(arabicFont, arabicFontBold, 'الخصم:', '${member.discount.toStringAsFixed(0)} ج.م', primaryColor),
                              _buildInfoRow(arabicFont, arabicFontBold, 'المبلغ المدفوع:', '${member.paidAmount.toStringAsFixed(0)} ج.م', primaryColor),
                              _buildInfoRow(arabicFont, arabicFontBold, 'المبلغ المتبقي:', '${member.remainingAmount.toStringAsFixed(0)} ج.م', primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 40),

                  // Barcode
                  pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: PdfColors.grey300, style: pw.BorderStyle.dashed),
                      ),
                      child: pw.Column(
                        children: [
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.code128(),
                            data: member.memberId,
                            width: 200,
                            height: 60,
                            color: PdfColors.black,
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            member.memberId,
                            style: pw.TextStyle(font: arabicFontBold, fontSize: 16, color: primaryColor, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Spacer(),

                  // Footer
                  pw.Divider(color: primaryColor, thickness: 2),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                      'شكراً لاشتراككم معنا!',
                      style: pw.TextStyle(font: arabicFontBold, fontSize: 16, color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // إضافة صفحة الشروط والأحكام
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(32),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: primaryColor, width: 8),
                  bottom: pw.BorderSide(color: primaryColor, width: 8),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'الشروط والأحكام',
                        style: pw.TextStyle(
                          font: arabicFontBold,
                          fontSize: 28,
                          color: primaryColor,
                        ),
                      ),
                      if (logoImage != null)
                        pw.Image(logoImage, width: 60, height: 60)
                      else
                        pw.SizedBox(width: 60, height: 60),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: primaryColor, thickness: 1),
                  pw.SizedBox(height: 30),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(24),
                    decoration: pw.BoxDecoration(
                      color: secondaryColor,
                      borderRadius: pw.BorderRadius.circular(16),
                      border: pw.Border.all(color: primaryColor.shade(.2)),
                    ),
                    child: pw.Text(
                      (member.notes != null && member.notes!.trim().isNotEmpty)
                          ? member.notes!
                          : 'لا توجد شروط أو أحكام إضافية مسجلة.',
                      style: pw.TextStyle(font: arabicFont, fontSize: 14, lineSpacing: 1.5, color: PdfColors.grey900),
                    ),
                  ),
                  pw.Spacer(),
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('توقيع العضو', style: pw.TextStyle(font: arabicFontBold, fontSize: 16, color: primaryColor)),
                          pw.SizedBox(height: 10),
                          pw.Text('................................', style: pw.TextStyle(font: arabicFont, color: PdfColors.grey600)),
                        ]
                      ),
                      pw.Column(
                        children: [
                          pw.Text('توقيع الموظف', style: pw.TextStyle(font: arabicFontBold, fontSize: 16, color: primaryColor)),
                          pw.SizedBox(height: 10),
                          pw.Text('................................', style: pw.TextStyle(font: arabicFont, color: PdfColors.grey600)),
                        ]
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 800,
            height: 600,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('معاينة الفاتورة', style: TextStyle(fontFamily: 'Cairo')),
                centerTitle: true,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              body: PdfPreview(
                build: (format) async => doc.save(),
                pdfFileName: 'فاتورة_${member.fullName}.pdf',
                canChangeOrientation: false,
                canChangePageFormat: false,
                allowSharing: true,
                allowPrinting: true,
                initialPageFormat: PdfPageFormat.a4,
              ),
            ),
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الطباعة: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: ColorPalette.errorColor,
        ),
      );
    }
  }
}

pw.Widget _buildInfoRow(pw.Font font, pw.Font boldFont, String label, String value, PdfColor primaryColor) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: font, fontSize: 12, color: primaryColor),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.grey900),
          ),
        ),
      ],
    ),
  );
}
