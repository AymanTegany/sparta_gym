import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatsapp_bot_flutter/whatsapp_bot_flutter.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// خدمة الواتساب المركزية (WhatsappBotService)
/// تعمل في الخلفية طوال فترة تشغيل التطبيق (Singleton)
/// تدعم:
/// 1. البقاء متصلاً حتى عند التنقل بين الشاشات المختلفة
/// 2. الاتصال التلقائي (Auto-Connect) في الخلفية عند فتح التطبيق
/// 3. إيقاف الاتصال المؤقت (Pause / Disconnect) مع حفظ الجلسة
/// 4. تغيير الحساب (Switch Account / Logout) ومسح الجلسة لإنتاج كود QR جديد
/// 5. إرسال الرسائل الفردية والجماعية في الخلفية دون انقطاع
/// ──────────────────────────────────────────────────────────────────────────────

class WhatsappBotService extends ChangeNotifier {
  final SharedPreferences _prefs;

  WhatsappBotService({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences;

  // ─── كائن الاتصال والحالة ───
  WhatsappClient? _client;
  Uint8List? _qrCodeBytes;
  String _connectionStatus = 'غير متصل';
  bool _isConnecting = false;
  bool _isConnected = false;

  // ─── الإعدادات المحفوظة ───
  bool _headless = true;
  bool _autoConnect = true;
  int _bulkDelay = 5;
  String _chromePath = '';

  // ─── سجل النشاط ───
  final List<WhatsappLogEntry> _logs = [];

  // ─── حالة الإرسال الجماعي ───
  bool _isSendingBulk = false;
  int _bulkTotal = 0;
  int _bulkSent = 0;
  int _bulkFailed = 0;

  // ─── Getters ───
  WhatsappClient? get client => _client;
  Uint8List? get qrCodeBytes => _qrCodeBytes;
  String get connectionStatus => _connectionStatus;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get headless => _headless;
  bool get autoConnect => _autoConnect;
  int get bulkDelay => _bulkDelay;
  String get chromePath => _chromePath;
  List<WhatsappLogEntry> get logs => List.unmodifiable(_logs);

  bool get isSendingBulk => _isSendingBulk;
  int get bulkTotal => _bulkTotal;
  int get bulkSent => _bulkSent;
  int get bulkFailed => _bulkFailed;

  // ═══════════════════════════════════════════════════════════════════════════
  // التهيئة الأولية (تُستدعى عند فتح التطبيق)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> init() async {
    _headless = _prefs.getBool('wa_headless') ?? true;
    _autoConnect = _prefs.getBool('wa_auto_connect') ?? true;
    _bulkDelay = _prefs.getInt('wa_bulk_delay') ?? 5;
    _chromePath = _prefs.getString('wa_chrome_path') ?? '';

    _log('تهيئة خدمة الواتساب المركزية في الخلفية...');

    // إذا كان الاتصال التلقائي مفعلاً، نبدأ الاتصال في الخلفية
    if (_autoConnect) {
      _log('تفعيل الاتصال التلقائي في الخلفية...');
      // تشغيل غير متزامن بدون تعطيل بدء التطبيق
      Future.delayed(const Duration(milliseconds: 500), () {
        connect();
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إدارة الإعدادات
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> setHeadless(bool value) async {
    _headless = value;
    await _prefs.setBool('wa_headless', value);
    notifyListeners();
  }

  Future<void> setAutoConnect(bool value) async {
    _autoConnect = value;
    await _prefs.setBool('wa_auto_connect', value);
    notifyListeners();
  }

  Future<void> setBulkDelay(int seconds) async {
    _bulkDelay = seconds;
    await _prefs.setInt('wa_bulk_delay', seconds);
    notifyListeners();
  }

  Future<void> setChromePath(String path) async {
    _chromePath = path.trim();
    await _prefs.setString('wa_chrome_path', _chromePath);
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void _log(String text, {WhatsappLogType type = WhatsappLogType.info}) {
    _logs.insert(
      0,
      WhatsappLogEntry(message: text, time: DateTime.now(), type: type),
    );
    // نحدد الحد الأقصى للسجلات لتفادي استهلاك الذاكرة
    if (_logs.length > 300) {
      _logs.removeLast();
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تحديد مسار المتصفح ومجلد الجلسة
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Directory> getSessionDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final sessionDir = Directory('${appDir.path}/whatsapp_bot_session');
    if (!sessionDir.existsSync()) {
      sessionDir.createSync(recursive: true);
    }
    return sessionDir;
  }

  String? _findBrowserExecutable() {
    if (_chromePath.isNotEmpty && File(_chromePath).existsSync()) {
      return _chromePath;
    }

    final possiblePaths = [
      r"C:\Program Files\Google\Chrome\Application\chrome.exe",
      r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
      r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
      r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    ];

    for (final path in possiblePaths) {
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // وظائف الاتصال والتحكم
  // ═══════════════════════════════════════════════════════════════════════════

  /// بدء الاتصال بـ WhatsApp
  Future<void> connect() async {
    if (_isConnecting || _isConnected) return;

    _isConnecting = true;
    _connectionStatus = 'جاري تهيئة المتصفح...';
    _qrCodeBytes = null;
    notifyListeners();

    _log('بدء تشغيل محرك واتساب...');

    try {
      final sessionDir = await getSessionDirectory();
      final execPath = _findBrowserExecutable();

      if (execPath == null) {
        _log(
          'لم يتم العثور على Chrome أو Edge تلقائياً. يرجى إدخال المسار في الإعدادات.',
          type: WhatsappLogType.error,
        );
        _connectionStatus = 'المتصفح غير متوفر';
        _isConnecting = false;
        notifyListeners();
        return;
      }

      _log('استخدام المتصفح: $execPath (وضع مخفي: $_headless)');

      _client = await WhatsappBotFlutter.connect(
        sessionDirectory: sessionDir.path,
        puppeteerClient: () async {
          return await puppeteer.launch(
            headless: _headless,
            executablePath: execPath,
            userDataDir: sessionDir.path,
            args: [
              '--no-sandbox',
              '--disable-setuid-sandbox',
              '--disable-dev-shm-usage',
              '--disable-gpu',
            ],
          );
        },
        onConnectionEvent: (ConnectionEvent event) {
          _log('حدث اتصال: $event');
          switch (event) {
            case ConnectionEvent.authenticated:
              _connectionStatus = 'تمت المصادقة بنجاح ✓';
              _isConnected = true;
              _qrCodeBytes = null;
              break;
            case ConnectionEvent.connected:
              _connectionStatus = 'متصل ✓';
              _isConnected = true;
              _qrCodeBytes = null;
              break;
            case ConnectionEvent.disconnected:
              _connectionStatus = 'تم قطع الاتصال';
              _isConnected = false;
              break;
            case ConnectionEvent.logout:
              _connectionStatus = 'تم تسجيل الخروج من الهاتف';
              _isConnected = false;
              _client = null;
              break;
            default:
              _connectionStatus = event.toString();
          }
          notifyListeners();
        },
        onQrCode: (String qr, Uint8List? imageBytes) {
          _qrCodeBytes = imageBytes;
          _connectionStatus = 'في انتظار مسح رمز QR...';
          _log('تم استلام رمز QR — امسحه من تطبيق واتساب على هاتفك');
          notifyListeners();
        },
      );

      if (_client != null) {
        _isConnected = true;
        _connectionStatus = 'متصل ✓';
        _qrCodeBytes = null;
        _isConnecting = false;
        _log('تم الاتصال بنجاح وتثبيت الجلسة في الخلفية!', type: WhatsappLogType.success);
        notifyListeners();

        // الاستماع للرسائل الواردة
        _client!.on(WhatsappEvent.chatNewMessage, (data) {
          try {
            final List<Message> messages = Message.parse(data);
            for (var msg in messages) {
              if (msg.id?.fromMe == false) {
                _log(
                  'رسالة واردة من ${msg.from}: ${msg.body}',
                  type: WhatsappLogType.incoming,
                );
              }
            }
          } catch (_) {}
        });
      }
    } catch (e) {
      _log('خطأ في الاتصال: $e', type: WhatsappLogType.error);
      _connectionStatus = 'فشل الاتصال';
      _isConnecting = false;
      _isConnected = false;
      notifyListeners();
    }
  }

  /// إيقاف الاتصال المؤقت (دون مسح الحساب أو الجلسة)
  Future<void> disconnect({bool tryLogout = false}) async {
    try {
      if (_client != null) {
        await _client!.disconnect(tryLogout: tryLogout);
      }
    } catch (e) {
      _log('خطأ أثناء إغلاق المتصفح: $e', type: WhatsappLogType.error);
    } finally {
      _client = null;
      _isConnected = false;
      _isConnecting = false;
      _qrCodeBytes = null;
      _connectionStatus = tryLogout ? 'تم تسجيل الخروج' : 'غير متصل (متوقف مؤقتاً)';
      _log(
        tryLogout
            ? 'تم تسجيل الخروج من الحساب بنجاح'
            : 'تم إيقاف خدمة الواتساب مؤقتاً (الجلسة محفوظة)',
        type: WhatsappLogType.info,
      );
      notifyListeners();
    }
  }

  /// تغيير الحساب: تسجيل خروج، مسح مجلد الجلسة، والبدء فوراً لإظهار QR جديد
  Future<void> switchAccount() async {
    _log('بدء إجراء تغيير الحساب...', type: WhatsappLogType.info);
    _connectionStatus = 'جاري إنهاء الجلسة ومسح الحساب...';
    _isConnecting = true;
    notifyListeners();

    try {
      // 1. قطع الاتصال مع محاولة تسجيل الخروج
      if (_client != null) {
        try {
          await _client!.disconnect(tryLogout: true);
        } catch (_) {}
        _client = null;
      }

      _isConnected = false;
      _qrCodeBytes = null;

      // 2. إعطاء مهلة لإغلاق ملفات Chrome ثم مسح مجلد الجلسة
      await Future.delayed(const Duration(milliseconds: 800));
      final sessionDir = await getSessionDirectory();

      if (sessionDir.existsSync()) {
        try {
          sessionDir.deleteSync(recursive: true);
          _log('تم حذف ملفات الجلسة السابقة بنجاح ✓');
        } catch (e) {
          _log('ملاحظة أثناء تنظيف مجلد الجلسة: $e', type: WhatsappLogType.info);
        }
      }

      // إعادة إنشاء مجلد فارغ
      sessionDir.createSync(recursive: true);
      _isConnecting = false;

      // 3. إعادة بدء الاتصال فوراً لطلب كود QR جديد للحساب الجديد
      _log('جاري تشغيل المتصفح لطلب رمز QR للحساب الجديد...', type: WhatsappLogType.info);
      await connect();
    } catch (e) {
      _log('فشل تغيير الحساب: $e', type: WhatsappLogType.error);
      _isConnecting = false;
      _connectionStatus = 'فشل تغيير الحساب';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // وظائف إرسال الرسائل
  // ═══════════════════════════════════════════════════════════════════════════

  /// تنسيق وتنظيف رقم الهاتف
  static String cleanPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('00')) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('0')) {
      cleaned = '20${cleaned.substring(1)}';
    } else if (cleaned.length == 10 && !cleaned.startsWith('20')) {
      cleaned = '20$cleaned';
    }
    return cleaned;
  }

  /// إرسال رسالة فردية
  Future<bool> sendSingleMessage(String phone, String message) async {
    if (_client == null || !_isConnected) {
      _log('يجب الاتصال أولاً لإرسال الرسائل!', type: WhatsappLogType.error);
      throw Exception('الواتساب غير متصل');
    }

    final cleanedPhone = cleanPhone(phone);
    try {
      final jsCode = "WPP.chat.sendTextMessage('$cleanedPhone@c.us', `$message`, { createChat: true })";
      final result = await _client!.executeFunction(jsCode);

      if (result != null && result is Map && result['id'] == null) {
        throw Exception('الرقم غير صالح أو لم يتم التوصيل: $result');
      }

      _log('تم إرسال الرسالة إلى $cleanedPhone ✓', type: WhatsappLogType.success);
      return true;
    } catch (e) {
      _log('فشل إرسال الرسالة إلى $cleanedPhone: $e', type: WhatsappLogType.error);
      rethrow;
    }
  }

  /// إرسال رسائل جماعية في الخلفية
  Future<void> sendBulkMessages(
    List<Map<String, String>> items, // [{'phone': '...', 'message': '...', 'name': '...'}]
  ) async {
    if (_client == null || !_isConnected) {
      _log('يجب الاتصال أولاً للإرسال الجماعي!', type: WhatsappLogType.error);
      return;
    }

    if (items.isEmpty) {
      _log('قائمة الإرسال فارغة', type: WhatsappLogType.error);
      return;
    }

    _isSendingBulk = true;
    _bulkTotal = items.length;
    _bulkSent = 0;
    _bulkFailed = 0;
    notifyListeners();

    _log('بدء الإرسال الجماعي في الخلفية لـ ${items.length} عضو...', type: WhatsappLogType.info);

    for (int i = 0; i < items.length; i++) {
      if (!_isSendingBulk) {
        _log('تم إيقاف الإرسال الجماعي بناءً على طلب المستخدم', type: WhatsappLogType.info);
        break;
      }

      final item = items[i];
      final phone = item['phone'] ?? '';
      final message = item['message'] ?? '';
      final name = item['name'] ?? phone;
      final cleanedPhone = cleanPhone(phone);

      try {
        final jsCode = "WPP.chat.sendTextMessage('$cleanedPhone@c.us', `$message`, { createChat: true })";
        final result = await _client!.executeFunction(jsCode);

        if (result != null && result is Map && result['id'] == null) {
          throw Exception('الرقم غير صالح: $result');
        }

        _bulkSent++;
        _log('✓ تم الإرسال لـ $name ($cleanedPhone)', type: WhatsappLogType.success);
      } catch (e) {
        _bulkFailed++;
        _log('✗ فشل الإرسال لـ $name: $e', type: WhatsappLogType.error);
      }

      notifyListeners();

      // تأخير زمني بين الرسائل
      if (i < items.length - 1 && _isSendingBulk) {
        await Future.delayed(Duration(seconds: _bulkDelay));
      }
    }

    _isSendingBulk = false;
    _log(
      'اكتمل الإرسال الجماعي — نجح: $_bulkSent | فشل: $_bulkFailed | إجمالي: $_bulkTotal',
      type: WhatsappLogType.success,
    );
    notifyListeners();
  }

  /// إيقاف الإرسال الجماعي الجاري
  void stopBulkSending() {
    _isSendingBulk = false;
    _log('تم طلب إيقاف الإرسال الجماعي', type: WhatsappLogType.info);
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// نماذج السجلات
// ═══════════════════════════════════════════════════════════════════════════

class WhatsappLogEntry {
  final String message;
  final DateTime time;
  final WhatsappLogType type;

  WhatsappLogEntry({
    required this.message,
    required this.time,
    this.type = WhatsappLogType.info,
  });
}

enum WhatsappLogType {
  info(Icons.info_outline_rounded, Colors.grey),
  success(Icons.check_circle_outline_rounded, Colors.green),
  error(Icons.error_outline_rounded, Colors.red),
  incoming(Icons.call_received_rounded, Colors.blue);

  final IconData icon;
  final Color color;
  const WhatsappLogType(this.icon, this.color);
}
