import '../models/user_model.dart';

/// تم إيقاف هذا الملف لأننا نستخدم LocalAuthDataSource حالياً.
/// تم تحديثه فقط لإزالة أخطاء الكومبيلر.
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String username, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<UserModel> login(String username, String password) async {
    throw UnimplementedError('نحن نستخدم نظام التسجيل المحلي حالياً');
  }
}
