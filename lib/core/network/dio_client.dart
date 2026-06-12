import 'package:dio/dio.dart';

/// إعداد عميل HTTP (Dio) مع إضافة الـ Interceptors والـ Headers الأساسية.
class DioClient {
  final Dio dio;

  DioClient(this.dio) {
    dio.options
      ..baseUrl = 'https://api.example.com/' // TODO: استبدل هذا برابط الـ API الخاص بك
      ..connectTimeout = const Duration(seconds: 30)
      ..receiveTimeout = const Duration(seconds: 30)
      ..headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

    // إضافة Interceptors لطباعة الـ Logs أثناء التطوير أو لحقن الـ Token
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }
}
