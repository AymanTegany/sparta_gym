import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../../services/audio_service.dart';
import '../../../features/attendance/presentation/cubit/attendance_cubit.dart';
import '../../../features/attendance/presentation/cubit/attendance_state.dart';

class GlobalScannerListener extends StatefulWidget {
  final Widget child;
  
  // متغير للتحكم في تفعيل أو إيقاف القارئ الشامل (مثل عند فتح دايلوج إضافة عضو)
  static bool isScannerActive = true;

  const GlobalScannerListener({super.key, required this.child});

  @override
  State<GlobalScannerListener> createState() => _GlobalScannerListenerState();
}

class _GlobalScannerListenerState extends State<GlobalScannerListener> {
  String _barcodeBuffer = '';
  DateTime? _lastKeyPressTime;
  
  // لتعطيل المسح المتكرر لنفس العضو في فترة قصيرة
  String? _lastScannedBarcode;
  DateTime? _lastScannedTime;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!GlobalScannerListener.isScannerActive) return false;

    if (event is KeyDownEvent) {
      final now = DateTime.now();

      // إذا مر وقت طويل نسبياً منذ آخر ضغطة، فهذا يعني أن الإدخال يدوي وليس من قارئ الباركود
      if (_lastKeyPressTime != null && now.difference(_lastKeyPressTime!).inMilliseconds > 100) {
        _barcodeBuffer = '';
      }
      _lastKeyPressTime = now;

      // تحقق من الضغط على زر الإدخال (Enter)
      if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        if (_barcodeBuffer.isNotEmpty && _barcodeBuffer.length > 2) {
          final code = _barcodeBuffer;
          _barcodeBuffer = '';
          
          _processBarcode(code);
          // لا نعيد true هنا للسماح لبقية الحقول بالعمل، أو نعيد true إذا أردنا منع الـ Enter من الوصول للحقول.
          // في العادة إذا تم التقاط باركود، فمن الأفضل عدم إرسال الـ Enter للحقول النشطة.
          return true;
        }
      } else if (event.character != null && event.character!.isNotEmpty) {
        // تجاهل الأحرف غير القابلة للطباعة
        if (!event.logicalKey.keyLabel.contains('Control') && !event.logicalKey.keyLabel.contains('Alt')) {
           _barcodeBuffer += event.character!;
        }
      }
    }
    return false;
  }

  void _processBarcode(String barcode) {
    final scannedValue = barcode.trim();
    if (scannedValue.isEmpty) return;

    final now = DateTime.now();
    if (_lastScannedBarcode == scannedValue &&
        _lastScannedTime != null &&
        now.difference(_lastScannedTime!).inSeconds < 5) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم مسح هذا الكود للتو، يرجى الانتظار قليلاً.', style: TextStyle(fontFamily: 'Cairo')),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _lastScannedBarcode = scannedValue;
    _lastScannedTime = now;

    // استدعاء الكيوبت لتسجيل الحضور/الانصراف (تلقائي)
    context.read<AttendanceCubit>().processScan(scannedValue, 'تلقائي');
  }

  /// تحديد نوع الخطأ وعنوانه المناسب
  static ({String title, DialogType dialogType}) _classifyError(String message) {
    if (message.contains('منتهي') || message.contains('منتهية') || message.contains('الصلاحية')) {
      return (title: '⛔ اشتراك منتهي', dialogType: DialogType.warning);
    }
    if (message.contains('غير مسجل') || message.contains('غير موجود')) {
      return (title: '❓ عضو غير مسجل', dialogType: DialogType.info);
    }
    if (message.contains('مسجل حضور بالفعل')) {
      return (title: '🔄 تسجيل دخول مكرر', dialogType: DialogType.info);
    }
    if (message.contains('لا يوجد تسجيل دخول')) {
      return (title: '⚠️ لم يسجل دخول', dialogType: DialogType.info);
    }
    if (message.contains('الزيارات المسموح')) {
      return (title: '🚫 انتهت الزيارات', dialogType: DialogType.warning);
    }
    if (message.contains('تاريخ انتهاء')) {
      return (title: '📅 خطأ في البيانات', dialogType: DialogType.error);
    }
    return (title: '❌ خطأ', dialogType: DialogType.error);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceCubit, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceActionSuccess) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.scale,
            title: state.type == 'حضور' ? 'تم تسجيل الدخول ✅' : 'تم تسجيل الخروج ✅',
            desc: state.message,
            descTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            titleTextStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            autoHide: const Duration(seconds: 3),
          ).show();
        } else if (state is AttendanceError) {
          if (state.message.contains('منتهي') || state.message.contains('منتهية') || state.message.contains('الزيارات')) {
            AudioService.playAlertSound();
          }
          final errorInfo = _classifyError(state.message);
          AwesomeDialog(
            context: context,
            dialogType: errorInfo.dialogType,
            animType: AnimType.scale,
            title: errorInfo.title,
            desc: state.message,
            descTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.red),
            titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            btnOkOnPress: () {},
            btnOkColor: Colors.red,
            btnOkText: 'حسناً',
            autoHide: const Duration(seconds: 10),
            dismissOnTouchOutside: true,
          ).show();
        }
      },
      child: widget.child,
    );
  }
}
