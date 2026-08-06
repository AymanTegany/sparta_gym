import 'dart:convert';
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
        return _parseError(e);
      } else {
        debugPrint('Exception in WhatsApp API: $e');
        return 'حدث خطأ غير متوقع: $e';
      }
    }
  }

  /// Send a generic template message
  Future<String?> sendTemplateMessage({
    required String phoneNumber,
    required String templateName,
    required List<String> parameters,
    required String accessToken,
    required String phoneNumberId,
    String languageCode = 'ar', // Default to Arabic, but can be 'ar_EG' etc.
  }) async {
    if (accessToken.isEmpty || phoneNumberId.isEmpty) {
      debugPrint('WhatsApp API configuration is missing.');
      return 'بيانات ربط الواتساب غير مكتملة.';
    }

    // Clean phone number (remove +, spaces, etc.)
    String cleanedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanedPhone.startsWith('00')) {
      cleanedPhone = cleanedPhone.substring(2);
    } else if (cleanedPhone.startsWith('0')) {
      cleanedPhone = '2$cleanedPhone'; 
    } else if (cleanedPhone.length == 10) {
      cleanedPhone = '20$cleanedPhone';
    }

    final url = 'https://graph.facebook.com/v17.0/$phoneNumberId/messages';

    // Map parameters to the format required by WhatsApp API
    final List<Map<String, dynamic>> apiParameters = parameters.map((param) {
      return {
        'type': 'text',
        'text': param,
      };
    }).toList();

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
          'type': 'template',
          'template': {
            'name': templateName,
            'language': {
              'code': languageCode
            },
            if (apiParameters.isNotEmpty)
              'components': [
                {
                  'type': 'body',
                  'parameters': apiParameters
                }
              ]
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('WhatsApp template message sent successfully to $cleanedPhone');
        return null;
      } else {
        debugPrint('Failed to send WhatsApp template: ${response.data}');
        return 'خطأ غير معروف: ${response.statusCode}';
      }
    } catch (e) {
      if (e is DioException) {
        return _parseError(e, templateName: templateName);
      } else {
        debugPrint('Exception in WhatsApp API Template: $e');
        return 'حدث خطأ غير متوقع: $e';
      }
    }
  }

  /// Parse the DioException to retrieve specific WhatsApp/Meta API error details
  String _parseError(DioException e, {String? templateName}) {
    try {
      final responseData = e.response?.data;
      if (responseData == null) {
        return 'تعذر الاتصال بـ WhatsApp API (${e.response?.statusCode ?? e.message})';
      }

      Map<dynamic, dynamic>? errorMap;
      if (responseData is Map) {
        errorMap = responseData;
      } else if (responseData is String) {
        try {
          final decoded = jsonDecode(responseData);
          if (decoded is Map) {
            errorMap = decoded;
          }
        } catch (_) {}
      }

      if (errorMap != null && errorMap.containsKey('error')) {
        final errorDetails = errorMap['error'];
        if (errorDetails is Map) {
          final errorMsg = errorDetails['message'] ?? 'خطأ في API';
          
          if (errorMsg.toString().contains('more than 24 hours')) {
            return 'لا يمكنك إرسال رسالة نصية حرة (Text) لعميل لم يراسلك منذ أكثر من 24 ساعة (قوانين WhatsApp API). يجب استخدام Template Message أو أن يقوم العميل بمراسلتك أولاً.';
          }
          
          if (errorMsg.toString().contains('Template name does not exist')) {
            return 'القالب المطلوب ${templateName != null ? "($templateName) " : ""}غير موجود أو لغته تختلف عن العربية (ar)، أو لم تتم الموافقة عليه بعد.';
          }

          return 'خطأ WhatsApp API: $errorMsg';
        }
      }
      
      return 'تعذر الاتصال بـ WhatsApp API (${e.response?.statusCode ?? e.message}): ${responseData.toString()}';
    } catch (_) {
      return 'تعذر الاتصال بـ WhatsApp API (${e.response?.statusCode ?? e.message})';
    }
  }
}
