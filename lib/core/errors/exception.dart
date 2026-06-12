/// مجلد: core/errors
/// 
/// ملف: exception.dart
/// يحتوي على تعريفات الاستثناءات المخصصة (Custom Exceptions) التي يتم رميها من طبقة الـ Data.

/// استثناء ناتج عن خطأ في الخادم
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'حدث خطأ في الخادم']);

  @override
  String toString() => 'ServerException: $message';
}

/// استثناء ناتج عن خطأ في قاعدة البيانات المحلية
class DatabaseException implements Exception {
  final String message;
  const DatabaseException([this.message = 'حدث خطأ في قاعدة البيانات']);

  @override
  String toString() => 'DatabaseException: $message';
}

/// استثناء ناتج عن خطأ في التخزين المؤقت
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'حدث خطأ في التخزين المؤقت']);

  @override
  String toString() => 'CacheException: $message';
}
