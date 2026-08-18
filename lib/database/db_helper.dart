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
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: 8,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 8) {
          try {
            await db.execute(
              'ALTER TABLE ${AppConstants.tableUsers} ADD COLUMN created_at TEXT',
            );
          } catch (_) {}
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
      final jsonString = await rootBundle.loadString('assets/food_data.json');
      final foods = FoodItemModel.listFromJsonString(jsonString);
      final batch = db.batch();
      final seenNames = <String>{};
      for (final food in foods) {
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
      await batch.commit(noResult: true);
    } catch (_) {
      // Fallback
    }

    // Seed pantry items (bahan makanan segar di kulkas)
    await _seedPantryItems(db);
    // Seed initial notifications (tips & panduan awal)
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
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDcPiJEMCmQ3HRVbcyFp8QuNZfB2Vr7ZzCNSPq8LeWXK6gaKqr7yh_H9Rja8wkM4uPeESMs8zKA4_15t2Mocrk9z2SqiBk92cWAjaLf1Y0HhH-H-XB8cVIrAi0KAZdrtyzqunKTQ32fassRQ11luY8H-OFvzFvbNA5crL_QOu60aT4T53w0B1ZiqoGiuyQUMdug7vSyI1uUvJNXFZxCFWnpCYzkePmDwvoMNiFn6yIYkwDYnolDQWUSXg',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      PantryItemModel(
        name: 'Susu UHT',
        quantity: 1,
        unit: 'L',
        storage: 'Kulkas',
        expiryDate: now.add(const Duration(days: 3)),
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuB32I-05BQEXVC37e4PNZcRpnBz8zeWtMIbFi_6T-9fgRmL2JW5p07288dFHdeXP65Og9U3g-thmRk42z55OafxmFOXx6u1oy6ooEmUACs60yzeNcgX21STQTXL44m3h68f5WWlkFo-YpMllThjowX17wBNZT6KMYTbWX0PEhu8uRvjms6e_GXJoAKTHAKwvBRY4dTdXskcfwYg7ThKcRXQ9mdIih9DgRvk-WbiqVN3cW771b0EYkFETg',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      PantryItemModel(
        name: 'Brokoli',
        quantity: 500,
        unit: 'g',
        storage: 'Kulkas',
        expiryDate: now.add(const Duration(days: 4)),
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuATlUqaIOqfCvcDojnBb5N9g8SQPgt9tAYN9PfDN5iEKn4N19cyAYqqBn_g4aNIOZto8yKnnZELsbE05Ih0_6NSMsEEZMkOu0bL3GGpoAnEEZyuC8X5_US5aXvu8-TbPLhpfr3bJAXygrBlVQkXF2JXcEEGFKI7sFphrlGFsuzRtCxxKQpbtb3c7RzWS2GwgVPvgX8CVNsoUVLJV8mUjBZPN1QEAcDW-eCGdn1RwVqxJHRUXV8zv6n7uA',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      PantryItemModel(
        name: 'Tomat',
        quantity: 300,
        unit: 'g',
        storage: 'Kulkas',
        expiryDate: now.add(const Duration(days: 6)),
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDXYXmeja6TqYF85erWaJQ-veCjYKcUY3kORbMh-oiRyPzZHGSEp6J5WJMP202AFMgSKIF7ufJtj-92476bUvNcaH29HZshBc79iG7Wbus2j56IK_urvsuCdKzJIXK-nY9dVqiwjY74OF6PohVQJuLqtCR2KbAtX_3F_5IUf0geW2nJoSCCkTpgaQE5L0CWp7M_HXneq6Z4jITPSv2RAeY2D-a5jnE2bhy0aMoV81wLNln7wMla8N5OPQ',
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
        title: 'Bayam Segar mendekati masa kedaluwarsa',
        message: 'Bayam Segar di kulkas sebaiknya diolah dalam 1 hari.',
        type: 'expiry_warning',
        iconType: 'warning',
        relatedPantryId: 1,
        createdAt: now.subtract(const Duration(minutes: 25)),
      ),
      NotificationModel(
        title: 'Tips Food Rescue',
        message:
            'Gunakan bahan yang paling dekat tanggal kadaluwarsanya terlebih dahulu untuk mengurangi sampah makanan.',
        type: 'tips',
        iconType: 'lightbulb',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      NotificationModel(
        title: 'Selamat Datang di FoodCura!',
        message:
            'Mulai catat makanan harian dan pantau stok kulkas Anda untuk gaya hidup lebih sehat.',
        type: 'system',
        iconType: 'eco',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 12)),
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
      final userMap = pengguna.toMap()..remove('id');
      userMap['email'] = pengguna.email.trim().toLowerCase();
      userMap['name'] = pengguna.name.trim();
      userMap['created_at'] =
          pengguna.createdAt ?? DateTime.now().toIso8601String();

      final id = await db.insert(
        AppConstants.tableUsers,
        userMap,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      if (id > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(AppConstants.keyLoggedInUserId, id);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<UserModelSQL?> loginUser(String email, String password) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();
    final results = await db.query(
      AppConstants.tableUsers,
      where: 'LOWER(TRIM(email)) = ? AND password = ?',
      whereArgs: [cleanEmail, password],
    );

    if (results.isNotEmpty) {
      final user = UserModelSQL.fromMap(results.first);
      final prefs = await SharedPreferences.getInstance();
      if (user.id != null) {
        await prefs.setInt(AppConstants.keyLoggedInUserId, user.id!);
      }
      return user;
    }
    return null;
  }

  /// Ambil data user yang sedang login berdasarkan userId di SharedPreferences
  Future<UserModelSQL?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(AppConstants.keyLoggedInUserId);
    final db = await database;

    if (userId != null && userId > 0) {
      final results = await db.query(
        AppConstants.tableUsers,
        where: 'id = ?',
        whereArgs: [userId],
      );
      if (results.isNotEmpty) {
        return UserModelSQL.fromMap(results.first);
      }
    }

    // Fallback: Jika ID belum tersimpan atau tidak cocok, ambil user terbaru yang ada di database
    final fallbackUsers = await db.query(
      AppConstants.tableUsers,
      orderBy: 'id DESC',
      limit: 1,
    );
    if (fallbackUsers.isNotEmpty) {
      final fallback = UserModelSQL.fromMap(fallbackUsers.first);
      if (fallback.id != null) {
        await prefs.setInt(AppConstants.keyLoggedInUserId, fallback.id!);
      }
      return fallback;
    }

    return null;
  }

  /// Update data pengguna (nama, email, password)
  Future<bool> updateUser(UserModelSQL user) async {
    if (user.id == null) return false;
    final db = await database;
    try {
      final count = await db.update(
        AppConstants.tableUsers,
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return count > 0;
    } catch (_) {
      return false;
    }
  }

  /// Algoritma Streak: hitung berapa hari berturut-turut user aktif / login / membuat food log.
  /// Disimpan di SharedPreferences [AppConstants.keyStreakCount] dan
  /// [AppConstants.keyStreakLastDate].
  Future<int> computeAndSaveStreak() async {
    final db = await database;
    final prefs = await SharedPreferences.getInstance();

    final loggedInUser = await getLoggedInUser();
    if (loggedInUser == null) {
      await prefs.setInt(AppConstants.keyStreakCount, 0);
      await prefs.setString(AppConstants.keyStreakLastDate, '');
      return 0;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final todayStr = AppDateFormatter.formatToday(now);

    final savedLastDateStr =
        prefs.getString(AppConstants.keyStreakLastDate) ?? '';
    final savedStreak = prefs.getInt(AppConstants.keyStreakCount) ?? 0;
    final parsedLastDate = AppDateFormatter.parseDate(savedLastDateStr);
    final lastActiveDay = parsedLastDate != null
        ? DateTime(parsedLastDate.year, parsedLastDate.month, parsedLastDate.day)
        : null;

    // Ambil semua tanggal unik yang ada food log
    final result = await db.rawQuery(
      'SELECT DISTINCT date FROM $tableFoodLogs',
    );

    final dateSet = <DateTime>{};
    for (final r in result) {
      final dateStr = r['date'] as String?;
      final parsed = AppDateFormatter.parseDate(dateStr);
      if (parsed != null) {
        dateSet.add(DateTime(parsed.year, parsed.month, parsed.day));
      }
    }

    // Hari ini aktif karena user sedang login/membuka aplikasi
    dateSet.add(today);

    int currentStreak;

    if (lastActiveDay == today) {
      // User sudah membuka app/login hari ini, pertahankan streak saat ini (minimal 1)
      currentStreak = savedStreak > 0 ? savedStreak : 1;
    } else if (lastActiveDay == yesterday) {
      // Kemarin aktif dan hari ini login/aktif kembali -> streak bertambah 1!
      currentStreak = savedStreak > 0 ? savedStreak + 1 : 2;
    } else {
      // Jika baru pertama kali login, atau sudah jeda lebih dari 1 hari:
      // Hitung apakah ada food log beruntun ke belakang dimulai dari hari ini
      int logStreak = 0;
      DateTime checkDate = today;
      while (dateSet.contains(checkDate)) {
        logStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      // Minimal 1 karena user sudah login dan aktif hari ini
      currentStreak = logStreak > 0 ? logStreak : 1;
    }

    await prefs.setInt(AppConstants.keyStreakCount, currentStreak);
    await prefs.setString(AppConstants.keyStreakLastDate, todayStr);
    return currentStreak;
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

  // --- FOOD CATALOG CRUD ---
  Future<List<FoodItemModel>> getFoodCatalog() async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT * FROM $tableFoods GROUP BY LOWER(TRIM(name))',
    );
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
    final results = await db.query(tableFoodLogs, orderBy: 'id DESC');

    final seenNames = <String>{};
    final List<FoodItemModel> recentFoods = [];

    for (var map in results) {
      final log = FoodLogModel.fromMap(map);
      final key = log.foodName.trim().toLowerCase();
      if (!seenNames.contains(key)) {
        seenNames.add(key);
        recentFoods.add(
          FoodItemModel(
            name: log.foodName,
            calories: log.calories,
            protein: log.protein,
            carbs: log.carbs,
            fat: log.fat,
            category: log.mealType,
            imagePath: log.imagePath,
          ),
        );
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
    final results = await db.query(
      tableFoodLogs,
      where: 'date = ?',
      whereArgs: [targetDate],
      orderBy: 'id DESC',
    );
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
    return await db.delete(tableFoodLogs, where: 'id = ?', whereArgs: [id]);
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
          items = items
              .where(
                (i) =>
                    i.expiryStatus == 'urgent' || i.expiryStatus == 'expired',
              )
              .toList();
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

  Future<int> getUsedPantryItemsCount() async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tablePantryItems WHERE is_used = 1',
    );
    return Sqflite.firstIntValue(results) ?? 0;
  }

  Future<int> deletePantryItem(int id) async {
    final db = await database;
    return await db.delete(tablePantryItems, where: 'id = ?', whereArgs: [id]);
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
    final res = await db.insert(
      tableNotifications,
      notif.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    NotificationNotifier.instance.refresh();
    return res;
  }

  Future<List<NotificationModel>> getNotifications({String? filter}) async {
    // Auto-check expiry, nutrition excess & meal reminders before returning notifications
    await checkExpiryAndCreateNotifications();
    await checkNutritionExcess();
    await checkMealRemindersAndCreateNotifications();

    final db = await database;
    String? where;
    List<Object?>? whereArgs;

    if (filter == 'unread') {
      where = 'is_read = 0';
    } else if (filter == 'expiry') {
      where = 'type = ?';
      whereArgs = ['expiry_warning'];
    } else if (filter == 'foodcura') {
      where = 'type IN (?, ?, ?, ?)';
      whereArgs = ['nutrition_excess', 'meal_reminder', 'tips', 'system'];
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
    final res = await db.update(
      tableNotifications,
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    NotificationNotifier.instance.refresh();
    return res;
  }

  Future<int> markAllNotificationsRead() async {
    final db = await database;
    final res = await db.update(tableNotifications, {
      'is_read': 1,
    }, where: 'is_read = 0');
    NotificationNotifier.instance.refresh();
    return res;
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
    final prefs = await SharedPreferences.getInstance();
    final isExpiryAlertEnabled =
        prefs.getBool(AppConstants.keyNotifExpiryAlert) ?? true;
    if (!isExpiryAlertEnabled) return;

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
            message =
                '${item.name} di ${item.storage.toLowerCase()} sudah melewati tanggal kadaluwarsa.';
          } else if (days <= 2) {
            title = '${item.name} hampir kadaluwarsa';
            message =
                '${item.name} di ${item.storage.toLowerCase()} akan kadaluwarsa dalam $days hari.';
          } else {
            title = '${item.name} perlu segera digunakan';
            message =
                '${item.name} di ${item.storage.toLowerCase()} akan kadaluwarsa dalam $days hari.';
          }

          final id = await addNotification(
            NotificationModel(
              title: title,
              message: message,
              type: 'expiry_warning',
              iconType: 'warning',
              relatedPantryId: item.id,
              createdAt: DateTime.now(),
            ),
          );

          try {
            await NotificationService.instance.showSystemNotification(
              id: id,
              title: title,
              body: message,
            );
          } catch (e) {
            debugPrint('Error triggering system notification: $e');
          }
        }
      }
    }
  }

  /// Cek waktu makan harian (Sarapan, Makan Siang, Makan Malam).
  /// Jika sudah masuk jadwalnya dan user belum mencatat makanan untuk waktu makan tersebut,
  /// buat notifikasi pengingat secara otomatis.
  Future<void> checkMealRemindersAndCreateNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final isDailyMealLogEnabled =
        prefs.getBool(AppConstants.keyNotifDailyMealLog) ?? true;
    if (!isDailyMealLogEnabled) return;

    final db = await database;
    final now = DateTime.now();
    final todayStr = AppDateFormatter.formatToday();
    final startOfDay =
        DateTime(now.year, now.month, now.day).toIso8601String();

    final mealConfigs = [
      {
        'type': 'Sarapan',
        'enabledKey': AppConstants.keyNotifBreakfastEnabled,
        'timeKey': AppConstants.keyNotifBreakfastTime,
        'defaultTime': '07:30',
        'title': 'Saatnya sarapan',
        'message':
            'Jangan lupa catat sarapanmu hari ini untuk tracking kalori.',
      },
      {
        'type': 'Makan Siang',
        'enabledKey': AppConstants.keyNotifLunchEnabled,
        'timeKey': AppConstants.keyNotifLunchTime,
        'defaultTime': '12:30',
        'title': 'Saatnya makan siang',
        'message':
            'Jangan lupa catat makan siangmu hari ini untuk tracking kalori.',
      },
      {
        'type': 'Makan Malam',
        'enabledKey': AppConstants.keyNotifDinnerEnabled,
        'timeKey': AppConstants.keyNotifDinnerTime,
        'defaultTime': '19:00',
        'title': 'Saatnya makan malam',
        'message':
            'Jangan lupa catat makan malammu hari ini untuk tracking kalori.',
      },
    ];

    for (final meal in mealConfigs) {
      final isEnabled = prefs.getBool(meal['enabledKey'] as String) ?? true;
      if (!isEnabled) continue;

      final timeStr = prefs.getString(meal['timeKey'] as String) ??
          (meal['defaultTime'] as String);
      final parts = timeStr.split(':');
      final targetHour = int.tryParse(parts[0]) ?? 12;
      final targetMinute =
          parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      // Cek apakah waktu sekarang sudah mencapai atau melewati jadwal makan hari ini
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        targetHour,
        targetMinute,
      );
      if (now.isBefore(scheduledTime)) {
        continue;
      }

      // Cek apakah user sudah mencatat makanan untuk mealType ini hari ini
      final mealType = meal['type'] as String;
      final logs = await db.query(
        tableFoodLogs,
        where: 'date = ? AND meal_type = ?',
        whereArgs: [todayStr, mealType],
      );

      // Jika belum dicatat, cek apakah notifikasi pengingat sudah dibuat hari ini
      if (logs.isEmpty) {
        final title = meal['title'] as String;
        final existing = await db.query(
          tableNotifications,
          where: 'type = ? AND title = ? AND created_at >= ?',
          whereArgs: ['meal_reminder', title, startOfDay],
        );

        if (existing.isEmpty) {
          final notif = NotificationModel(
            title: title,
            message: meal['message'] as String,
            type: 'meal_reminder',
            iconType: 'restaurant',
            createdAt: now,
          );

          final id = await addNotification(notif);
          try {
            await NotificationService.instance.showSystemNotification(
              id: id,
              title: notif.title,
              body: notif.message,
            );
          } catch (e) {
            debugPrint('Error triggering meal reminder notification: $e');
          }
        }
      }
    }
  }

  /// Helper: cek apakah notif dengan [keyword] sudah ada hari ini,
  /// jika belum, buat notif baru dan simpan hasilnya ke [container].
  Future<void> _checkAndNotify(
    Database db,
    String keyword,
    String startOfDay,
    String title,
    String message,
    NotificationModel? Function() getContainer,
    void Function(NotificationModel) setContainer,
  ) async {
    final existing = await db.query(
      tableNotifications,
      where: 'title LIKE ? AND created_at >= ?',
      whereArgs: ['%$keyword%', startOfDay],
    );
    if (existing.isEmpty) {
      final notif = NotificationModel(
        title: title,
        message: message,
        type: 'nutrition_excess',
        iconType: 'warning',
        createdAt: DateTime.now(),
      );
      final id = await addNotification(notif);
      try {
        await NotificationService.instance.showSystemNotification(
          id: id,
          title: notif.title,
          body: notif.message,
        );
      } catch (e) {
        debugPrint('Error triggering system notification: $e');
      }

      if (getContainer() == null) {
        setContainer(
          NotificationModel(
            id: id,
            title: notif.title,
            message: notif.message,
            type: notif.type,
            iconType: notif.iconType,
            isRead: false,
            createdAt: notif.createdAt,
          ),
        );
      }
    }
  }

  /// Cek nutrisi harian, jika kelebihan buat notifikasi per-nutrisi & simpan ke database
  Future<NotificationModel?> checkNutritionExcess() async {
    final prefs = await SharedPreferences.getInstance();
    final isNutritionAlertEnabled =
        prefs.getBool(AppConstants.keyNotifNutritionExcess) ?? true;
    if (!isNutritionAlertEnabled) return null;

    final db = await database;
    final todayStr = AppDateFormatter.formatToday();

    final logs = await db.query(
      tableFoodLogs,
      where: 'date = ?',
      whereArgs: [todayStr],
    );
    if (logs.isEmpty) return null;

    int totalCalories = 0;
    double totalProtein = 0, totalCarbs = 0, totalFat = 0;
    for (var log in logs) {
      totalCalories += (log['calories'] as num).toInt();
      totalProtein += (log['protein'] as num).toDouble();
      totalCarbs += (log['carbs'] as num).toDouble();
      totalFat += (log['fat'] as num).toDouble();
    }

    double totalCholesterol = logs.isEmpty
        ? 0.0
        : (totalFat * 4.5 + totalProtein * 3.5);

    final startOfDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ).toIso8601String();

    NotificationModel? result;
    void setResult(NotificationModel n) => result ??= n;

    if (totalFat >= 67.0) {
      await _checkAndNotify(
        db,
        'Lemak',
        startOfDay,
        'Peringatan Lemak Tinggi!',
        'Asupan Lemak (${totalFat.toStringAsFixed(1)}g / 67g) telah melebihi batas anjuran harian Kemenkes (67g). Batasi gorengan & makanan berminyak.',
        () => result,
        setResult,
      );
    }
    if (totalCalories > 2000) {
      await _checkAndNotify(
        db,
        'Kalori',
        startOfDay,
        'Peringatan Kalori Berlebih!',
        'Total asupan kalori ($totalCalories kcal / 2000 kcal) telah melebihi target harian Anda.',
        () => result,
        setResult,
      );
    }
    if (totalCholesterol > 300.0) {
      await _checkAndNotify(
        db,
        'Kolesterol',
        startOfDay,
        'Peringatan Kolesterol Tinggi!',
        'Estimasi kolesterol (${totalCholesterol.toStringAsFixed(0)}mg / 300mg) melebihi batas yang disarankan.',
        () => result,
        setResult,
      );
    }
    if (totalCarbs > 300.0) {
      await _checkAndNotify(
        db,
        'Karbohidrat',
        startOfDay,
        'Peringatan Karbohidrat Tinggi!',
        'Asupan Karbohidrat (${totalCarbs.toStringAsFixed(1)}g / 300g) telah melebihi rekomendasi harian.',
        () => result,
        setResult,
      );
    }
    if (totalProtein > 65.0) {
      await _checkAndNotify(
        db,
        'Protein',
        startOfDay,
        'Peringatan Protein Tinggi!',
        'Asupan Protein (${totalProtein.toStringAsFixed(1)}g / 65g) telah melebihi rekomendasi harian.',
        () => result,
        setResult,
      );
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

  static const String _keyEcoPoints = 'user_eco_points';
  // Expose key so other classes can read the pref directly if needed
  static const String keyEcoPoints = _keyEcoPoints;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getInt(_keyEcoPoints) ?? 0;
  }

  Future<void> addPoints(int points) async {
    if (points <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyEcoPoints) ?? 0;
    final updated = current + points;
    await prefs.setInt(_keyEcoPoints, updated);
    value = updated;
  }

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getInt(_keyEcoPoints) ?? 0;
  }
}
