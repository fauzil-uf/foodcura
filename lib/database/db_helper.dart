import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../constants/app_date_formatter.dart';
import '../models/food_item_model.dart';
import '../models/food_log_model.dart';
import '../models/notification_model.dart';
import '../models/pantry_item_model.dart';
import '../models/user_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  static const String tableFoods = 'foods';
  static const String tableFoodLogs = 'food_logs';
  static const String tablePantryItems = 'pantry_items';
  static const String tableNotifications = 'notifications';

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
      version: 7,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 7) {
          await db.execute('DROP TABLE IF EXISTS $tableFoods');
          await db.execute('DROP TABLE IF EXISTS $tableFoodLogs');
          await db.execute('DROP TABLE IF EXISTS $tablePantryItems');
          await db.execute('DROP TABLE IF EXISTS $tableNotifications');
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tablePantryItems(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        storage TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        image_url TEXT,
        is_used INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableNotifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_type TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        related_pantry_id INTEGER,
        created_at TEXT NOT NULL
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

    // Seed pantry items (sesuai desain Stitch)
    await _seedPantryItems(db);
    // Seed initial notifications
    await _seedNotifications(db);
  }

  Future<void> _seedPantryItems(Database db) async {
    final now = DateTime.now();
    final pantryItems = [
      PantryItemModel(
        name: 'Bayam Segar',
        quantity: 250,
        unit: 'g',
        storage: 'Kulkas',
        expiryDate: now.add(const Duration(days: 1)),
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDcPiJEMCmQ3HRVbcyFp8QuNZfB2Vr7ZzCNSPq8LeWXK6gaKqr7yh_H9Rja8wkM4uPeESMs8zKA4_15t2Mocrk9z2SqiBk92cWAjaLf1Y0HhH-H-XB8cVIrAi0KAZdrtyzqunKTQ32fassRQ11luY8H-OFvzFvbNA5crL_QOu60aT4T53w0B1ZiqoGiuyQUMdug7vSyI1uUvJNXFZxCFWnpCYzkePmDwvoMNiFn6yIYkwDYnolDQWUSXg',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      PantryItemModel(
        name: 'Susu UHT',
        quantity: 1,
        unit: 'L',
        storage: 'Kulkas',
        expiryDate: now.add(const Duration(days: 3)),
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB32I-05BQEXVC37e4PNZcRpnBz8zeWtMIbFi_6T-9fgRmL2JW5p07288dFHdeXP65Og9U3g-thmRk42z55OafxmFOXx6u1oy6ooEmUACs60yzeNcgX21STQTXL44m3h68f5WWlkFo-YpMllThjowX17wBNZT6KMYTbWX0PEhu8uRvjms6e_GXJoAKTHAKwvBRY4dTdXskcfwYg7ThKcRXQ9mdIih9DgRvk-WbiqVN3cW771b0EYkFETg',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      PantryItemModel(
        name: 'Brokoli',
        quantity: 500,
        unit: 'g',
        storage: 'Kulkas',
        expiryDate: now.add(const Duration(days: 4)),
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuATlUqaIOqfCvcDojnBb5N9g8SQPgt9tAYN9PfDN5iEKn4N19cyAYqqBn_g4aNIOZto8yKnnZELsbE05Ih0_6NSMsEEZMkOu0bL3GGpoAnEEZyuC8X5_US5aXvu8-TbPLhpfr3bJAXygrBlVQkXF2JXcEEGFKI7sFphrlGFsuzRtCxxKQpbtb3c7RzWS2GwgVPvgX8CVNsoUVLJV8mUjBZPN1QEAcDW-eCGdn1RwVqxJHRUXV8zv6n7uA',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      PantryItemModel(
        name: 'Tomat',
        quantity: 300,
        unit: 'g',
        storage: 'Kulkas',
        expiryDate: now.add(const Duration(days: 6)),
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDXYXmeja6TqYF85erWaJQ-veCjYKcUY3kORbMh-oiRyPzZHGSEp6J5WJMP202AFMgSKIF7ufJtj-92476bUvNcaH29HZshBc79iG7Wbus2j56IK_urvsuCdKzJIXK-nY9dVqiwjY74OF6PohVQJuLqtCR2KbAtX_3F_5IUf0geW2nJoSCCkTpgaQE5L0CWp7M_HXneq6Z4jITPSv2RAeY2D-a5jnE2bhy0aMoV81wLNln7wMla8N5OPQ',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    for (var item in pantryItems) {
      await db.insert(
        tablePantryItems,
        item.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _seedNotifications(Database db) async {
    final now = DateTime.now();
    final notifications = [
      NotificationModel(
        title: 'Peringatan Lemak Jenuh Tinggi!',
        message: 'Asupan Lemak Jenuh hari ini (28.4g / 25g) telah melebihi batas harian. Batasi gorengan & santan.',
        type: 'nutrition_excess',
        iconType: 'warning',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 8)),
      ),
      NotificationModel(
        title: 'Bayam Segar hampir kadaluwarsa',
        message: 'Bayam Segar di kulkas akan kadaluwarsa dalam 1 hari.',
        type: 'expiry_warning',
        iconType: 'warning',
        relatedPantryId: 1,
        createdAt: now.subtract(const Duration(minutes: 25)),
      ),
      NotificationModel(
        title: 'Peringatan Kolesterol Tinggi!',
        message: 'Estimasi Kolesterol hari ini (320mg / 300mg) telah melebihi batas harian disarankan.',
        type: 'nutrition_excess',
        iconType: 'warning',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2, minutes: 15)),
      ),
      NotificationModel(
        title: 'Susu UHT hampir kadaluwarsa',
        message: 'Susu UHT di kulkas akan kadaluwarsa dalam 3 hari.',
        type: 'expiry_warning',
        iconType: 'warning',
        relatedPantryId: 2,
        createdAt: now.subtract(const Duration(hours: 4, minutes: 30)),
      ),
      NotificationModel(
        title: 'Brokoli perlu segera digunakan',
        message: 'Brokoli di kulkas akan kadaluwarsa dalam 4 hari.',
        type: 'expiry_warning',
        iconType: 'warning',
        relatedPantryId: 3,
        createdAt: now.subtract(const Duration(hours: 7)),
      ),
      NotificationModel(
        title: 'Tomat perlu segera digunakan',
        message: 'Tomat di kulkas akan kadaluwarsa dalam 6 hari.',
        type: 'expiry_warning',
        iconType: 'warning',
        relatedPantryId: 4,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      NotificationModel(
        title: 'Tips Food Rescue',
        message: 'Gunakan bahan yang paling dekat tanggal kadaluwarsanya terlebih dahulu.',
        type: 'tips',
        iconType: 'lightbulb',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      NotificationModel(
        title: 'FoodCura membantu kurangi food waste',
        message: 'Teruskan kebiasaan baik Anda menyelamatkan makanan!',
        type: 'system',
        iconType: 'eco',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];

    for (var notif in notifications) {
      await db.insert(
        tableNotifications,
        notif.toMap()..remove('id'),
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

  Future<NotificationModel?> addFoodLog(FoodLogModel log) async {
    final db = await database;
    await db.insert(
      tableFoodLogs,
      log.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Check nutrition excess after adding and return notification if triggered
    return await checkNutritionExcess();
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

  // --- PANTRY ITEMS CRUD ---
  Future<int> addPantryItem(PantryItemModel item) async {
    final db = await database;
    final id = await db.insert(
      tablePantryItems,
      item.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Check expiry after adding
    await checkExpiryAndCreateNotifications();
    return id;
  }

  Future<List<PantryItemModel>> getPantryItems({String? filter}) async {
    final db = await database;
    final results = await db.query(
      tablePantryItems,
      where: 'is_used = 0',
      orderBy: 'expiry_date ASC',
    );

    var items = results.map((map) => PantryItemModel.fromMap(map)).toList();

    // Apply filter
    if (filter != null) {
      switch (filter) {
        case 'urgent':
          items = items.where((i) => i.expiryStatus == 'urgent' || i.expiryStatus == 'expired').toList();
          break;
        case 'segera':
          items = items.where((i) => i.expiryStatus == 'segera').toList();
          break;
        case 'aman':
          items = items.where((i) => i.expiryStatus == 'aman').toList();
          break;
      }
    }

    return items;
  }

  Future<List<PantryItemModel>> searchPantryItems(String query) async {
    final db = await database;
    final results = await db.query(
      tablePantryItems,
      where: 'is_used = 0 AND name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'expiry_date ASC',
    );
    return results.map((map) => PantryItemModel.fromMap(map)).toList();
  }

  Future<int> markPantryItemUsed(int id) async {
    final db = await database;
    return await db.update(
      tablePantryItems,
      {'is_used': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePantryItem(int id) async {
    final db = await database;
    return await db.delete(
      tablePantryItems,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updatePantryItem(PantryItemModel item) async {
    final db = await database;
    if (item.id == null) return 0;
    return await db.update(
      tablePantryItems,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Count active pantry items by urgency status
  Future<Map<String, int>> getPantryStatusCounts() async {
    final items = await getPantryItems();
    int urgentCount = 0;
    int segeraCount = 0;
    int amanCount = 0;
    for (var item in items) {
      switch (item.expiryStatus) {
        case 'urgent':
        case 'expired':
          urgentCount++;
          break;
        case 'segera':
          segeraCount++;
          break;
        case 'aman':
          amanCount++;
          break;
      }
    }
    return {
      'urgent': urgentCount,
      'segera': segeraCount,
      'aman': amanCount,
      'total': items.length,
    };
  }

  // --- NOTIFICATIONS CRUD ---
  Future<int> addNotification(NotificationModel notif) async {
    final db = await database;
    return await db.insert(
      tableNotifications,
      notif.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NotificationModel>> getNotifications({String? filter}) async {
    // Auto-check expiry & nutrition excess before returning notifications
    await checkExpiryAndCreateNotifications();
    await checkNutritionExcess();

    final db = await database;
    String? where;
    List<Object?>? whereArgs;

    if (filter == 'unread') {
      where = 'is_read = 0';
    } else if (filter == 'expiry') {
      where = 'type = ?';
      whereArgs = ['expiry_warning'];
    } else if (filter == 'foodcura') {
      where = 'type IN (?, ?, ?)';
      whereArgs = ['nutrition_excess', 'tips', 'system'];
    }

    final results = await db.query(
      tableNotifications,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return results.map((map) => NotificationModel.fromMap(map)).toList();
  }

  Future<int> markNotificationRead(int id) async {
    final db = await database;
    return await db.update(
      tableNotifications,
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markAllNotificationsRead() async {
    final db = await database;
    return await db.update(
      tableNotifications,
      {'is_read': 1},
      where: 'is_read = 0',
    );
  }

  Future<int> getUnreadNotificationCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableNotifications WHERE is_read = 0',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // --- EXPIRY & NUTRITION CHECK ---

  /// Cek semua pantry items, buat notifikasi jika dekat expired
  Future<void> checkExpiryAndCreateNotifications() async {
    final db = await database;
    final items = await getPantryItems();

    for (var item in items) {
      final days = item.daysUntilExpiry;
      if (days <= 5) {
        // Cek apakah sudah ada notifikasi untuk item ini agar tidak spam
        final existing = await db.query(
          tableNotifications,
          where: 'related_pantry_id = ?',
          whereArgs: [item.id],
        );

        if (existing.isEmpty) {
          String title;
          String message;
          if (days <= 0) {
            title = '${item.name} sudah kadaluwarsa!';
            message = '${item.name} di ${item.storage.toLowerCase()} sudah melewati tanggal kadaluwarsa.';
          } else if (days <= 2) {
            title = '${item.name} hampir kadaluwarsa';
            message = '${item.name} di ${item.storage.toLowerCase()} akan kadaluwarsa dalam $days hari.';
          } else {
            title = '${item.name} perlu segera digunakan';
            message = '${item.name} di ${item.storage.toLowerCase()} akan kadaluwarsa dalam $days hari.';
          }

          await addNotification(NotificationModel(
            title: title,
            message: message,
            type: 'expiry_warning',
            iconType: 'warning',
            relatedPantryId: item.id,
            createdAt: DateTime.now(),
          ));
        }
      }
    }
  }

  /// Cek nutrisi harian, jika kelebihan buat notifikasi per-nutrisi & simpan ke database
  Future<NotificationModel?> checkNutritionExcess() async {
    final db = await database;
    final todayStr = AppDateFormatter.formatToday();

    // Ambil semua food logs hari ini
    final logs = await db.query(
      tableFoodLogs,
      where: 'date = ?',
      whereArgs: [todayStr],
    );

    if (logs.isEmpty) return null;

    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var log in logs) {
      totalCalories += (log['calories'] as num).toInt();
      totalProtein += (log['protein'] as num).toDouble();
      totalCarbs += (log['carbs'] as num).toDouble();
      totalFat += (log['fat'] as num).toDouble();
    }

    double totalCholesterol = (totalFat * 4.5 + totalProtein * 3.5);
    if (totalCholesterol <= 0) totalCholesterol = 180.0;

    // Target harian
    const maxCalories = 2000;
    const maxProtein = 65.0;
    const maxCarbs = 300.0;
    const maxFat = 25.0; // Lemak Jenuh
    const maxCholesterol = 300.0;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();

    NotificationModel? newlyCreatedNotif;

    // 1. Cek Lemak Jenuh
    if (totalFat >= maxFat) {
      final existing = await db.query(
        tableNotifications,
        where: 'title LIKE ? AND created_at >= ?',
        whereArgs: ['%Lemak Jenuh%', startOfDay],
      );
      if (existing.isEmpty) {
        final notif = NotificationModel(
          title: 'Peringatan Lemak Jenuh Tinggi!',
          message: 'Asupan Lemak Jenuh (${totalFat.toStringAsFixed(1)}g / 25g) telah melebihi batas harian. Batasi gorengan & santan.',
          type: 'nutrition_excess',
          iconType: 'warning',
          createdAt: DateTime.now(),
        );
        final id = await addNotification(notif);
        newlyCreatedNotif ??= NotificationModel(
          id: id,
          title: notif.title,
          message: notif.message,
          type: notif.type,
          iconType: notif.iconType,
          isRead: false,
          createdAt: notif.createdAt,
        );
      }
    }

    // 2. Cek Kalori
    if (totalCalories > maxCalories) {
      final existing = await db.query(
        tableNotifications,
        where: 'title LIKE ? AND created_at >= ?',
        whereArgs: ['%Kalori%', startOfDay],
      );
      if (existing.isEmpty) {
        final notif = NotificationModel(
          title: 'Peringatan Kalori Berlebih!',
          message: 'Total asupan kalori ($totalCalories kcal / 2000 kcal) telah melebihi target harian Anda.',
          type: 'nutrition_excess',
          iconType: 'warning',
          createdAt: DateTime.now(),
        );
        final id = await addNotification(notif);
        newlyCreatedNotif ??= NotificationModel(
          id: id,
          title: notif.title,
          message: notif.message,
          type: notif.type,
          iconType: notif.iconType,
          isRead: false,
          createdAt: notif.createdAt,
        );
      }
    }

    // 3. Cek Kolesterol
    if (totalCholesterol > maxCholesterol) {
      final existing = await db.query(
        tableNotifications,
        where: 'title LIKE ? AND created_at >= ?',
        whereArgs: ['%Kolesterol%', startOfDay],
      );
      if (existing.isEmpty) {
        final notif = NotificationModel(
          title: 'Peringatan Kolesterol Tinggi!',
          message: 'Estimasi kolesterol (${totalCholesterol.toStringAsFixed(0)}mg / 300mg) melebihi batas yang disarankan.',
          type: 'nutrition_excess',
          iconType: 'warning',
          createdAt: DateTime.now(),
        );
        final id = await addNotification(notif);
        newlyCreatedNotif ??= NotificationModel(
          id: id,
          title: notif.title,
          message: notif.message,
          type: notif.type,
          iconType: notif.iconType,
          isRead: false,
          createdAt: notif.createdAt,
        );
      }
    }

    // 4. Cek Karbohidrat
    if (totalCarbs > maxCarbs) {
      final existing = await db.query(
        tableNotifications,
        where: 'title LIKE ? AND created_at >= ?',
        whereArgs: ['%Karbohidrat%', startOfDay],
      );
      if (existing.isEmpty) {
        final notif = NotificationModel(
          title: 'Peringatan Karbohidrat Tinggi!',
          message: 'Asupan Karbohidrat (${totalCarbs.toStringAsFixed(1)}g / 300g) telah melebihi rekomendasi harian.',
          type: 'nutrition_excess',
          iconType: 'warning',
          createdAt: DateTime.now(),
        );
        final id = await addNotification(notif);
        newlyCreatedNotif ??= NotificationModel(
          id: id,
          title: notif.title,
          message: notif.message,
          type: notif.type,
          iconType: notif.iconType,
          isRead: false,
          createdAt: notif.createdAt,
        );
      }
    }

    // 5. Cek Protein Excess
    if (totalProtein > maxProtein + 40) {
      final existing = await db.query(
        tableNotifications,
        where: 'title LIKE ? AND created_at >= ?',
        whereArgs: ['%Protein%', startOfDay],
      );
      if (existing.isEmpty) {
        final notif = NotificationModel(
          title: 'Asupan Protein Sangat Tinggi',
          message: 'Protein (${totalProtein.toStringAsFixed(1)}g / 65g) telah jauh melampaui kebutuhan harian.',
          type: 'nutrition_excess',
          iconType: 'warning',
          createdAt: DateTime.now(),
        );
        final id = await addNotification(notif);
        newlyCreatedNotif ??= NotificationModel(
          id: id,
          title: notif.title,
          message: notif.message,
          type: notif.type,
          iconType: notif.iconType,
          isRead: false,
          createdAt: notif.createdAt,
        );
      }
    }

    return newlyCreatedNotif;
  }
}
