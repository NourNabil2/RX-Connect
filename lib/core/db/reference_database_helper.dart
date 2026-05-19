import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class ReferenceDatabaseHelper {
  static final ReferenceDatabaseHelper _instance = ReferenceDatabaseHelper._internal();
  factory ReferenceDatabaseHelper() => _instance;
  ReferenceDatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String dbPath = join(documentsDirectory.path, 'medical_reference.db');

    if (!await databaseExists(dbPath)) {
      await _copyDatabaseFromAssets(dbPath);
    }

    return openDatabase(dbPath, readOnly: true, singleInstance: true);
  }

  Future<void> _copyDatabaseFromAssets(String dbPath) async {
    try {
      debugPrint('📦 Copying medical_reference.db from assets...');
      await Directory(dirname(dbPath)).create(recursive: true);

      final ByteData data = await rootBundle.load('assets/db/medical_reference.db');
      final List<int> bytes = data.buffer.asUint8List();
      await File(dbPath).writeAsBytes(bytes, flush: true);

      debugPrint('✅ Medical reference database copied to $dbPath');
    } catch (e) {
      debugPrint('❌ Failed to copy medical_reference.db: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // ==================== NORMALIZED SCHEMA QUERIES ====================

  /// ⬅️ التعديل هنا: إرجاع String بدل int
  Future<String?> resolveTradeName(String brandName) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'trade_names',
        columns: ['active_ingredient_id'],
        where: 'brand_name COLLATE NOCASE = ?',
        whereArgs: [brandName.trim()],
        limit: 1,
      );
      return results.isNotEmpty ? results.first['active_ingredient_id'] as String : null;
    } catch (e) {
      debugPrint('❌ DB Error resolveTradeName("$brandName"): $e');
      return null;
    }
  }

  /// ⬅️ التعديل هنا: إرجاع String بدل int
  Future<String?> getActiveIngredientIdByName(String ingredientName) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'active_ingredients',
        columns: ['id'],
        where: 'name COLLATE NOCASE = ?',
        whereArgs: [ingredientName.trim()],
        limit: 1,
      );
      return results.isNotEmpty ? results.first['id'] as String : null;
    } catch (e) {
      debugPrint('❌ DB Error getActiveIngredientIdByName("$ingredientName"): $e');
      return null;
    }
  }

  /// ⬅️ استقبال String
  Future<Map<String, dynamic>?> getActiveIngredient(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'active_ingredients',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      debugPrint('❌ DB Error getActiveIngredient($id): $e');
      return null;
    }
  }

  /// ⬅️ استقبال String
  Future<List<Map<String, dynamic>>> findInteractions(
      String ingredient1Id,
      String ingredient2Id,
      ) async {
    try {
      final db = await database;
      return db.query(
        'interactions',
        where:
        '(ingredient_1_id = ? AND ingredient_2_id = ?) OR (ingredient_1_id = ? AND ingredient_2_id = ?)',
        whereArgs: [ingredient1Id, ingredient2Id, ingredient2Id, ingredient1Id],
      );
    } catch (e) {
      debugPrint('❌ DB Error findInteractions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchTradeNames(String query, {int limit = 20}) async {
    try {
      final db = await database;
      if (query.trim().isEmpty) return [];

      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT t.brand_name, t.active_ingredient_id, a.name as active_ingredient_name
        FROM trade_names t
        INNER JOIN active_ingredients a ON t.active_ingredient_id = a.id
        WHERE t.brand_name LIKE ? COLLATE NOCASE
        ORDER BY t.brand_name ASC
        LIMIT ?
      ''', ['%${query.trim()}%', limit]);

      return results;
    } catch (e) {
      debugPrint('❌ DB Error searchTradeNames("$query"): $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllTradeNames({int limit = 50}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT t.brand_name, t.active_ingredient_id, a.name as active_ingredient_name
        FROM trade_names t
        INNER JOIN active_ingredients a ON t.active_ingredient_id = a.id
        ORDER BY t.brand_name ASC
        LIMIT ?
      ''', [limit]);
      return results;
    } catch (e) {
      return [];
    }
  }

  /// ⬅️ استقبال String
  Future<String?> getActiveIngredientName(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'active_ingredients',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return results.isNotEmpty ? results.first['name'] as String : null;
    } catch (e) {
      return null;
    }
  }
}