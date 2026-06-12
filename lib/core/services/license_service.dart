import 'dart:convert';
import 'package:crypto/crypto.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// خدمة ترخيص التطبيق محلياً (Offline License Service)
/// ──────────────────────────────────────────────────────────────────────────────
/// تقوم بتوليد والتحقق من كروت الترخيص (License Keys) دون الحاجة للاتصال بالإنترنت.
/// تعتمد على ربط الترخيص بـ deviceId الخاص بالجهاز وتحديد فترة صلاحية بالأيام.
class LicenseService {
  static const String _kSecretSalt = 'sparta_gym_secret_salt_2026';

  /// توليد كارت ترخيص جديد لجهاز معين وعدد أيام محدد
  static String generateLicense(String deviceId, int days) {
    final rawInput = '$deviceId:$days:$_kSecretSalt';
    // توليد هاش MD5 لضمان عدم التلاعب
    final hash = md5.convert(utf8.encode(rawInput)).toString().substring(0, 10).toUpperCase();
    
    // بناء الكارت بصيغة: DAYS:DEVICEID:HASH
    final rawKey = '${days}D:$deviceId:$hash';
    
    // تشفيره بـ Base64 لجعله رمزاً واحداً يسهل نسخه
    return base64Url.encode(utf8.encode(rawKey));
  }

  /// التحقق من صلاحية كارت الترخيص للجهاز الحالي
  /// يرجع خريطة تحتوي على:
  /// - `isValid`: هل الكارت صالح للجهاز؟
  /// - `days`: عدد الأيام المرخص بها
  /// - `error`: رسالة الخطأ في حال عدم الصلاحية
  static Map<String, dynamic> validateLicense(String licenseKey, String deviceId) {
    try {
      if (licenseKey.trim().isEmpty) {
        return {'isValid': false, 'error': 'الرجاء إدخال كارت الترخيص'};
      }

      // فك تشفير الكارت
      final decoded = utf8.decode(base64Url.decode(licenseKey.trim()));
      final parts = decoded.split(':');
      
      if (parts.length < 3) {
        return {'isValid': false, 'error': 'تنسيق كارت الترخيص غير صالح'};
      }

      final daysPart = parts[0];     // e.g. "30D" or "9999D"
      final deviceIdPart = parts[1]; // e.g. deviceId
      final hashPart = parts[2];     // e.g. HASH

      // التحقق من توافق الجهاز
      if (deviceIdPart != deviceId) {
        return {'isValid': false, 'error': 'هذا الترخيص مخصص لجهاز آخر'};
      }

      // استخراج عدد الأيام
      final daysStr = daysPart.replaceAll('D', '');
      final days = int.tryParse(daysStr);
      if (days == null) {
        return {'isValid': false, 'error': 'عدد أيام الترخيص غير صحيح'};
      }

      // إعادة حساب الهاش للمقارنة والتحقق من عدم التعديل
      final rawInput = '$deviceId:$days:$_kSecretSalt';
      final expectedHash = md5.convert(utf8.encode(rawInput)).toString().substring(0, 10).toUpperCase();

      if (hashPart != expectedHash) {
        return {'isValid': false, 'error': 'رمز الترخيص غير صالح أو تم التلاعب به'};
      }

      return {
        'isValid': true,
        'days': days,
      };
    } catch (e) {
      return {'isValid': false, 'error': 'فشل فحص الترخيص: تنسيق غير مدعوم'};
    }
  }
}
