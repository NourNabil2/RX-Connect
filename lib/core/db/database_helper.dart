import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'virtual_pharmacist.db');

    return await openDatabase(
      path,
      version: 2, // ⬅️ التعديل 1: رفع الإصدار إلى 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Medications Table
    await db.execute('''
      CREATE TABLE medications (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        activeIngredient TEXT,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        times TEXT NOT NULL,
        imageUrl TEXT,
        startDate TEXT NOT NULL,
        endDate TEXT,
        notes TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Adherence Logs Table
    await db.execute('''
      CREATE TABLE adherence_logs (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        medicationId TEXT NOT NULL,
        medicationName TEXT NOT NULL, -- ⬅️ التعديل 2: إضافة العمود هنا للنسخ الجديدة
        scheduledTime TEXT NOT NULL,
        takenTime TEXT,
        status TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (medicationId) REFERENCES medications (id)
      )
    ''');

    // Reminders Table (للتنبيهات المحلية)
    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        medicationId TEXT NOT NULL,
        time TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (medicationId) REFERENCES medications (id)
      )
    ''');

    // Drug Interactions Cache (للتفاعلات الدوائية)
    await db.execute('''
      CREATE TABLE drug_interactions (
        id TEXT PRIMARY KEY,
        drug1 TEXT NOT NULL,
        drug2 TEXT NOT NULL,
        severity TEXT NOT NULL,
        description TEXT NOT NULL,
        recommendation TEXT NOT NULL
      )
    ''');

    // Medications Database (قاعدة بيانات الأدوية المحلية)
    await db.execute('''
      CREATE TABLE medications_database (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        nameAr TEXT,
        activeIngredient TEXT NOT NULL,
        category TEXT,
        imageUrl TEXT,
        defaultDosage TEXT,
        sideEffects TEXT,
        contraindications TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // ⬅️ التعديل 3: عمل Migration سلس لقاعدة البيانات القديمة
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE adherence_logs ADD COLUMN medicationName TEXT DEFAULT ""');
    }
  }

  // ==================== MEDICATIONS CRUD ====================

  Future<int> insertMedication(Map<String, dynamic> medication) async {
    final db = await database;
    return await db.insert('medications', medication);
  }

  Future<List<Map<String, dynamic>>> getAllMedications(String userId) async {
    final db = await database;
    return await db.query(
      'medications',
      where: 'userId = ? AND isActive = ?',
      whereArgs: [userId, 1],
      orderBy: 'createdAt DESC',
    );
  }

  Future<Map<String, dynamic>?> getMedicationById(String id) async {
    final db = await database;
    final results = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateMedication(Map<String, dynamic> medication) async {
    final db = await database;
    final id = medication['id'] as String;

    // لا تُحدّث `id`, `userId`, `createdAt`
    final updateMap = Map<String, dynamic>.from(medication)
      ..remove('id')
      ..remove('userId')
      ..remove('createdAt');

    return await db.update(
      'medications',
      updateMap,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMedication(String id) async {
    final db = await database;
    // Soft delete
    return await db.update(
      'medications',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== ADHERENCE LOGS ====================

  Future<int> insertAdherenceLog(Map<String, dynamic> log) async {
    final db = await database;
    return await db.insert('adherence_logs', log);
  }

  Future<List<Map<String, dynamic>>> getAdherenceLogs(
      String userId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    final db = await database;
    return await db.query(
      'adherence_logs',
      where: 'userId = ? AND scheduledTime BETWEEN ? AND ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'scheduledTime DESC',
    );
  }

  Future<double> getAdherenceRate(String userId, DateTime startDate, DateTime endDate) async {
    final db = await database;

    final total = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM adherence_logs WHERE userId = ? AND scheduledTime BETWEEN ? AND ?',
        [userId, startDate.toIso8601String(), endDate.toIso8601String()],
      ),
    );

    final taken = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM adherence_logs WHERE userId = ? AND status = ? AND scheduledTime BETWEEN ? AND ?',
        [userId, 'taken', startDate.toIso8601String(), endDate.toIso8601String()],
      ),
    );

    if (total == null || total == 0) return 0.0;
    return (taken ?? 0) / total * 100;
  }

  // ==================== REMINDERS ====================

  Future<int> insertReminder(Map<String, dynamic> reminder) async {
    final db = await database;
    return await db.insert('reminders', reminder);
  }

  Future<List<Map<String, dynamic>>> getReminders(String medicationId) async {
    final db = await database;
    return await db.query(
      'reminders',
      where: 'medicationId = ? AND enabled = ?',
      whereArgs: [medicationId, 1],
    );
  }

  Future<int> updateReminder(String id, Map<String, dynamic> reminder) async {
    final db = await database;
    return await db.update(
      'reminders',
      reminder,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== DRUG INTERACTIONS ====================

  Future<List<Map<String, dynamic>>> checkInteractions(
      String drugName,
      List<String> currentMedications,
      ) async {
    final db = await database;

    // البحث عن التفاعلات في الكاش المحلي
    List<Map<String, dynamic>> interactions = [];

    for (String medication in currentMedications) {
      final results = await db.query(
        'drug_interactions',
        where: '(drug1 = ? AND drug2 = ?) OR (drug1 = ? AND drug2 = ?)',
        whereArgs: [drugName, medication, medication, drugName],
      );

      interactions.addAll(results);
    }

    return interactions;
  }

  Future<int> cacheInteraction(Map<String, dynamic> interaction) async {
    final db = await database;
    return await db.insert(
      'drug_interactions',
      interaction,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== MEDICATIONS DATABASE ====================

  Future<int> insertMedicationData(Map<String, dynamic> medication) async {
    final db = await database;
    return await db.insert(
      'medications_database',
      medication,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> searchMedicationsDatabase(String query) async {
    final db = await database;
    return await db.query(
      'medications_database',
      where: 'name LIKE ? OR nameAr LIKE ? OR activeIngredient LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      limit: 20,
    );
  }

  Future<Map<String, dynamic>?> getMedicationByName(String name) async {
    final db = await database;
    final results = await db.query(
      'medications_database',
      where: 'name = ? OR nameAr = ?',
      whereArgs: [name, name],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // ==================== UTILITY ====================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('medications');
    await db.delete('adherence_logs');
    await db.delete('reminders');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}