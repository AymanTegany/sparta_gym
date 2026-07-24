import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class WhatsappApiService {
  final Dio _dio = Dio();

  /// Send a WhatsApp message using the WhatsApp Cloud API.
  /// Returns [null] if successful, or an error message string if it fails.
  Future<String?> sendMessage({
    required String phoneNumber,
    required String message,
    required String accessToken,
    required String phoneNumberId,
  }) async {
    if (accessToken.isEmpty || phoneNumberId.isEmpty) {
      debugPrint('WhatsApp API configuration is missing.');
      return 'بيانات ربط الواتساب غير مكتملة.';
    }

    // Clean phone number (remove +, spaces, etc.)
    String cleanedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Ensure country code is present.
    if (cleanedPhone.startsWith('00')) {
      cleanedPhone = cleanedPhone.substring(2); // remove 00
    } else if (cleanedPhone.startsWith('0')) {
      cleanedPhone = '2$cleanedPhone'; // assume Egypt 20 if starts with 0
    } else if (cleanedPhone.length == 10) {
      // Basic handling for 10 digit numbers without country code
      cleanedPhone = '20$cleanedPhone';
    }

    final url = 'https://graph.facebook.com/v17.0/$phoneNumberId/messages';

    try {
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'messaging_product': 'whatsapp',
          'recipient_type': 'individual',
          'to': cleanedPhone,
          'type': 'text',
          'text': {
            'preview_url': false,
            'body': message,
          },
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('WhatsApp message sent successfully to $cleanedPhone');
        return null; // Success
      } else {
        debugPrint('Failed to send WhatsApp message: ${response.data}');
        return 'خطأ غير معروف: ${response.statusCode}';
      }
    } catch (e) {
      if (e is DioException) {
        final errorData = e.response?.data;
        debugPrint('DioException in WhatsApp API: $errorData');
        if (errorData is Map && errorData.containsKey('error')) {
          final errorMsg = errorData['error']['message'] ?? 'خطأ في API';
          // Check for 24h rule error
          if (errorMsg.toString().contains('more than 24 hours')) {
            return 'لا يمكنك إرسال رسالة نصية حرة (Text) لعميل لم يراسلك منذ أكثر من 24 ساعة (قوانين WhatsApp API). يجب استخدام Template Message أو أن يقوم العميل بمراسلتك أولاً.';
          }
          return 'خطأ: $errorMsg';
        }
        return 'تعذر الاتصال بـ WhatsApp API (${e.response?.statusCode ?? e.message})';
      } else {
        debugPrint('Exception in WhatsApp API: $e');
        return 'حدث خطأ غير متوقع: $e';
      }
    }
  }
}
