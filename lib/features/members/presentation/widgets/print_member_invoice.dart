import 'dart:io';
import 'package:flutter/material.dart';
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
    final arabicFont = await PdfGoogleFonts.cairoRegular();

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
                              font: arabicFont,
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (settings.gymPhone.isNotEmpty)
                            pw.Text('هاتف: ${settings.gymPhone}', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                          if (settings.gymAddress.isNotEmpty)
                            pw.Text('العنوان: ${settings.gymAddress}', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                          if (settings.commercialRegister.isNotEmpty)
                            pw.Text('سجل تجاري: ${settings.commercialRegister}', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                        ],
                      ),
                      if (logoImage != null)
                        pw.Image(logoImage, width: 100, height: 100)
                      else
                        pw.SizedBox(width: 100, height: 100),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  pw.SizedBox(height: 20),

                  // Title
                  pw.Center(
                    child: pw.Text(
                      'إيصال اشتراك',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 30),

                  // Member & Subscription Info
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(arabicFont, 'اسم العميل:', member.fullName),
                          _buildInfoRow(arabicFont, 'رقم الهاتف:', member.phoneNumber ?? '—'),
                          _buildInfoRow(arabicFont, 'تاريخ البداية:', startDateStr),
                          _buildInfoRow(arabicFont, 'تاريخ الانتهاء:', endDateStr),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(arabicFont, 'نوع الاشتراك:', member.membershipType),
                          _buildInfoRow(arabicFont, 'سعر الاشتراك:', '${member.membershipPrice.toStringAsFixed(0)} ج.م'),
                          _buildInfoRow(arabicFont, 'الخصم:', '${member.discount.toStringAsFixed(0)} ج.م'),
                          _buildInfoRow(arabicFont, 'المبلغ المدفوع:', '${member.paidAmount.toStringAsFixed(0)} ج.م'),
                          _buildInfoRow(arabicFont, 'المبلغ المتبقي:', '${member.remainingAmount.toStringAsFixed(0)} ج.م'),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 40),

                  // Barcode
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.code128(),
                          data: member.memberId,
                          width: 200,
                          height: 80,
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          member.memberId,
                          style: pw.TextStyle(font: arabicFont, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  pw.Spacer(),

                  // Footer
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                      'شكراً لاشتراككم معنا!',
                      style: pw.TextStyle(font: arabicFont, fontSize: 14),
                    ),
                  ),
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

pw.Widget _buildInfoRow(pw.Font font, String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 8),
    child: pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          value,
          style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}
