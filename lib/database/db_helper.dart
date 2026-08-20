import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../constants/app_date_formatter.dart';
import '../models/food_item_model.dart';
import '../models/food_log_model.dart';
import '../models/notification_model.dart';
import '../models/pantry_item_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

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
    await _ensureDataIntegrity(_database!);
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async => await _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
        await _seedDatabase(db);
      },
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  Future<void> _ensureDataIntegrity(Database db) async {
    try {
      final nonZeroChol = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableFoods WHERE cholesterol > 0'),
      ) ?? 0;
      final okezoneInFoods = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM $tableFoods WHERE image_path LIKE '%okezone%'"),
      ) ?? 0;

      if (nonZeroChol < 50 || okezoneInFoods > 0) {
        await _seedDatabase(db);
      }

      // Perbarui log makanan lama yang masih menggunakan URL gambar lama/okezone
      await db.rawUpdate('''
        UPDATE $tableFoodLogs 
        SET image_path = (
          SELECT $tableFoods.image_path 
          FROM $tableFoods 
          WHERE LOWER(TRIM($tableFoods.name)) = LOWER(TRIM($tableFoodLogs.food_name)) 
          LIMIT 1
        )
        WHERE image_path LIKE '%okezone%'
           OR food_name = 'Rujak Buah'
           OR food_name LIKE 'Dada Ayam%';
      ''');

      // Perbarui nama menu lama jika masih 'Dada Ayam Panggang & Salad'
      await db.rawUpdate('''
        UPDATE $tableFoodLogs 
        SET food_name = 'Dada Ayam Panggang',
            calories = 284,
            protein = 31.0,
            carbs = 0.0,
            fat = 15.0,
            cholesterol = 85.0
        WHERE food_name = 'Dada Ayam Panggang & Salad';
      ''');
    } catch (_) {}
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableUsers}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT
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
        cholesterol REAL NOT NULL DEFAULT 0,
        category TEXT NOT NULL,
        image_path TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableFoodLogs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        food_name TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        cholesterol REAL NOT NULL DEFAULT 0,
        image_path TEXT NOT NULL,
        time TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tablePantryItems(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
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
        user_id INTEGER NOT NULL,
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
      final jsonString = await rootBundle.loadString('assets/food_data.json');
      final foods = FoodItemModel.listFromJsonString(jsonString);

      // Bersihkan dan masukkan ulang katalog makanan terupdate
      await db.delete(tableFoods);

      final batch = db.batch();
      final seenNames = <String>{};
      for (final food in foods) {
        if (seenNames.add(food.name.trim().toLowerCase())) {
          batch.insert(tableFoods, food.toMap()..remove('id'));
        }
      }
      await batch.commit(noResult: true);

      // Sinkronisasi data kolesterol pada catatan makanan lama yang bernilai 0 / NULL
      await db.rawUpdate('''
        UPDATE $tableFoodLogs 
        SET cholesterol = (
          SELECT $tableFoods.cholesterol 
          FROM $tableFoods 
          WHERE LOWER(TRIM($tableFoods.name)) = LOWER(TRIM($tableFoodLogs.food_name)) 
          LIMIT 1
        )
        WHERE (cholesterol = 0 OR cholesterol IS NULL)
          AND EXISTS (
            SELECT 1 FROM $tableFoods 
            WHERE LOWER(TRIM($tableFoods.name)) = LOWER(TRIM($tableFoodLogs.food_name)) 
              AND $tableFoods.cholesterol > 0
          )
      ''');
    } catch (_) {}
  }

  /// Menyiapkan stok bahan awal untuk akun pengguna baru
  Future<void> seedInitialPantryForUser(int userId, {Database? db}) async {
    final dbInst = db ?? await database;
    final existing = await dbInst.query(tablePantryItems, where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (existing.isNotEmpty) return;

    final now = DateTime.now();
    final items = [
      PantryItemModel(userId: userId, name: 'Bayam Segar', quantity: 250, unit: 'g', storage: 'Kulkas', expiryDate: now.add(const Duration(days: 1)), imageUrl: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=500', createdAt: now.subtract(const Duration(days: 3))),
      PantryItemModel(userId: userId, name: 'Susu UHT', quantity: 1, unit: 'L', storage: 'Kulkas', expiryDate: now.add(const Duration(days: 3)), imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500', createdAt: now.subtract(const Duration(days: 5))),
      PantryItemModel(userId: userId, name: 'Brokoli', quantity: 500, unit: 'g', storage: 'Kulkas', expiryDate: now.add(const Duration(days: 4)), imageUrl: 'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?w=500', createdAt: now.subtract(const Duration(days: 2))),
      PantryItemModel(userId: userId, name: 'Tomat', quantity: 300, unit: 'g', storage: 'Kulkas', expiryDate: now.add(const Duration(days: 6)), imageUrl: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=500', createdAt: now.subtract(const Duration(days: 1))),
    ];
    for (var it in items) {
      await dbInst.insert(tablePantryItems, it.toMap()..remove('id'), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Menyiapkan data awal Food Tracker untuk akun pengguna baru
  Future<void> seedInitialFoodLogsForUser(int userId, {Database? db}) async {
    final dbInst = db ?? await database;
    final existing = await dbInst.query(tableFoodLogs, where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (existing.isNotEmpty) return;

    final todayStr = AppDateFormatter.formatToday();
    final logs = [
      FoodLogModel(userId: userId, foodName: 'Oatmeal Buah Segar', mealType: 'Sarapan', calories: 320, protein: 11.5, carbs: 54.0, fat: 5.5, cholesterol: 0.0, imagePath: 'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=500', time: '07:30', date: todayStr, note: 'Menu sarapan sehat kaya serat.'),
      FoodLogModel(userId: userId, foodName: 'Dada Ayam Panggang', mealType: 'Makan Siang', calories: 284, protein: 31.0, carbs: 0.0, fat: 15.0, cholesterol: 85.0, imagePath: 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=500', time: '12:30', date: todayStr, note: 'Tinggi protein untuk energi.'),
      FoodLogModel(userId: userId, foodName: 'Rujak Buah', mealType: 'Camilan', calories: 200, protein: 1.0, carbs: 24.0, fat: 11.0, cholesterol: 0.0, imagePath: 'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=500', time: '16:00', date: todayStr, note: 'Camilan buah segar kaya serat & vitamin C.'),
      FoodLogModel(userId: userId, foodName: 'Ikan Bandeng Bakar', mealType: 'Makan Malam', calories: 250, protein: 26.0, carbs: 2.0, fat: 15.0, cholesterol: 60.0, imagePath: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=500', time: '19:30', date: todayStr, note: 'Menu makan malam kaya omega-3.'),
    ];
    for (var l in logs) {
      await dbInst.insert(tableFoodLogs, l.toMap()..remove('id'), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _seedNotifications(Database db, {required int userId}) async {
    final now = DateTime.now();
    final notifs = [
      NotificationModel(userId: userId, title: 'Bayam Segar mendekati masa kedaluwarsa', message: 'Bayam Segar di kulkas sebaiknya diolah dalam 1 hari.', type: 'expiry_warning', iconType: 'warning', relatedPantryId: 1, createdAt: now.subtract(const Duration(minutes: 25))),
      NotificationModel(userId: userId, title: 'Tips Food Rescue', message: 'Gunakan bahan yang paling dekat tanggal kadaluwarsanya terlebih dahulu untuk mengurangi sampah makanan.', type: 'tips', iconType: 'lightbulb', createdAt: now.subtract(const Duration(hours: 3))),
      NotificationModel(userId: userId, title: 'Selamat Datang di FoodCura!', message: 'Mulai catat makanan harian dan pantau stok kulkas Anda untuk gaya hidup lebih sehat.', type: 'system', iconType: 'eco', isRead: false, createdAt: now.subtract(const Duration(hours: 12))),
    ];
    for (var n in notifs) {
      await db.insert(tableNotifications, n.toMap()..remove('id'), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // --- USER AUTH CRUD ---

  Future<int?> getActiveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyLoggedInUserId);
  }

  Future<bool> registerUser(UserModelSQL pengguna) async {
    final db = await database;
    try {
      final userMap = pengguna.toMap()..remove('id');
      userMap['email'] = pengguna.email.trim().toLowerCase();
      userMap['name'] = pengguna.name.trim();
      userMap['created_at'] = pengguna.createdAt ?? DateTime.now().toIso8601String();

      final id = await db.insert(AppConstants.tableUsers, userMap, conflictAlgorithm: ConflictAlgorithm.abort);
      if (id > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(AppConstants.keyLoggedInUserId, id);
        await seedInitialPantryForUser(id, db: db);
        await seedInitialFoodLogsForUser(id, db: db);
        await _seedNotifications(db, userId: id);
        await EcoPointsNotifier.instance.refresh();
        await NotificationNotifier.instance.refresh();
        PantryUpdateNotifier.instance.notifyPantryChanged();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<UserModelSQL?> loginUser(String email, String password) async {
    final db = await database;
    final results = await db.query(AppConstants.tableUsers, where: 'LOWER(TRIM(email)) = ? AND password = ?', whereArgs: [email.trim().toLowerCase(), password], limit: 1);
    if (results.isNotEmpty) {
      final user = UserModelSQL.fromMap(results.first);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.keyLoggedInUserId, user.id!);
      await EcoPointsNotifier.instance.refresh();
      await NotificationNotifier.instance.refresh();
      PantryUpdateNotifier.instance.notifyPantryChanged();
      return user;
    }
    return null;
  }

  Future<UserModelSQL?> getLoggedInUser() async {
    final userId = await getActiveUserId();
    if (userId == null) return null;
    final db = await database;
    final results = await db.query(AppConstants.tableUsers, where: 'id = ?', whereArgs: [userId], limit: 1);
    return results.isNotEmpty ? UserModelSQL.fromMap(results.first) : null;
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyLoggedInUserId);
    await EcoPointsNotifier.instance.refresh();
    await NotificationNotifier.instance.refresh();
    PantryUpdateNotifier.instance.notifyPantryChanged();
  }

  Future<bool> updateUser(UserModelSQL user) async {
    if (user.id == null) return false;
    final db = await database;
    final userMap = user.toMap();
    userMap['email'] = user.email.trim().toLowerCase();
    userMap['name'] = user.name.trim();

    final count = await db.update(AppConstants.tableUsers, userMap, where: 'id = ?', whereArgs: [user.id]);
    return count > 0;
  }

  Future<int> computeAndSaveStreak({int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return 1;

    final prefs = await SharedPreferences.getInstance();
    final streakKey = 'user_streak_$targetUserId';
    final savedStreak = prefs.getInt(streakKey) ?? 0;

    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT date FROM $tableFoodLogs WHERE user_id = ? ORDER BY date DESC', [targetUserId]);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final dateSet = <DateTime>{};
    for (final r in result) {
      final parsed = AppDateFormatter.parseDate(r['date'] as String?);
      if (parsed != null) dateSet.add(DateTime(parsed.year, parsed.month, parsed.day));
    }
    dateSet.add(today);

    final lastActiveDay = dateSet.isNotEmpty ? dateSet.first : today;
    int currentStreak;
    if (lastActiveDay == today) {
      currentStreak = savedStreak > 0 ? savedStreak : 1;
    } else if (lastActiveDay == yesterday) {
      currentStreak = savedStreak > 0 ? savedStreak + 1 : 2;
    } else {
      int logStreak = 0;
      DateTime checkDate = today;
      while (dateSet.contains(checkDate)) {
        logStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      currentStreak = logStreak > 0 ? logStreak : 1;
    }

    await prefs.setInt(streakKey, currentStreak);
    return currentStreak;
  }

  Future<bool> isEmailRegistered(String email) async {
    final db = await database;
    final res = await db.query(AppConstants.tableUsers, where: 'LOWER(TRIM(email)) = ?', whereArgs: [email.trim().toLowerCase()], limit: 1);
    return res.isNotEmpty;
  }

  Future<bool> changePassword({required int userId, required String oldPassword, required String newPassword}) async {
    final db = await database;
    final userResults = await db.query(AppConstants.tableUsers, where: 'id = ? AND password = ?', whereArgs: [userId, oldPassword], limit: 1);
    if (userResults.isEmpty) return false;

    final count = await db.update(AppConstants.tableUsers, {'password': newPassword}, where: 'id = ?', whereArgs: [userId]);
    return count > 0;
  }

  // --- FOOD CATALOG & LOGS CRUD ---

  Future<List<FoodItemModel>> getFoodCatalog() async {
    final db = await database;
    final nonZeroCholCheck = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableFoods WHERE cholesterol > 0'),
    ) ?? 0;

    if (nonZeroCholCheck < 50) {
      await _seedDatabase(db);
    }

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

  Future<List<FoodItemModel>> getRecentAddedFoods({int limit = 10, int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return [];

    final db = await database;
    final rawLogs = await db.query(tableFoodLogs, where: 'user_id = ?', whereArgs: [targetUserId], orderBy: 'id DESC', limit: limit * 2);
    final seen = <String>{};
    final uniqueItems = <FoodItemModel>[];

    for (var log in rawLogs) {
      final name = (log['food_name'] as String?)?.trim() ?? '';
      if (name.isEmpty || !seen.add(name.toLowerCase())) continue;

      final matches = await db.query(tableFoods, where: 'LOWER(TRIM(name)) = ?', whereArgs: [name.toLowerCase()], limit: 1);
      uniqueItems.add(
        matches.isNotEmpty
            ? FoodItemModel.fromMap(matches.first)
            : FoodItemModel(
                name: name,
                calories: (log['calories'] as num?)?.toInt() ?? 0,
                protein: (log['protein'] as num?)?.toDouble() ?? 0.0,
                carbs: (log['carbs'] as num?)?.toDouble() ?? 0.0,
                fat: (log['fat'] as num?)?.toDouble() ?? 0.0,
                cholesterol: ((log['cholesterol'] as num?) ?? 0.0).toDouble(),
                category: log['meal_type'] as String? ?? 'Camilan',
                imagePath: (log['image_path'] as String?)?.isNotEmpty == true ? log['image_path'] as String : 'assets/images/food/default_food.png',
              ),
      );
      if (uniqueItems.length >= limit) break;
    }
    return uniqueItems;
  }

  Future<List<FoodLogModel>> getFoodLogs({String? date, int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return [];

    final db = await database;
    final where = ['user_id = ?', if (date != null) 'date = ?'].join(' AND ');
    final args = [targetUserId, ?date];

    final results = await db.query(tableFoodLogs, where: where, whereArgs: args, orderBy: 'time ASC');
    return results.map((map) => FoodLogModel.fromMap(map)).toList();
  }

  Future<NotificationModel?> addFoodLog(FoodLogModel log) async {
    final db = await database;
    final targetUserId = log.userId ?? await getActiveUserId();
    if (targetUserId == null) return null;

    final logMap = log.copyWith(userId: targetUserId).toMap()..remove('id');
    await db.insert(tableFoodLogs, logMap, conflictAlgorithm: ConflictAlgorithm.replace);
    return await checkNutritionExcess(userId: targetUserId);
  }

  Future<int> updateFoodLog(FoodLogModel log) async {
    if (log.id == null) return 0;
    final db = await database;
    final targetUserId = log.userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final res = await db.update(tableFoodLogs, log.copyWith(userId: targetUserId).toMap(), where: 'id = ? AND user_id = ?', whereArgs: [log.id, targetUserId]);
    await checkNutritionExcess(userId: targetUserId);
    return res;
  }

  Future<int> deleteFoodLog(int id) async {
    final db = await database;
    final targetUserId = await getActiveUserId();
    if (targetUserId == null) return 0;
    return await db.delete(tableFoodLogs, where: 'id = ? AND user_id = ?', whereArgs: [id, targetUserId]);
  }

  // --- PANTRY CRUD ---

  Future<int> addPantryItem(PantryItemModel item) async {
    final db = await database;
    final targetUserId = item.userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final res = await db.insert(tablePantryItems, item.copyWith(userId: targetUserId).toMap()..remove('id'), conflictAlgorithm: ConflictAlgorithm.replace);
    PantryUpdateNotifier.instance.notifyPantryChanged();
    await checkExpiryAndCreateNotifications(userId: targetUserId);
    return res;
  }

  Future<List<PantryItemModel>> getPantryItems({String? filter, int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return [];

    final db = await database;
    final results = await db.query(
      tablePantryItems, 
      where: 'is_used = 0 AND user_id = ?', 
      whereArgs: [targetUserId], 
      orderBy: 'expiry_date ASC'
    );
    
    var items = results.map((map) => PantryItemModel.fromMap(map)).toList();

    if (filter != null && filter != 'Semua') {
      final f = filter.toLowerCase();
      if (f == 'urgent' || f == 'danger') {
        items = items.where((i) => i.expiryStatus == 'urgent' || i.expiryStatus == 'expired' || i.daysUntilExpiry <= 2).toList();
      } else if (f == 'segera' || f == 'warning') {
        items = items.where((i) => i.expiryStatus == 'segera' || (i.daysUntilExpiry > 2 && i.daysUntilExpiry <= 5)).toList();
      } else if (f == 'aman' || f == 'safe') {
        items = items.where((i) => i.expiryStatus == 'aman' || i.daysUntilExpiry > 5).toList();
      } else {
        items = items.where((i) => i.storage.toLowerCase() == f).toList();
      }
    }

    return items;
  }

  Future<List<PantryItemModel>> searchPantryItems(String query, {int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return [];

    final db = await database;
    final results = await db.query(tablePantryItems, where: 'is_used = 0 AND name LIKE ? AND user_id = ?', whereArgs: ['%$query%', targetUserId], orderBy: 'expiry_date ASC');
    return results.map((map) => PantryItemModel.fromMap(map)).toList();
  }

  Future<int> markPantryItemUsed(int id) async {
    final db = await database;
    final targetUserId = await getActiveUserId();
    if (targetUserId == null) return 0;

    final res = await db.update(tablePantryItems, {'is_used': 1}, where: 'id = ? AND user_id = ?', whereArgs: [id, targetUserId]);
    PantryUpdateNotifier.instance.notifyPantryChanged();
    return res;
  }

  Future<int> deletePantryItem(int id) async {
    final db = await database;
    final targetUserId = await getActiveUserId();
    if (targetUserId == null) return 0;

    final res = await db.delete(tablePantryItems, where: 'id = ? AND user_id = ?', whereArgs: [id, targetUserId]);
    PantryUpdateNotifier.instance.notifyPantryChanged();
    return res;
  }

  Future<int> updatePantryItem(PantryItemModel item) async {
    if (item.id == null) return 0;
    final db = await database;
    final targetUserId = item.userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final res = await db.update(tablePantryItems, item.copyWith(userId: targetUserId).toMap(), where: 'id = ? AND user_id = ?', whereArgs: [item.id, targetUserId]);
    PantryUpdateNotifier.instance.notifyPantryChanged();
    await checkExpiryAndCreateNotifications(userId: targetUserId);
    return res;
  }

  Future<Map<String, int>> getPantryStatusCounts({int? userId}) async {
    final items = await getPantryItems(userId: userId);
    int safe = 0, warning = 0, danger = 0, expired = 0;
    for (var item in items) {
      final days = item.daysUntilExpiry;
      if (days < 0) {
        expired++;
      } else if (days <= 2) {
        danger++;
      } else if (days <= 5) {
        warning++;
      } else {
        safe++;
      }
    }
    return {
      'safe': safe,
      'warning': warning,
      'danger': danger,
      'expired': expired,
      'urgent': danger + expired,
      'segera': warning,
      'aman': safe,
      'total': items.length,
    };
  }

  // --- NOTIFICATIONS CRUD ---

  Future<int> addNotification(NotificationModel notif) async {
    final db = await database;
    final targetUserId = notif.userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final res = await db.insert(tableNotifications, notif.copyWith(userId: targetUserId).toMap()..remove('id'), conflictAlgorithm: ConflictAlgorithm.replace);
    await NotificationNotifier.instance.refresh();
    return res;
  }

  Future<List<NotificationModel>> getNotifications({String? filter, int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return [];

    final db = await database;
    String? typeClause;
    if (filter != null && filter != 'Semua') {
      if (filter == 'Kadaluwarsa') {
        typeClause = "type = 'expiry_warning'";
      } else if (filter == 'Pengingat Makan') {
        typeClause = "type = 'meal_reminder'";
      } else if (filter == 'Alert Gizi') {
        typeClause = "type = 'nutrition_excess'";
      } else if (filter == 'Sistem') {
        typeClause = "type IN ('system', 'tips')";
      }
    }

    final where = ['user_id = ?', ?typeClause].join(' AND ');
    final results = await db.query(tableNotifications, where: where, whereArgs: [targetUserId], orderBy: 'created_at DESC');
    return results.map((map) => NotificationModel.fromMap(map)).toList();
  }

  Future<int> markNotificationRead(int id) async {
    final db = await database;
    final targetUserId = await getActiveUserId();
    if (targetUserId == null) return 0;

    final res = await db.update(tableNotifications, {'is_read': 1}, where: 'id = ? AND user_id = ?', whereArgs: [id, targetUserId]);
    await NotificationNotifier.instance.refresh();
    return res;
  }

  Future<int> markAllNotificationsRead({int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final db = await database;
    final res = await db.update(tableNotifications, {'is_read': 1}, where: 'is_read = 0 AND user_id = ?', whereArgs: [targetUserId]);
    await NotificationNotifier.instance.refresh();
    return res;
  }

  Future<int> getUnreadNotificationCount({int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableNotifications WHERE is_read = 0 AND user_id = ?', [targetUserId]);
    return (result.first['count'] as int?) ?? 0;
  }

  // --- AUTOMATIC EXPIRY, MEAL & NUTRITION CHECKS ---

  Future<void> checkExpiryAndCreateNotifications({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(AppConstants.keyNotifExpiryAlert) ?? true)) return;

    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return;

    final db = await database;
    final items = await getPantryItems(userId: targetUserId);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

    for (var item in items) {
      final days = item.daysUntilExpiry;
      if (days <= 5) {
        final title = days <= 0 ? '${item.name} sudah kadaluwarsa!' : days <= 2 ? '${item.name} hampir kadaluwarsa' : '${item.name} perlu segera digunakan';
        final message = days <= 0 ? '${item.name} di ${item.storage.toLowerCase()} sudah melewati tanggal kadaluwarsa.' : '${item.name} di ${item.storage.toLowerCase()} akan kadaluwarsa dalam $days hari.';

        final existing = await db.query(tableNotifications, where: 'related_pantry_id = ? AND title = ? AND created_at >= ? AND user_id = ?', whereArgs: [item.id, title, todayStart, targetUserId]);
        if (existing.isEmpty) {
          final id = await addNotification(NotificationModel(userId: targetUserId, title: title, message: message, type: 'expiry_warning', iconType: 'warning', relatedPantryId: item.id, createdAt: DateTime.now()));
          try {
            await NotificationService.instance.showSystemNotification(id: id, title: title, body: message);
          } catch (_) {}
        }
      }
    }
  }

  static const List<Map<String, String>> _mealConfigs = [
    {'type': 'Sarapan', 'enabledKey': AppConstants.keyNotifBreakfastEnabled, 'timeKey': AppConstants.keyNotifBreakfastTime, 'defaultTime': '07:30', 'title': 'Saatnya sarapan', 'message': 'Jangan lupa catat sarapanmu hari ini untuk tracking kalori.'},
    {'type': 'Makan Siang', 'enabledKey': AppConstants.keyNotifLunchEnabled, 'timeKey': AppConstants.keyNotifLunchTime, 'defaultTime': '12:30', 'title': 'Saatnya makan siang', 'message': 'Jangan lupa catat makan siangmu hari ini untuk tracking kalori.'},
    {'type': 'Makan Malam', 'enabledKey': AppConstants.keyNotifDinnerEnabled, 'timeKey': AppConstants.keyNotifDinnerTime, 'defaultTime': '19:00', 'title': 'Saatnya makan malam', 'message': 'Jangan lupa catat makan malammu hari ini untuk tracking kalori.'},
  ];

  Future<void> checkMealRemindersAndCreateNotifications({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(AppConstants.keyNotifDailyMealLog) ?? true)) return;

    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return;

    final db = await database;
    final now = DateTime.now();
    final todayStr = AppDateFormatter.formatToday();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    for (final meal in _mealConfigs) {
      if (!(prefs.getBool(meal['enabledKey']!) ?? true)) continue;

      final timeStr = prefs.getString(meal['timeKey']!) ?? meal['defaultTime']!;
      final parts = timeStr.split(':');
      final targetHour = int.tryParse(parts[0]) ?? 12;
      final targetMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      final scheduledTime = DateTime(now.year, now.month, now.day, targetHour, targetMinute);
      if (now.isBefore(scheduledTime)) continue;

      final logs = await db.query(tableFoodLogs, where: 'date = ? AND meal_type = ? AND user_id = ?', whereArgs: [todayStr, meal['type']!, targetUserId]);
      if (logs.isEmpty) {
        final title = meal['title']!;
        final existing = await db.query(tableNotifications, where: 'type = ? AND title = ? AND created_at >= ? AND user_id = ?', whereArgs: ['meal_reminder', title, startOfDay, targetUserId]);
        if (existing.isEmpty) {
          final notif = NotificationModel(userId: targetUserId, title: title, message: meal['message']!, type: 'meal_reminder', iconType: 'restaurant', createdAt: now);
          final id = await addNotification(notif);
          try {
            await NotificationService.instance.showSystemNotification(id: id, title: notif.title, body: notif.message);
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _checkAndNotify(Database db, String keyword, String startOfDay, String title, String message, NotificationModel? Function() getContainer, void Function(NotificationModel) setContainer, {required int userId}) async {
    final existing = await db.query(tableNotifications, where: 'title LIKE ? AND created_at >= ? AND user_id = ?', whereArgs: ['%$keyword%', startOfDay, userId]);
    if (existing.isEmpty) {
      final notif = NotificationModel(userId: userId, title: title, message: message, type: 'nutrition_excess', iconType: 'warning', createdAt: DateTime.now());
      final id = await addNotification(notif);
      try {
        await NotificationService.instance.showSystemNotification(id: id, title: notif.title, body: notif.message);
      } catch (_) {}
      if (getContainer() == null) {
        setContainer(NotificationModel(id: id, userId: userId, title: notif.title, message: notif.message, type: notif.type, iconType: notif.iconType, isRead: false, createdAt: notif.createdAt));
      }
    }
  }

  Future<NotificationModel?> checkNutritionExcess({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(AppConstants.keyNotifNutritionExcess) ?? true)) return null;

    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return null;

    final db = await database;
    final todayStr = AppDateFormatter.formatToday();
    final logs = await db.query(tableFoodLogs, where: 'date = ? AND user_id = ?', whereArgs: [todayStr, targetUserId]);
    if (logs.isEmpty) return null;

    int totalCalories = 0;
    double totalProtein = 0, totalCarbs = 0, totalFat = 0, totalCholesterol = 0;
    for (var log in logs) {
      totalCalories += (log['calories'] as num).toInt();
      totalProtein += (log['protein'] as num).toDouble();
      totalCarbs += (log['carbs'] as num).toDouble();
      totalFat += (log['fat'] as num).toDouble();
      totalCholesterol += ((log['cholesterol'] as num?) ?? 0.0).toDouble();
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    NotificationModel? result;
    void setResult(NotificationModel n) => result ??= n;

    final rules = [
      if (totalFat >= 67.0) ('Lemak', 'Peringatan Lemak Tinggi!', 'Asupan Lemak (${totalFat.toStringAsFixed(1)}g / 67g) telah melebihi batas anjuran harian Kemenkes (67g). Batasi gorengan & makanan berminyak.'),
      if (totalCalories > 2000) ('Kalori', 'Peringatan Kalori Berlebih!', 'Total asupan kalori ($totalCalories kcal / 2000 kcal) telah melebihi target harian Anda.'),
      if (totalCholesterol > 300.0) ('Kolesterol', 'Peringatan Kolesterol Tinggi!', 'Asupan kolesterol (${totalCholesterol.toStringAsFixed(0)}mg / 300mg) telah melebihi batas anjuran harian Kemenkes (300mg). Batasi makanan hewani tinggi lemak dan jeroan.'),
      if (totalCarbs > 300.0) ('Karbohidrat', 'Peringatan Karbohidrat Tinggi!', 'Asupan Karbohidrat (${totalCarbs.toStringAsFixed(1)}g / 300g) telah melebihi rekomendasi harian.'),
      if (totalProtein > 65.0) ('Protein', 'Peringatan Protein Tinggi!', 'Asupan Protein (${totalProtein.toStringAsFixed(1)}g / 65g) telah melebihi rekomendasi harian.'),
    ];

    for (final rule in rules) {
      await _checkAndNotify(db, rule.$1, startOfDay, rule.$2, rule.$3, () => result, setResult, userId: targetUserId);
    }
    return result;
  }
}

class NotificationNotifier extends ValueNotifier<int> {
  static final NotificationNotifier instance = NotificationNotifier._();
  NotificationNotifier._() : super(0);

  Future<void> refresh() async {
    final count = await DBHelper().getUnreadNotificationCount();
    value = count;
  }
}

class EcoPointsNotifier extends ValueNotifier<int> {
  static final EcoPointsNotifier instance = EcoPointsNotifier._();
  EcoPointsNotifier._() : super(0);

  static const String _baseKey = 'user_eco_points';

  Future<String> _getKey() async {
    final userId = await DBHelper().getActiveUserId();
    return userId != null ? '${_baseKey}_$userId' : _baseKey;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getKey();
    value = prefs.getInt(key) ?? 0;
  }

  Future<void> addPoints(int points) async {
    if (points <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getKey();
    final current = prefs.getInt(key) ?? 0;
    final updated = current + points;
    await prefs.setInt(key, updated);
    value = updated;
  }

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getKey();
    value = prefs.getInt(key) ?? 0;
  }
}

/// Notifier global untuk sinkronisasi instan state inventaris dapur (Pantry & Expiry)
class PantryUpdateNotifier extends ValueNotifier<int> {
  static final PantryUpdateNotifier instance = PantryUpdateNotifier._();
  PantryUpdateNotifier._() : super(0);

  void notifyPantryChanged() {
    value++;
  }
}
