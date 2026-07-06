import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Singleton لإدارة قاعدة بيانات SQLite.
/// يتعامل مع إنشاء وفتح قاعدة البيانات وإنشاء الجداول وتحديثها.
class DatabaseHelper {
  // ==========================================
  // 1. إعدادات الـ Singleton
  // ==========================================
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  // ==========================================
  // 2. إعدادات قاعدة البيانات
  // ==========================================
  static const int _databaseVersion = 3;
  static const String _databaseName = 'sparta_gym_v1.db';

  // ==========================================
  // 3. تهيئة قاعدة البيانات والوصول إليها
  // ==========================================

  /// الحصول على قاعدة البيانات (إنشاؤها إذا لم تكن موجودة)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// تهيئة قاعدة البيانات وتحديد مسارها
  Future<Database> _initDatabase() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDocDir.path, 'SpartaGym', _databaseName);

    return await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: onDatabaseDowngradeDelete,
      ),
    );
  }

  // ==========================================
  // 4. بناء قاعدة البيانات (_onCreate)
  // ==========================================

  /// إنشاء الجداول الأساسية عند بناء قاعدة البيانات لأول مرة
  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
    await _createAllIndexes(db);
    await _insertDefaultInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // ── الترقية من v1 إلى v2: نظام الشفتات والموظفين ──

      // 1. إنشاء جدول الموظفين
      await db.execute('''
        CREATE TABLE IF NOT EXISTS employees (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          password TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'employee',
          isActive INTEGER NOT NULL DEFAULT 1,
          createdAt TEXT NOT NULL
        )
      ''');

      // 2. إنشاء جدول الشفتات
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shifts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          employeeId INTEGER NOT NULL,
          employeeName TEXT NOT NULL,
          startTime TEXT NOT NULL,
          endTime TEXT,
          isActive INTEGER NOT NULL DEFAULT 1,
          notes TEXT,
          FOREIGN KEY(employeeId) REFERENCES employees(id) ON DELETE CASCADE
        )
      ''');

      // 3. إضافة عمود shiftId للجداول الحالية
      await db.execute('ALTER TABLE payments ADD COLUMN shiftId INTEGER');
      await db.execute('ALTER TABLE pos_sales ADD COLUMN shiftId INTEGER');
      await db.execute('ALTER TABLE expenses ADD COLUMN shiftId INTEGER');

      // 4. إنشاء فهارس للجداول الجديدة
      await db.execute('CREATE INDEX IF NOT EXISTS idx_shifts_employeeId ON shifts(employeeId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_shifts_isActive ON shifts(isActive)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_employees_name ON employees(name)');

      // 5. إدخال حساب مدير افتراضي (كلمة السر: admin)
      await _insertDefaultAdmin(db);
    }

    if (oldVersion < 3) {
      // ── الترقية إلى v3: جدولة الشفتات التلقائية ──
      await db.execute('''
        CREATE TABLE IF NOT EXISTS scheduled_shifts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          employeeId INTEGER NOT NULL,
          employeeName TEXT NOT NULL,
          startHour INTEGER NOT NULL,
          startMinute INTEGER NOT NULL,
          endHour INTEGER,
          endMinute INTEGER,
          isEnabled INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY(employeeId) REFERENCES employees(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  /// دالة مساعدة لإنشاء جميع الجداول
  Future<void> _createAllTables(Database db) async {
    // 1. جدول الأعضاء
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
        dietPlanId INTEGER,
        additionalServicesIds TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 2. جدول مستخدمي النظام (المصادقة والترخيص)
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

    // 3. جدول باقات الاشتراكات
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

    // 4. جدول المدربين
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trainers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        phoneNumber TEXT NOT NULL DEFAULT '',
        specialization TEXT,
        price REAL,
        workingHours TEXT,
        notes TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    // 5. جدول الحضور والانصراف
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

    // 6. جدول المدفوعات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receiptId TEXT NOT NULL UNIQUE,
        memberId TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        paymentDate TEXT NOT NULL,
        employeeName TEXT NOT NULL,
        shiftId INTEGER,
        notes TEXT,
        FOREIGN KEY(memberId) REFERENCES members(memberId) ON DELETE CASCADE
      )
    ''');

    // 7. جدول الأنظمة الغذائية
    await db.execute('''
      CREATE TABLE IF NOT EXISTS diet_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        meals TEXT NOT NULL,
        notes TEXT,
        price REAL NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // 8. جدول المصروفات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        shiftId INTEGER,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 9. جدول عناصر المخزون
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        cost REAL NOT NULL DEFAULT 0,
        quantity INTEGER NOT NULL DEFAULT 0,
        barcode TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 10. جدول المبيعات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receiptId TEXT NOT NULL UNIQUE,
        totalAmount REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        finalAmount REAL NOT NULL DEFAULT 0,
        paymentMethod TEXT NOT NULL,
        memberId TEXT,
        shiftId INTEGER,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // 11. جدول عناصر المبيعات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        itemId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY(saleId) REFERENCES pos_sales(id) ON DELETE CASCADE,
        FOREIGN KEY(itemId) REFERENCES inventory_items(id) ON DELETE RESTRICT
      )
    ''');

    // 12. جدول أكواد الخصم
    await db.execute('''
      CREATE TABLE IF NOT EXISTS discount_codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // 13. جدول الخدمات الإضافية
    await db.execute('''
      CREATE TABLE IF NOT EXISTS additional_services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        monthlyPrice REAL NOT NULL DEFAULT 0,
        visitsLimit INTEGER NOT NULL DEFAULT 0,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    // 14. جدول الموظفين
    await db.execute('''
      CREATE TABLE IF NOT EXISTS employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'employee',
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    // 15. جدول الشفتات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER NOT NULL,
        employeeName TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        FOREIGN KEY(employeeId) REFERENCES employees(id) ON DELETE CASCADE
      )
    ''');

    // 16. جدول جدولة الشفتات التلقائية
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scheduled_shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER NOT NULL,
        employeeName TEXT NOT NULL,
        startHour INTEGER NOT NULL,
        startMinute INTEGER NOT NULL,
        endHour INTEGER,
        endMinute INTEGER,
        isEnabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(employeeId) REFERENCES employees(id) ON DELETE CASCADE
      )
    ''');
  }

  /// دالة مساعدة لإنشاء الفهارس (Indexes) لتسريع البحث
  Future<void> _createAllIndexes(Database db) async {
    // فهارس الأعضاء
    await db.execute('CREATE INDEX IF NOT EXISTS idx_members_memberId ON members(memberId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_members_fullName ON members(fullName)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_members_phoneNumber ON members(phoneNumber)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_members_endDate ON members(endDate)');

    // فهارس الحضور
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attendance_memberId ON attendance(memberId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attendance_checkInTime ON attendance(checkInTime)');

    // فهارس المدفوعات
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_memberId ON payments(memberId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_paymentDate ON payments(paymentDate)');

    // فهارس الشفتات والموظفين
    await db.execute('CREATE INDEX IF NOT EXISTS idx_shifts_employeeId ON shifts(employeeId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_shifts_isActive ON shifts(isActive)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_employees_name ON employees(name)');
  }

  /// دالة مساعدة لإدخال البيانات الافتراضية للأنظمة الغذائية وباقات الاشتراك
  Future<void> _insertDefaultInitialData(Database db) async {
    final nowStr = DateTime.now().toIso8601String();

    // 1. إدخال باقات اشتراك افتراضية
    final defaultMemberships = [
      {'name': 'تمرينة واحدة', 'durationDays': 1, 'price': 50.0, 'freezeDays': 0, 'visitsLimit': 1, 'isActive': 1, 'createdAt': nowStr},
      {'name': 'شهري', 'durationDays': 30, 'price': 300.0, 'freezeDays': 0, 'visitsLimit': null, 'isActive': 1, 'createdAt': nowStr},
      {'name': 'ربع سنوي', 'durationDays': 90, 'price': 800.0, 'freezeDays': 7, 'visitsLimit': null, 'isActive': 1, 'createdAt': nowStr},
      {'name': 'نصف سنوي', 'durationDays': 180, 'price': 1500.0, 'freezeDays': 15, 'visitsLimit': null, 'isActive': 1, 'createdAt': nowStr},
      {'name': 'سنوي', 'durationDays': 365, 'price': 2800.0, 'freezeDays': 30, 'visitsLimit': null, 'isActive': 1, 'createdAt': nowStr},
    ];

    for (var membership in defaultMemberships) {
      await db.insert('memberships', membership, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // 2. إدخال 3 أنظمة غذائية افتراضية
    final defaultDietPlans = [
      {
        'name': 'نظام التضخيم (Bulking)',
        'description': 'نظام غذائي غني بالسعرات الحرارية والبروتين لزيادة الكتلة العضلية.',
        'meals': 'وجبة 1: شوفان وبيض وموز.\\nوجبة 2: دجاج وأرز وخضروات.\\nوجبة 3: لحم وبطاطس.\\nوجبة 4: تونة وسلطة.',
        'notes': 'تأكد من شرب 3-4 لتر ماء يومياً.',
        'price': 0.0,
        'createdAt': nowStr,
      },
      {
        'name': 'نظام التنشيف (Cutting)',
        'description': 'نظام غذائي قليل الكربوهيدرات لحرق الدهون مع الحفاظ على العضلات.',
        'meals': 'وجبة 1: بياض البيض وسبانخ.\\nوجبة 2: صدر دجاج مشوي مع بروكلي.\\nوجبة 3: سمك مشوي وسلطة خضراء.\\nوجبة 4: جبن قريش.',
        'notes': 'يُفضل ممارسة الكارديو بعد التمرين أو على معدة فارغة.',
        'price': 0.0,
        'createdAt': nowStr,
      },
      {
        'name': 'نظام المحافظة (Maintenance)',
        'description': 'نظام غذائي متوازن للحفاظ على الوزن الحالي واللياقة.',
        'meals': 'وجبة 1: بيض كامل وتوست أسمر.\\nوجبة 2: لحم أو دجاج مع أرز وسلطة.\\nوجبة 3: فواكه ومكسرات.\\nوجبة 4: زبادي يوناني وتونة.',
        'notes': 'يمكن أخذ وجبة مفتوحة (Cheat Meal) مرة في الأسبوع.',
        'price': 0.0,
        'createdAt': nowStr,
      }
    ];

    for (var plan in defaultDietPlans) {
      await db.insert('diet_plans', plan, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // 3. إدخال حساب مدير افتراضي
    await _insertDefaultAdmin(db);
  }

  /// إدخال حساب المدير الافتراضي
  Future<void> _insertDefaultAdmin(Database db) async {
    // التحقق من عدم وجود حساب مدير مسبقاً
    final existing = await db.query('employees', where: "role = 'admin'", limit: 1);
    if (existing.isEmpty) {
      // كلمة سر مشفرة لـ 'admin' باستخدام SHA-256
      const adminPasswordHash = '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918';
      await db.insert('employees', {
        'name': 'المدير',
        'password': adminPasswordHash,
        'role': 'admin',
        'isActive': 1,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // ==========================================
  // 5. إدارة الموارد (Resource Management)
  // ==========================================

  /// إغلاق قاعدة البيانات بأمان
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
