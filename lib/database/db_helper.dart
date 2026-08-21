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

      // Pastikan pengguna lama memiliki nilai created_at yang valid
      await db.rawUpdate('''
        UPDATE ${AppConstants.tableUsers}
        SET created_at = ?
        WHERE created_at IS NULL OR TRIM(created_at) = '';
      ''', [DateTime.now().toIso8601String()]);
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

  /// Mengambil semua user terdaftar (sesuai kurikulum Local Storage II Slide Hal 12)
  Future<List<UserModelSQL>> getAllUsers() async {
    final db = await database;
    final results = await db.query(AppConstants.tableUsers);
    return results.map((map) => UserModelSQL.fromMap(map)).toList();
  }

  /// Menghapus user berdasarkan id (sesuai kurikulum Local Storage II Slide Hal 12)
  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete(AppConstants.tableUsers, where: 'id = ?', whereArgs: [id]);
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

  Future<List<FoodItemModel>> searchFoodCatalog(String query, {int? limit}) async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT * FROM $tableFoods WHERE (name LIKE ? OR category LIKE ?) GROUP BY LOWER(TRIM(name))'
      '${limit != null ? " LIMIT $limit" : ""}',
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

  /// Memasukkan data log makanan baru secara murni (DAO)
  Future<int> insertFoodLog(FoodLogModel log) async {
    final db = await database;
    final targetUserId = log.userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    // Hapus 'id' dari map agar mesin AUTOINCREMENT SQLite menghasilkan ID unik otomatis.
    final logMap = log.copyWith(userId: targetUserId).toMap()..remove('id');
    return await db.insert(tableFoodLogs, logMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateFoodLog(FoodLogModel log) async {
    if (log.id == null) return 0;
    final db = await database;
    final targetUserId = log.userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    return await db.update(tableFoodLogs, log.copyWith(userId: targetUserId).toMap(), where: 'id = ? AND user_id = ?', whereArgs: [log.id, targetUserId]);
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
    // Naikkan counter value untuk memicu sinyal pembaruan serentak di Dashboard, Pantry, dan Navbar.
    value++;
  }
}
