import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Singleton لإدارة قاعدة بيانات SQLite.
/// يتعامل مع إنشاء وفتح قاعدة البيانات وإنشاء الجداول.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static const int _databaseVersion = 3;
  static const String _databaseName = 'sparta_gym.db';

  /// الحصول على قاعدة البيانات (إنشاؤها إذا لم تكن موجودة)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// تهيئة قاعدة البيانات
  Future<Database> _initDatabase() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDocDir.path, 'SpartaGym', _databaseName);

    return await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// إنشاء الجداول عند إنشاء قاعدة البيانات لأول مرة
  Future<void> _onCreate(Database db, int version) async {
    // جدول الأعضاء
    await db.execute('''
      CREATE TABLE IF NOT EXISTS members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memberId TEXT NOT NULL UNIQUE,
        fullName TEXT NOT NULL,
        phoneNumber TEXT,
        email TEXT,
        gender TEXT,
        birthDate TEXT,
        address TEXT,
        nationalId TEXT,
        emergencyContact TEXT,
        membershipType TEXT NOT NULL,
        membershipPrice REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        paidAmount REAL NOT NULL DEFAULT 0,
        remainingAmount REAL NOT NULL DEFAULT 0,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        trainerName TEXT,
        notes TEXT,
        memberPhotoPath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // جدول مستخدمي النظام (المصادقة والترخيص)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        full_name TEXT,
        device_id TEXT,
        subscription_type TEXT NOT NULL,
        expiry_date TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // جدول باقات الاشتراكات (Memberships)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS memberships (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        durationDays INTEGER NOT NULL DEFAULT 30,
        price REAL NOT NULL DEFAULT 0,
        freezeDays INTEGER NOT NULL DEFAULT 0,
        visitsLimit INTEGER,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    // إدخال باقات افتراضية
    final nowStr = DateTime.now().toIso8601String();
    await db.insert('memberships', {
      'name': 'شهري',
      'durationDays': 30,
      'price': 300.0,
      'freezeDays': 0,
      'visitsLimit': null,
      'isActive': 1,
      'createdAt': nowStr,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('memberships', {
      'name': 'ربع سنوي',
      'durationDays': 90,
      'price': 800.0,
      'freezeDays': 7,
      'visitsLimit': null,
      'isActive': 1,
      'createdAt': nowStr,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('memberships', {
      'name': 'نصف سنوي',
      'durationDays': 180,
      'price': 1500.0,
      'freezeDays': 15,
      'visitsLimit': null,
      'isActive': 1,
      'createdAt': nowStr,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('memberships', {
      'name': 'سنوي',
      'durationDays': 365,
      'price': 2800.0,
      'freezeDays': 30,
      'visitsLimit': null,
      'isActive': 1,
      'createdAt': nowStr,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // فهارس لتسريع البحث
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_members_memberId ON members(memberId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_members_fullName ON members(fullName)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_members_phoneNumber ON members(phoneNumber)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_members_endDate ON members(endDate)');

    // جدول الحضور والانصراف (Attendance)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memberId TEXT NOT NULL,
        checkInTime TEXT NOT NULL,
        checkOutTime TEXT,
        durationMinutes INTEGER,
        FOREIGN KEY(memberId) REFERENCES members(memberId) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_attendance_memberId ON attendance(memberId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_attendance_checkInTime ON attendance(checkInTime)');

    // جدول المدفوعات (Payments)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receiptId TEXT NOT NULL UNIQUE,
        memberId TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        paymentDate TEXT NOT NULL,
        employeeName TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY(memberId) REFERENCES members(memberId) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payments_memberId ON payments(memberId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payments_paymentDate ON payments(paymentDate)');
  }

  /// ترقية قاعدة البيانات عند تحديث الإصدار
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS attendance (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          memberId TEXT NOT NULL,
          checkInTime TEXT NOT NULL,
          checkOutTime TEXT,
          durationMinutes INTEGER,
          FOREIGN KEY(memberId) REFERENCES members(memberId) ON DELETE CASCADE
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_attendance_memberId ON attendance(memberId)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_attendance_checkInTime ON attendance(checkInTime)');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          receiptId TEXT NOT NULL UNIQUE,
          memberId TEXT NOT NULL,
          amount REAL NOT NULL,
          paymentMethod TEXT NOT NULL,
          paymentDate TEXT NOT NULL,
          employeeName TEXT NOT NULL,
          notes TEXT,
          FOREIGN KEY(memberId) REFERENCES members(memberId) ON DELETE CASCADE
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_payments_memberId ON payments(memberId)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_payments_paymentDate ON payments(paymentDate)');
    }
  }

  /// إغلاق قاعدة البيانات
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
