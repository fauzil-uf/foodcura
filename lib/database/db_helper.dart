import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../constants/app_date_formatter.dart';
import '../models/food_item_model.dart';
import '../models/food_log_model.dart';
import '../models/user_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  static const String tableFoods = 'foods';
  static const String tableFoodLogs = 'food_logs';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 6) {
          await db.execute('DROP TABLE IF EXISTS $tableFoods');
          await db.execute('DROP TABLE IF EXISTS $tableFoodLogs');
          await _createTables(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableUsers}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableFoods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        category TEXT NOT NULL,
        image_path TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableFoodLogs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        food_name TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        image_path TEXT NOT NULL,
        time TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');

    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    try {
      final csvString = await rootBundle.loadString('assets/food_data.csv');
      final lines = csvString.split('\n');
      final batch = db.batch();
      final seenNames = <String>{};
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isNotEmpty) {
          final food = FoodItemModel.fromCsvLine(line);
          final key = food.name.trim().toLowerCase();
          if (!seenNames.contains(key)) {
            seenNames.add(key);
            batch.insert(
              tableFoods,
              food.toMap()..remove('id'),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }
      await batch.commit(noResult: true);
    } catch (_) {
      // Fallback
    }

    final today = AppDateFormatter.formatToday();
    final initialLogs = [
      FoodLogModel(
        foodName: 'Roti Putih',
        mealType: 'Sarapan',
        calories: 248,
        protein: 8.0,
        carbs: 50.0,
        fat: 1.2,
        imagePath: 'assets/images/food/roti_putih.png',
        time: '07:30',
        date: today,
      ),
      FoodLogModel(
        foodName: 'Telur Rebus',
        mealType: 'Sarapan',
        calories: 154,
        protein: 12.53,
        carbs: 1.12,
        fat: 10.57,
        imagePath: 'assets/images/food/telur_rebus.png',
        time: '08:00',
        date: today,
      ),
      FoodLogModel(
        foodName: 'Nasi',
        mealType: 'Makan Siang',
        calories: 180,
        protein: 3.0,
        carbs: 39.8,
        fat: 0.3,
        imagePath: 'assets/images/food/nasi.png',
        time: '12:00',
        date: today,
      ),
      FoodLogModel(
        foodName: 'Ayam taliwang',
        mealType: 'Makan Siang',
        calories: 264,
        protein: 18.2,
        carbs: 2.7,
        fat: 20.1,
        imagePath: 'assets/images/food/ayam_taliwang.png',
        time: '12:30',
        date: today,
      ),
      FoodLogModel(
        foodName: 'Cap cai sayur',
        mealType: 'Makan Siang',
        calories: 97,
        protein: 5.8,
        carbs: 4.2,
        fat: 6.3,
        imagePath: 'assets/images/food/cap_cai.png',
        time: '13:00',
        date: today,
      ),
      FoodLogModel(
        foodName: 'Ayam',
        mealType: 'Makan Malam',
        calories: 302,
        protein: 18.2,
        carbs: 0.0,
        fat: 25.0,
        imagePath: 'assets/images/food/ayam.png',
        time: '18:45',
        date: today,
      ),
      FoodLogModel(
        foodName: 'Kangkung tumis',
        mealType: 'Makan Malam',
        calories: 52,
        protein: 1.8,
        carbs: 3.0,
        fat: 3.6,
        imagePath: 'assets/images/food/kangkung.png',
        time: '19:15',
        date: today,
      ),
      FoodLogModel(
        foodName: 'Apel',
        mealType: 'Camilan',
        calories: 58,
        protein: 0.3,
        carbs: 14.9,
        fat: 0.4,
        imagePath: 'assets/images/food/apel.png',
        time: '15:30',
        date: today,
        note: 'Apel segar, manis dan renyah.',
      ),
      FoodLogModel(
        foodName: 'Yoghurt',
        mealType: 'Camilan',
        calories: 52,
        protein: 3.3,
        carbs: 4.0,
        fat: 2.5,
        imagePath: 'assets/images/food/yoghurt.png',
        time: '16:10',
        date: today,
      ),
    ];

    for (var log in initialLogs) {
      await db.insert(
        tableFoodLogs,
        log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // --- USER AUTH CRUD ---
  Future<bool> registerUser(UserModelSQL pengguna) async {
    final db = await database;
    try {
      await db.insert(
        AppConstants.tableUsers,
        pengguna.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<UserModelSQL?> loginUser(String email, String password) async {
    final db = await database;
    final results = await db.query(
      AppConstants.tableUsers,
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (results.isNotEmpty) {
      return UserModelSQL.fromMap(results.first);
    }
    return null;
  }

  Future<bool> isEmailRegistered(String email) async {
    final db = await database;
    final results = await db.query(
      AppConstants.tableUsers,
      where: 'email = ?',
      whereArgs: [email],
    );
    return results.isNotEmpty;
  }

  Future<List<UserModelSQL>> getAllUsers() async {
    final db = await database;
    final results = await db.query(AppConstants.tableUsers);
    return results.map((map) => UserModelSQL.fromMap(map)).toList();
  }

  // --- FOOD CATALOG CRUD ---
  Future<List<FoodItemModel>> getFoodCatalog() async {
    final db = await database;
    final results = await db.rawQuery('SELECT * FROM $tableFoods GROUP BY LOWER(TRIM(name))');
    return results.map((map) => FoodItemModel.fromMap(map)).toList();
  }

  Future<List<FoodItemModel>> searchFoodCatalog(String query) async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT * FROM $tableFoods WHERE (name LIKE ? OR category LIKE ?) GROUP BY LOWER(TRIM(name))',
      ['%$query%', '%$query%'],
    );
    return results.map((map) => FoodItemModel.fromMap(map)).toList();
  }

  Future<List<FoodItemModel>> getRecentAddedFoods({int limit = 10}) async {
    final db = await database;
    final results = await db.query(
      tableFoodLogs,
      orderBy: 'id DESC',
    );

    final seenNames = <String>{};
    final List<FoodItemModel> recentFoods = [];

    for (var map in results) {
      final log = FoodLogModel.fromMap(map);
      final key = log.foodName.trim().toLowerCase();
      if (!seenNames.contains(key)) {
        seenNames.add(key);
        recentFoods.add(FoodItemModel(
          name: log.foodName,
          calories: log.calories,
          protein: log.protein,
          carbs: log.carbs,
          fat: log.fat,
          category: log.mealType,
          imagePath: log.imagePath,
        ));
      }
      if (recentFoods.length >= limit) break;
    }

    if (recentFoods.isEmpty) {
      final catalog = await getFoodCatalog();
      return catalog.take(limit).toList();
    }

    return recentFoods;
  }

  // --- FOOD LOGS CRUD ---
  Future<List<FoodLogModel>> getFoodLogs({String? date}) async {
    final db = await database;
    final targetDate = date ?? AppDateFormatter.formatToday();
    var results = await db.query(
      tableFoodLogs,
      where: 'date = ?',
      whereArgs: [targetDate],
      orderBy: 'id DESC',
    );

    // If no logs for target date, fallback to all logs
    if (results.isEmpty) {
      results = await db.query(
        tableFoodLogs,
        orderBy: 'id DESC',
      );
    }
    return results.map((map) => FoodLogModel.fromMap(map)).toList();
  }

  Future<List<FoodLogModel>> getFoodLogsByMeal(
    String mealType, {
    String? date,
  }) async {
    final db = await database;
    final targetDate = date ?? AppDateFormatter.formatToday();
    var results = await db.query(
      tableFoodLogs,
      where: 'date = ? AND meal_type = ?',
      whereArgs: [targetDate, mealType],
      orderBy: 'id DESC',
    );

    if (results.isEmpty) {
      results = await db.query(
        tableFoodLogs,
        where: 'meal_type = ?',
        whereArgs: [mealType],
        orderBy: 'id DESC',
      );
    }
    return results.map((map) => FoodLogModel.fromMap(map)).toList();
  }

  Future<int> addFoodLog(FoodLogModel log) async {
    final db = await database;
    return await db.insert(
      tableFoodLogs,
      log.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateFoodLog(FoodLogModel log) async {
    final db = await database;
    if (log.id == null) return 0;
    return await db.update(
      tableFoodLogs,
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteFoodLog(int id) async {
    final db = await database;
    return await db.delete(
      tableFoodLogs,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
