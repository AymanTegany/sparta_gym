import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sparta_gym/core/database/database_helper.dart';
import 'package:sparta_gym/features/auth/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:sparta_gym/core/services/license_service.dart';

const String _kDeviceIdKey = 'app_device_id';
const String _kSessionUserKey = 'session_user_id';

class LocalAuthDataSource {
  final DatabaseHelper databaseHelper;
  final SharedPreferences prefs;

  LocalAuthDataSource({required this.databaseHelper, required this.prefs});

  String getDeviceId() {
    String? deviceId = prefs.getString(_kDeviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      prefs.setString(_kDeviceIdKey, deviceId);
    }
    return deviceId;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Register
  // ════════════════════════════════════════════════════════════════════════════

  Future<User> register({
    required String username,
    required String password,
    required String licenseKey,
  }) async {
    final currentDevice = getDeviceId();
    final licenseResult = LicenseService.validateLicense(
      licenseKey,
      currentDevice,
    );

    if (!licenseResult['isValid']) {
      throw Exception(licenseResult['error'] ?? 'الكرت غير صالح');
    }

    final int days = licenseResult['days'];
    final String subscriptionType = days > 1000 ? 'open' : 'limited';
    final DateTime? expiry = days > 1000
        ? null
        : DateTime.now().add(Duration(days: days));

    final db = await databaseHelper.database;
    final existing = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (existing.isNotEmpty) throw Exception('اسم المستخدم موجود مسبقاً');

    final id = await db.insert('users', {
      'username': username,
      'password': _hashPassword(password),
      'full_name': username,
      'device_id': currentDevice,
      'subscription_type': subscriptionType,
      'expiry_date': expiry?.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });

    return User(
      id: id,
      username: username,
      fullName: username,
      deviceId: currentDevice,
      subscriptionType: subscriptionType,
      expiryDate: expiry,
      createdAt: DateTime.now(),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Login
  // ════════════════════════════════════════════════════════════════════════════

  Future<User> login({
    required String username,
    required String password,
  }) async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, _hashPassword(password)],
    );

    if (results.isEmpty) {
      throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
    }

    final userData = results.first;
    if (userData['device_id'] != getDeviceId()) {
      throw Exception('هذا الحساب مسجل على جهاز آخر');
    }

    final user = User(
      id: userData['id'] as int,
      username: userData['username'] as String,
      fullName: userData['full_name'] as String,
      deviceId: userData['device_id'] as String,
      subscriptionType: userData['subscription_type'] as String,
      expiryDate: userData['expiry_date'] != null
          ? DateTime.tryParse(userData['expiry_date'] as String)
          : null,
    );

    // التحقق من انتهاء الاشتراك
    if (user.isExpired) {
      throw Exception('عذراً، انتهت مدة الاشتراك. يرجى التواصل مع المبرمج.');
    }

    await prefs.setInt(_kSessionUserKey, user.id!);
    return user;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Session Check
  // ════════════════════════════════════════════════════════════════════════════

  Future<User?> checkSession() async {
    final userId = prefs.getInt(_kSessionUserKey);
    if (userId == null) return null;

    final db = await databaseHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) return null;
    final userData = results.first;

    final user = User(
      id: userData['id'] as int,
      username: userData['username'] as String,
      fullName: userData['full_name'] as String,
      deviceId: userData['device_id'] as String,
      subscriptionType: userData['subscription_type'] as String,
      expiryDate: userData['expiry_date'] != null
          ? DateTime.tryParse(userData['expiry_date'] as String)
          : null,
    );

    // التحقق من انتهاء الاشتراك أثناء الجلسة
    if (user.isExpired) {
      await logout();
      return null;
    }

    return user;
  }

  Future<void> logout() async => await prefs.remove(_kSessionUserKey);

  // ════════════════════════════════════════════════════════════════════════════
  // Update Subscription (Admin Only)
  // ════════════════════════════════════════════════════════════════════════════

  Future<User> updateSubscription({
    required int userId,
    required String licenseKey,
  }) async {
    final currentDevice = getDeviceId();
    final licenseResult = LicenseService.validateLicense(
      licenseKey,
      currentDevice,
    );

    if (!licenseResult['isValid']) {
      throw Exception(licenseResult['error'] ?? 'الكرت غير صالح');
    }

    final int days = licenseResult['days'];
    final String subscriptionType = days > 1000 ? 'open' : 'limited';
    final DateTime? expiry = days > 1000
        ? null
        : DateTime.now().add(Duration(days: days));

    final db = await databaseHelper.database;
    await db.update(
      'users',
      {
        'subscription_type': subscriptionType,
        'expiry_date': expiry?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    // جلب البيانات المحدثة
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    final userData = results.first;

    return User(
      id: userData['id'] as int,
      username: userData['username'] as String,
      fullName: userData['full_name'] as String,
      deviceId: userData['device_id'] as String,
      subscriptionType: userData['subscription_type'] as String,
      expiryDate: userData['expiry_date'] != null
          ? DateTime.tryParse(userData['expiry_date'] as String)
          : null,
    );
  }
}
