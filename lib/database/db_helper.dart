import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../constants/app_food_formatter.dart';
import '../models/food_item_model.dart';
import '../models/food_log_model.dart';
import '../models/notification_model.dart';
import '../models/pantry_item_model.dart';
import '../models/user_model.dart';
import '../services/app_notifiers.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../utils/security_helper.dart';

//// Helper database SQLite lokal (CRUD user, makanan, pantry, & notifikasi)
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

    final db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async => await _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
        await _loadFoodCatalogFromAssets(db);
      },
      onDowngrade: onDatabaseDowngradeDelete,
    );

    // Tambahkan indexing database untuk akselerasi query kilat O(log N)
    await _createIndices(db);

    // Pastikan katalog makanan selalu tersinkronisasi dan URL gambar lama diperbaiki (hanya 1x check)
    await _ensureFoodCatalogSynced(db);

    return db;
  }

  Future<void> _createIndices(Database db) async {
    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_food_logs_user_date ON $tableFoodLogs(user_id, date);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_pantry_user_status ON $tablePantryItems(user_id, is_used, expiry_date);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON $tableNotifications(user_id, is_read);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_pantry ON $tableNotifications(related_pantry_id, user_id);',
      );
      // Pastikan kolom soft delete dan firestore_id tersedia di table notifications
      try {
        await db.execute(
          'ALTER TABLE $tableNotifications ADD COLUMN is_deleted INTEGER DEFAULT 0;',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tableNotifications ADD COLUMN firestore_id TEXT;',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tablePantryItems ADD COLUMN image_url TEXT;',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tablePantryItems ADD COLUMN firestore_id TEXT;',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE $tableFoodLogs ADD COLUMN firestore_id TEXT;',
        );
      } catch (_) {}
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_user_deleted ON $tableNotifications(user_id, is_deleted);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_foods_category ON $tableFoods(category);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_foods_name ON $tableFoods(name);',
      );
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
        note TEXT,
        firestore_id TEXT,
        created_at TEXT NOT NULL
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
        firestore_id TEXT,
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
        is_deleted INTEGER DEFAULT 0,
        related_pantry_id INTEGER,
        firestore_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await _createIndices(db);
    await _loadFoodCatalogFromAssets(db);
  }

  /// Memuat master katalog makanan dari assets lokal ke database SQLite
  Future<void> _loadFoodCatalogFromAssets(Database db) async {
    try {
      final jsonString = await rootBundle.loadString('assets/food_data.json');
      final foods = FoodItemModel.listFromJsonString(jsonString);

      await db.delete(tableFoods);

      final batch = db.batch();
      final seenNames = <String>{};
      for (final food in foods) {
        if (seenNames.add(food.name.trim().toLowerCase())) {
          batch.insert(tableFoods, food.toMap()..remove('id'));
        }
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  /// Sinkronisasi otomatis katalog makanan & perbaikan URL gambar warisan (legacy)
  Future<void> _ensureFoodCatalogSynced(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const syncKey = 'food_catalog_synced_v11';
      if (prefs.getBool(syncKey) == true) return;

      // Sinkronkan ulang database dengan data gizi katalog yang sudah dinormalisasi ke porsi saji realistis (URT)
      await _loadFoodCatalogFromAssets(db);

      // Perbaiki juga data food_logs & pantry_items jika user sempat mencatat dengan URL lama
      const fallbackCleanImage =
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500';

      try {
        await db.rawUpdate('''
          UPDATE $tableFoodLogs 
          SET image_path = '$fallbackCleanImage' 
          WHERE image_path LIKE '%katakabar%' 
             OR image_path LIKE '%masakapahariini%' 
             OR image_path LIKE '%bukanarjuna%'
        ''');
      } catch (_) {}

      try {
        await db.rawUpdate('''
          UPDATE $tablePantryItems 
          SET image_url = '$fallbackCleanImage' 
          WHERE image_url LIKE '%katakabar%' 
             OR image_url LIKE '%masakapahariini%' 
             OR image_url LIKE '%bukanarjuna%'
        ''');
      } catch (_) {}

      await prefs.setBool(syncKey, true);
    } catch (_) {}
  }

  Future<void> _createWelcomeNotifications(
    Database db, {
    required int userId,
  }) async {
    final now = DateTime.now();
    final notifs = [
      NotificationModel(
        userId: userId,
        title: 'Tips Food Rescue',
        message:
            'Gunakan bahan yang paling dekat tanggal kedaluwarsanya terlebih dahulu untuk mengurangi sampah makanan.',
        type: 'tips',
        iconType: 'lightbulb',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      NotificationModel(
        userId: userId,
        title: 'Selamat Datang di FoodCura!',
        message:
            'Mulai catat makanan harian dan pantau stok kulkas Anda untuk gaya hidup lebih sehat.',
        type: 'system',
        iconType: 'eco',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
    ];
    for (var n in notifs) {
      await db.insert(
        tableNotifications,
        n.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // --- USER AUTH CRUD ---

  /// Ambil user ID yang sedang login dari SharedPreferences
  Future<int?> getActiveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyLoggedInUserId);
  }

  /// Registrasi user baru
  Future<bool> registerUser(UserModelSQL pengguna) async {
    final db = await database;
    try {
      final userMap = pengguna.toMap()..remove('id');
      userMap['email'] = pengguna.email.trim().toLowerCase();
      userMap['name'] = pengguna.name.trim();
      userMap['password'] = SecurityHelper.hashPassword(pengguna.password);
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
        await _createWelcomeNotifications(db, userId: id);
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

  /// Login user dengan verifikasi password hash SHA-256 (support legacy auto-upgrade)
  Future<UserModelSQL?> loginUser(String email, String password) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();
    final results = await db.query(
      AppConstants.tableUsers,
      where: 'LOWER(TRIM(email)) = ?',
      whereArgs: [cleanEmail],
      limit: 1,
    );

    if (results.isNotEmpty) {
      final userMap = Map<String, dynamic>.from(results.first);
      final storedPassword = userMap['password'] as String? ?? '';

      // Cegah bypass login form biasa untuk akun yang terdaftar via Google OAuth
      final isGoogle =
          storedPassword == 'google_oauth_user' ||
          storedPassword.startsWith('GOOGLE_OAUTH_') ||
          storedPassword.startsWith('GOOGLE_AUTH_');
      if (isGoogle) {
        throw 'Akun ini terdaftar menggunakan Google Sign-In. Silakan masuk menggunakan tombol "Lanjutkan dengan Google".';
      }

      if (SecurityHelper.verifyPassword(password, storedPassword)) {
        // Auto-upgrade legacy plaintext password ke SHA-256 hash jika belum di-hash
        if (!SecurityHelper.isHashed(storedPassword)) {
          final secureHash = SecurityHelper.hashPassword(password);
          await db.update(
            AppConstants.tableUsers,
            {'password': secureHash},
            where: 'id = ?',
            whereArgs: [userMap['id']],
          );
          userMap['password'] = secureHash;
        }

        final user = UserModelSQL.fromMap(userMap);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(AppConstants.keyLoggedInUserId, user.id!);
        await EcoPointsNotifier.instance.refresh();
        await NotificationNotifier.instance.refresh();
        PantryUpdateNotifier.instance.notifyPantryChanged();
        return user;
      }
    }
    return null;
  }

  /// Ambil data profil user yang sedang login
  Future<UserModelSQL?> getLoggedInUser() async {
    final userId = await getActiveUserId();
    if (userId == null) return null;
    final db = await database;
    final results = await db.query(
      AppConstants.tableUsers,
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (results.isEmpty) return null;

    UserModelSQL user = UserModelSQL.fromMap(results.first);

    // Sinkronisasi tanggal bergabung asli dari akun Firebase jika ada
    try {
      final fbUser = AuthService.instance.currentUser;
      if (fbUser != null &&
          fbUser.email != null &&
          fbUser.email!.trim().toLowerCase() ==
              user.email.trim().toLowerCase() &&
          fbUser.metadata.creationTime != null) {
        final fbCreationTime = fbUser.metadata.creationTime!;
        final localCreated = DateTime.tryParse(user.createdAt ?? '');
        if (localCreated == null || localCreated.isAfter(fbCreationTime)) {
          final trueCreatedAt = fbCreationTime.toIso8601String();
          await db.update(
            AppConstants.tableUsers,
            {'created_at': trueCreatedAt},
            where: 'id = ?',
            whereArgs: [userId],
          );
          user = UserModelSQL(
            id: user.id,
            name: user.name,
            email: user.email,
            password: user.password,
            createdAt: trueCreatedAt,
          );
        }
      }
    } catch (_) {}

    return user;
  }

  /// Cari atau buat akun user baru dari Google Sign-In
  Future<UserModelSQL?> findOrCreateGoogleUser(
    String email,
    String name, {
    DateTime? creationTime,
  }) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim().isNotEmpty
        ? name.trim()
        : 'Pengguna FoodCura';

    final results = await db.query(
      AppConstants.tableUsers,
      where: 'LOWER(TRIM(email)) = ?',
      whereArgs: [cleanEmail],
      limit: 1,
    );

    int userId;
    UserModelSQL user;

    if (results.isNotEmpty) {
      user = UserModelSQL.fromMap(results.first);
      userId = user.id!;
      // Perbarui tanggal bergabung jika akun Firebase dibuat lebih awal
      if (creationTime != null) {
        final localCreated = DateTime.tryParse(user.createdAt ?? '');
        if (localCreated == null || localCreated.isAfter(creationTime)) {
          final trueCreatedAt = creationTime.toIso8601String();
          await db.update(
            AppConstants.tableUsers,
            {'created_at': trueCreatedAt},
            where: 'id = ?',
            whereArgs: [userId],
          );
          user = UserModelSQL(
            id: user.id,
            name: user.name,
            email: user.email,
            password: user.password,
            createdAt: trueCreatedAt,
          );
        }
      }
    } else {
      final trueCreationDate = (creationTime ?? DateTime.now())
          .toIso8601String();
      final secureOAuthToken =
          'GOOGLE_OAUTH_LOCKED_${DateTime.now().microsecondsSinceEpoch}';
      final userMap = {
        'name': cleanName,
        'email': cleanEmail,
        'password': secureOAuthToken,
        'created_at': trueCreationDate,
      };
      userId = await db.insert(AppConstants.tableUsers, userMap);
      user = UserModelSQL(
        id: userId,
        name: cleanName,
        email: cleanEmail,
        password: secureOAuthToken,
        createdAt: userMap['created_at'],
      );
      await _createWelcomeNotifications(db, userId: userId);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyLoggedInUserId, userId);
    await EcoPointsNotifier.instance.refresh();
    await NotificationNotifier.instance.refresh();
    PantryUpdateNotifier.instance.notifyPantryChanged();
    return user;
  }

  /// Logout user dan bersihkan session SharedPreferences
  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyLoggedInUserId);
    try {
      await NotificationService.instance.cancelAllNotifications();
    } catch (_) {}
    await EcoPointsNotifier.instance.refresh();
    await NotificationNotifier.instance.refresh();
    PantryUpdateNotifier.instance.notifyPantryChanged();
  }

  /// Update informasi profil user (nama & email)
  Future<bool> updateUser(UserModelSQL user) async {
    if (user.id == null) return false;
    final db = await database;
    final userMap = user.toMap();
    userMap['email'] = user.email.trim().toLowerCase();
    userMap['name'] = user.name.trim();

    final count = await db.update(
      AppConstants.tableUsers,
      userMap,
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return count > 0;
  }

  /// Ambil semua daftar pengguna
  Future<List<UserModelSQL>> getAllUsers() async {
    final db = await database;
    final results = await db.query(AppConstants.tableUsers);
    return results.map((map) => UserModelSQL.fromMap(map)).toList();
  }

  /// Hapus akun user beserta seluruh data riwayat terkait (cascading batch delete)
  Future<void> deleteUser(int id) async {
    final db = await database;
    final batch = db.batch();
    batch.delete(AppConstants.tableUsers, where: 'id = ?', whereArgs: [id]);
    batch.delete(tableFoodLogs, where: 'user_id = ?', whereArgs: [id]);
    batch.delete(tablePantryItems, where: 'user_id = ?', whereArgs: [id]);
    batch.delete(tableNotifications, where: 'user_id = ?', whereArgs: [id]);
    await batch.commit(noResult: true);
  }

  /// Cek ketersediaan/duplikasi email
  Future<bool> isEmailRegistered(String email) async {
    final db = await database;
    final res = await db.query(
      AppConstants.tableUsers,
      where: 'LOWER(TRIM(email)) = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return res.isNotEmpty;
  }

  /// Ambil user berdasarkan email (untuk validasi reset password)
  Future<UserModelSQL?> getUserByEmail(String email) async {
    final db = await database;
    final res = await db.query(
      AppConstants.tableUsers,
      where: 'LOWER(TRIM(email)) = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return UserModelSQL.fromMap(res.first);
  }

  /// Perbarui password user berdasarkan email (sinkronisasi reset password)
  Future<bool> updatePasswordForEmail(String email, String newPassword) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();
    final newHashedPassword = SecurityHelper.hashPassword(newPassword);
    final count = await db.update(
      AppConstants.tableUsers,
      {'password': newHashedPassword},
      where: 'LOWER(TRIM(email)) = ?',
      whereArgs: [cleanEmail],
    );
    return count > 0;
  }

  /// Ganti password user dengan validasi password lama
  Future<bool> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final db = await database;
    final userResults = await db.query(
      AppConstants.tableUsers,
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (userResults.isEmpty) return false;

    final storedPassword = userResults.first['password'] as String? ?? '';
    // Akun Google tidak memiliki password lokal untuk diubah
    final isGoogle =
        storedPassword == 'google_oauth_user' ||
        storedPassword.startsWith('GOOGLE_OAUTH_') ||
        storedPassword.startsWith('GOOGLE_AUTH_');
    if (isGoogle) {
      return false;
    }

    if (!SecurityHelper.verifyPassword(oldPassword, storedPassword)) {
      return false;
    }

    final newHashedPassword = SecurityHelper.hashPassword(newPassword);
    final count = await db.update(
      AppConstants.tableUsers,
      {'password': newHashedPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return count > 0;
  }

  // --- FOOD CATALOG & LOGS CRUD ---

  /// Ambil semua daftar katalog makanan (cepat dengan memanfaatkan index)
  Future<List<FoodItemModel>> getFoodCatalog() async {
    final db = await database;
    final results = await db.query(tableFoods, orderBy: 'name ASC');
    return results.map((map) => FoodItemModel.fromMap(map)).toList();
  }

  /// Sinkronisasi katalog makanan antara Cloud Firestore dan SQLite lokal (Offline-First)
  Future<void> syncFoodCatalogWithFirestore() async {
    try {
      final firestoreService = FirestoreService.instance;
      if (!firestoreService.isAvailable) return;

      final remoteFoods = await firestoreService.getFoods();
      if (remoteFoods.isEmpty) {
        // Jika koleksi foods di Firestore masih kosong, seed dari database lokal
        final localFoods = await getFoodCatalog();
        if (localFoods.isNotEmpty) {
          await firestoreService.seedFoods(localFoods);
        }
      } else {
        // Jika terdapat data dari Firestore, upsert ke SQLite lokal agar katalog selalu mutakhir
        final db = await database;
        final batch = db.batch();
        for (final food in remoteFoods) {
          batch.insert(
            tableFoods,
            food.toMap()..remove('id'),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    } catch (_) {
      // Abaikan kegagalan jaringan saat offline
    }
  }

  /// Cari makanan di katalog berdasarkan nama atau kategori
  Future<List<FoodItemModel>> searchFoodCatalog(
    String query, {
    int? limit,
  }) async {
    final db = await database;
    final cleanQuery = query.trim();
    final results = await db.query(
      tableFoods,
      where: 'name LIKE ? OR category LIKE ?',
      whereArgs: ['%$cleanQuery%', '%$cleanQuery%'],
      orderBy: 'name ASC',
      limit: limit,
    );
    return results.map((map) => FoodItemModel.fromMap(map)).toList();
  }

  /// Ambil riwayat makanan yang baru dicatat user secara batch O(1) query
  Future<List<FoodItemModel>> getRecentAddedFoods({
    int limit = 10,
    int? userId,
  }) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return [];

    final db = await database;
    final rawLogs = await db.query(
      tableFoodLogs,
      where: 'user_id = ?',
      whereArgs: [targetUserId],
      orderBy: 'id DESC',
      limit: limit * 2,
    );
    final seen = <String>{};
    final namesToFetch = <String>{};
    final logMapByName = <String, Map<String, dynamic>>{};
    final rawNamesOrdered = <String>[];

    for (var log in rawLogs) {
      final name = (log['food_name'] as String?)?.trim() ?? '';
      if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
      rawNamesOrdered.add(name);
      namesToFetch.add(name);

      // Ekstraksi nama dasar jika makanan tercatat dengan porsi kurung (mencegah duplikasi kalkulasi kalori)
      final match = RegExp(r'^(.*?)\s*\(([^)]+)\)$').firstMatch(name);
      if (match != null) {
        final candidateBase = match.group(1)!.trim();
        final candidateInner = match.group(2)!.trim();
        if (AppFoodFormatter.isPortionUnit(candidateInner) ||
            candidateInner.toLowerCase().contains('porsi')) {
          namesToFetch.add(candidateBase);
        }
      }

      logMapByName[name.toLowerCase()] = log;
      if (rawNamesOrdered.length >= limit) break;
    }

    if (rawNamesOrdered.isEmpty) return [];

    // Query batch sekaligus menggunakan WHERE name IN (...) tanpa loop query N+1
    final placeholders = List.filled(namesToFetch.length, '?').join(',');
    final catalogMatches = await db.query(
      tableFoods,
      where: 'name IN ($placeholders)',
      whereArgs: namesToFetch.toList(),
    );

    final catalogByName = {
      for (var row in catalogMatches)
        (row['name'] as String).trim().toLowerCase(): FoodItemModel.fromMap(
          row,
        ),
    };

    final uniqueItems = <FoodItemModel>[];
    for (var name in rawNamesOrdered) {
      final lower = name.toLowerCase();

      // Cek apakah kandidat nama dasar tersedia di katalog dasar
      String? baseName;
      final match = RegExp(r'^(.*?)\s*\(([^)]+)\)$').firstMatch(name);
      if (match != null) {
        final candidateInner = match.group(2)!.trim();
        if (AppFoodFormatter.isPortionUnit(candidateInner) ||
            candidateInner.toLowerCase().contains('porsi')) {
          baseName = match.group(1)!.trim();
        }
      }

      if (baseName != null &&
          catalogByName.containsKey(baseName.toLowerCase())) {
        uniqueItems.add(catalogByName[baseName.toLowerCase()]!);
      } else if (catalogByName.containsKey(lower)) {
        uniqueItems.add(catalogByName[lower]!);
      } else {
        final log = logMapByName[lower]!;
        uniqueItems.add(
          FoodItemModel(
            name: baseName ?? AppFoodFormatter.cleanDisplayName(name),
            calories: (log['calories'] as num?)?.toInt() ?? 0,
            protein: (log['protein'] as num?)?.toDouble() ?? 0.0,
            carbs: (log['carbs'] as num?)?.toDouble() ?? 0.0,
            fat: (log['fat'] as num?)?.toDouble() ?? 0.0,
            cholesterol: ((log['cholesterol'] as num?) ?? 0.0).toDouble(),
            category: log['meal_type'] as String? ?? 'Camilan',
            imagePath: (log['image_path'] as String?)?.isNotEmpty == true
                ? log['image_path'] as String
                : 'assets/images/food/default_food.png',
          ),
        );
      }
    }
    return uniqueItems;
  }

  /// Ambil log makanan user per tanggal
  Future<List<FoodLogModel>> getFoodLogs({String? date, int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return [];

    final db = await database;
    final where = ['user_id = ?', if (date != null) 'date = ?'].join(' AND ');
    final args = [targetUserId, ?date];

    final results = await db.query(
      tableFoodLogs,
      where: where,
      whereArgs: args,
      orderBy: 'time ASC',
    );
    return results.map((map) => FoodLogModel.fromMap(map)).toList();
  }

  /// Simpan catatan makanan baru
  Future<int> insertFoodLog(FoodLogModel log) async {
    final db = await database;
    final targetUserId = log.userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final logMap = log.copyWith(userId: targetUserId).toMap()..remove('id');
    return await db.insert(
      tableFoodLogs,
      logMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update catatan makanan
  Future<int> updateFoodLog(FoodLogModel log) async {
    if (log.id == null) return 0;
    final db = await database;
    final targetUserId = log.userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    return await db.update(
      tableFoodLogs,
      log.copyWith(userId: targetUserId).toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [log.id, targetUserId],
    );
  }

  /// Hapus catatan makanan berdasarkan ID
  Future<int> deleteFoodLog(int id, {int? userId}) async {
    final db = await database;
    final targetUserId = userId ?? await getActiveUserId();
    return await db.delete(
      tableFoodLogs,
      where: targetUserId != null
          ? 'id = ? AND (user_id = ? OR user_id = 0 OR user_id IS NULL)'
          : 'id = ?',
      whereArgs: targetUserId != null ? [id, targetUserId] : [id],
    );
  }

  // --- PANTRY CRUD ---

  /// Tambah bahan baru ke inventaris pantry
  Future<int> addPantryItem(PantryItemModel item) async {
    final db = await database;
    final targetUserId = item.userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final res = await db.insert(
      tablePantryItems,
      item.copyWith(userId: targetUserId).toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    PantryUpdateNotifier.instance.notifyPantryChanged();
    return res;
  }

  /// Ambil daftar bahan pantry yang belum habis/dipakai
  Future<List<PantryItemModel>> getPantryItems({int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return [];

    final db = await database;
    final results = await db.query(
      tablePantryItems,
      where: 'is_used = 0 AND user_id = ?',
      whereArgs: [targetUserId],
      orderBy: 'expiry_date ASC',
    );
    return results.map((map) => PantryItemModel.fromMap(map)).toList();
  }

  /// Ambil seluruh bahan pantry user (termasuk yang is_used = 1) untuk keperluan sinkronisasi
  Future<List<PantryItemModel>> getAllPantryItemsRaw({int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return [];

    final db = await database;
    final results = await db.query(
      tablePantryItems,
      where: 'user_id = ?',
      whereArgs: [targetUserId],
      orderBy: 'expiry_date ASC',
    );
    return results.map((map) => PantryItemModel.fromMap(map)).toList();
  }

  /// Cari bahan pantry berdasarkan nama
  Future<List<PantryItemModel>> searchPantryItems(
    String query, {
    int? userId,
  }) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return [];

    final db = await database;
    final results = await db.query(
      tablePantryItems,
      where: 'is_used = 0 AND name LIKE ? AND user_id = ?',
      whereArgs: ['%$query%', targetUserId],
      orderBy: 'expiry_date ASC',
    );
    return results.map((map) => PantryItemModel.fromMap(map)).toList();
  }

  /// Tandai bahan pantry sudah digunakan/habis (+5 Eco Points)
  Future<int> markPantryItemUsed(int id, {int? userId}) async {
    final db = await database;
    final targetUserId = userId ?? await getActiveUserId();

    final rows = await db.query(
      tablePantryItems,
      columns: ['expiry_date', 'is_used'],
      where: targetUserId != null
          ? 'id = ? AND (user_id = ? OR user_id = 0 OR user_id IS NULL)'
          : 'id = ?',
      whereArgs: targetUserId != null ? [id, targetUserId] : [id],
      limit: 1,
    );
    if (rows.isEmpty || (rows.first['is_used'] as int?) == 1) return 0;

    final res = await db.update(
      tablePantryItems,
      {'is_used': 1},
      where: targetUserId != null
          ? 'id = ? AND (user_id = ? OR user_id = 0 OR user_id IS NULL)'
          : 'id = ?',
      whereArgs: targetUserId != null ? [id, targetUserId] : [id],
    );

    // Eco points hanya diberikan jika bahan dihabiskan sebelum kedaluwarsa
    final expStr = rows.first['expiry_date'] as String?;
    final expDate = DateTime.tryParse(expStr ?? '');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (expDate == null ||
        DateTime(
              expDate.year,
              expDate.month,
              expDate.day,
            ).difference(today).inDays >=
            0) {
      await EcoPointsNotifier.instance.addPoints(5);
    }
    PantryUpdateNotifier.instance.notifyPantryChanged();
    return res;
  }

  /// Hapus item bahan dari pantry
  Future<int> deletePantryItem(int id, {int? userId}) async {
    final db = await database;
    final targetUserId = userId ?? await getActiveUserId();

    final res = await db.delete(
      tablePantryItems,
      where: targetUserId != null
          ? 'id = ? AND (user_id = ? OR user_id = 0 OR user_id IS NULL)'
          : 'id = ?',
      whereArgs: targetUserId != null ? [id, targetUserId] : [id],
    );
    PantryUpdateNotifier.instance.notifyPantryChanged();
    return res;
  }

  /// Update data bahan makanan di pantry
  Future<int> updatePantryItem(PantryItemModel item) async {
    if (item.id == null) return 0;
    final db = await database;
    final targetUserId = item.userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final res = await db.update(
      tablePantryItems,
      item.copyWith(userId: targetUserId).toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [item.id, targetUserId],
    );
    PantryUpdateNotifier.instance.notifyPantryChanged();
    return res;
  }

  // Hitung jumlah bahan berdasarkan status kedaluwarsa
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

  /// Simpan notifikasi baru
  Future<int> addNotification(
    NotificationModel notif, {
    bool syncToCloud = true,
  }) async {
    final db = await database;
    final targetUserId = notif.userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final res = await db.insert(
      tableNotifications,
      notif.copyWith(userId: targetUserId).toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Sinkronisasi notifikasi ke Firestore (latar belakang) jika bukan hasil sync dari cloud
    if (syncToCloud) {
      try {
        final uid =
            AuthService.instance.currentUser?.uid ?? 'user_$targetUserId';
        final cloudDocId = notif.firestoreId ?? 'notif_$res';
        FirestoreService.instance
            .addNotification(
              uid,
              notif.copyWith(
                id: res,
                userId: targetUserId,
                firestoreId: cloudDocId,
              ),
            )
            .then((returnedId) {
              if (returnedId != null) {
                db
                    .update(
                      tableNotifications,
                      {'firestore_id': returnedId},
                      where: 'id = ?',
                      whereArgs: [res],
                    )
                    .ignore();
              }
            })
            .ignore();
      } catch (_) {}
    }

    await NotificationNotifier.instance.refresh();
    return res;
  }

  /// Perbarui notifikasi yang sudah ada (judul, pesan, status baca, dll.)
  Future<int> updateNotification(
    NotificationModel notif, {
    bool syncToCloud = true,
  }) async {
    if (notif.id == null) return 0;
    final db = await database;
    final targetUserId = notif.userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final res = await db.update(
      tableNotifications,
      notif.copyWith(userId: targetUserId).toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [notif.id, targetUserId],
    );

    if (syncToCloud) {
      try {
        final uid =
            AuthService.instance.currentUser?.uid ?? 'user_$targetUserId';
        FirestoreService.instance
            .addNotification(uid, notif.copyWith(userId: targetUserId))
            .ignore();
      } catch (_) {}
    }

    await NotificationNotifier.instance.refresh();
    return res;
  }

  /// Ambil daftar notifikasi user dengan opsi filter kategori (hanya yang belum dihapus)
  Future<List<NotificationModel>> getNotifications({
    String? filter,
    int? userId,
  }) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return [];

    final db = await database;
    String? typeClause;
    if (filter != null &&
        filter != 'Semua' &&
        filter != NotificationModel.filterAll &&
        filter.isNotEmpty) {
      if (filter == NotificationModel.filterExpiry ||
          filter == NotificationModel.typeExpiryWarning ||
          filter == 'Kedaluwarsa' ||
          filter == 'Kadaluwarsa') {
        typeClause = "type = '${NotificationModel.typeExpiryWarning}'";
      } else if (filter == NotificationModel.filterUnread ||
          filter == 'Belum Dibaca') {
        typeClause = "is_read = 0";
      } else if (filter == NotificationModel.filterMealReminder ||
          filter == NotificationModel.typeMealReminder ||
          filter == 'Pengingat Makan') {
        typeClause = "type = '${NotificationModel.typeMealReminder}'";
      } else if (filter == NotificationModel.filterNutritionExcess ||
          filter == NotificationModel.typeNutritionExcess ||
          filter == 'Alert Gizi') {
        typeClause = "type = '${NotificationModel.typeNutritionExcess}'";
      } else if (filter == NotificationModel.filterInfoTips ||
          filter == NotificationModel.typeTips ||
          filter == NotificationModel.typeSystem ||
          filter == 'Sistem' ||
          filter == 'Info & Tips') {
        typeClause =
            "type IN ('${NotificationModel.typeSystem}', '${NotificationModel.typeTips}')";
      }
    }

    final where = ['user_id = ?', 'is_deleted = 0', ?typeClause].join(' AND ');
    final results = await db.query(
      tableNotifications,
      where: where,
      whereArgs: [targetUserId],
      orderBy: 'created_at DESC',
    );
    return results.map((map) => NotificationModel.fromMap(map)).toList();
  }

  /// Ambil seluruh notifikasi user (termasuk yang is_deleted = 1) untuk keperluan resolusi sinkronisasi
  Future<List<NotificationModel>> getAllNotificationsRaw({int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return [];

    final db = await database;
    final results = await db.query(
      tableNotifications,
      where: 'user_id = ?',
      whereArgs: [targetUserId],
      orderBy: 'created_at DESC',
    );
    return results.map((map) => NotificationModel.fromMap(map)).toList();
  }

  /// Tandai notifikasi tertentu sudah dibaca
  Future<int> markNotificationRead(int id, {String? firestoreId}) async {
    final db = await database;
    final targetUserId = await getActiveUserId();
    if (targetUserId == null) return 0;

    final res = await db.update(
      tableNotifications,
      {'is_read': 1},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, targetUserId],
    );

    // Sinkronisasi status dibaca ke Firestore
    try {
      final uid = AuthService.instance.currentUser?.uid ?? 'user_$targetUserId';
      String? cloudDocId = firestoreId;
      if (cloudDocId == null) {
        final rows = await db.query(
          tableNotifications,
          columns: ['firestore_id'],
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, targetUserId],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          cloudDocId = rows.first['firestore_id'] as String?;
        }
      }
      cloudDocId ??= 'notif_$id';
      FirestoreService.instance.markNotificationRead(uid, cloudDocId).ignore();
    } catch (_) {
      // Supresi aman saat offline atau unauthenticated
    }

    await NotificationNotifier.instance.refresh();
    return res;
  }

  /// Tandai semua notifikasi sudah dibaca
  Future<int> markAllNotificationsRead({int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final db = await database;
    final res = await db.update(
      tableNotifications,
      {'is_read': 1},
      where: 'is_read = 0 AND is_deleted = 0 AND user_id = ?',
      whereArgs: [targetUserId],
    );

    // Sinkronisasi tandai semua dibaca ke Firestore
    try {
      final uid = AuthService.instance.currentUser?.uid ?? 'user_$targetUserId';
      FirestoreService.instance.markAllNotificationsRead(uid).ignore();
    } catch (_) {
      // Supresi aman saat offline atau unauthenticated
    }

    await NotificationNotifier.instance.refresh();
    return res;
  }

  /// Hitung jumlah notifikasi yang belum dibaca (tidak termasuk yang dihapus)
  Future<int> getUnreadNotificationCount({int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableNotifications WHERE is_read = 0 AND is_deleted = 0 AND user_id = ?',
      [targetUserId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Bersihkan notifikasi duplikat aktif di database
  Future<void> cleanDuplicateNotifications({int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return;

    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE $tableNotifications
      SET is_deleted = 1
      WHERE id NOT IN (
        SELECT MAX(id)
        FROM $tableNotifications
        WHERE user_id = ? AND is_deleted = 0
        GROUP BY title, substr(created_at, 1, 10), IFNULL(related_pantry_id, 0)
      ) AND user_id = ? AND is_deleted = 0
    ''',
      [targetUserId, targetUserId],
    );
  }

  /// Hapus satu notifikasi (soft delete) berdasarkan ID
  Future<int> deleteNotification(
    int id, {
    String? firestoreId,
    int? userId,
  }) async {
    final targetUserId = userId ?? await getActiveUserId();
    final db = await database;

    // Ambil firestore_id jika belum diberikan
    String? cloudDocId = firestoreId;
    if (cloudDocId == null) {
      final rows = await db.query(
        tableNotifications,
        columns: ['firestore_id', 'user_id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        cloudDocId = rows.first['firestore_id'] as String?;
      }
    }
    cloudDocId ??= 'notif_$id';

    final res = await db.update(
      tableNotifications,
      {'is_deleted': 1},
      where: targetUserId != null
          ? 'id = ? AND (user_id = ? OR user_id = 0 OR user_id IS NULL)'
          : 'id = ?',
      whereArgs: targetUserId != null ? [id, targetUserId] : [id],
    );

    // Sinkronisasi soft delete ke Firestore
    try {
      final uid =
          AuthService.instance.currentUser?.uid ??
          (targetUserId != null ? 'user_$targetUserId' : null);
      if (uid != null) {
        FirestoreService.instance
            .softDeleteNotification(uid, cloudDocId)
            .ignore();
      }
    } catch (_) {
      // Supresi aman saat offline atau unauthenticated
    }

    await NotificationNotifier.instance.refresh();
    return res;
  }

  /// Hapus beberapa notifikasi sekaligus (batch soft delete) berdasarkan daftar ID
  Future<int> deleteNotifications(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final targetUserId = await getActiveUserId();
    if (targetUserId == null) return 0;

    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');

    // Ambil mapping doc ids yang valid
    final rows = await db.query(
      tableNotifications,
      columns: ['id', 'firestore_id'],
      where: 'id IN ($placeholders) AND (user_id = ? OR user_id = 0 OR user_id IS NULL)',
      whereArgs: [...ids, targetUserId],
    );
    final docIds = rows.map((r) {
      final fId = r['firestore_id'] as String?;
      final localId = r['id'];
      return (fId != null && fId.isNotEmpty) ? fId : 'notif_$localId';
    }).toList();

    final res = await db.update(
      tableNotifications,
      {'is_deleted': 1},
      where: 'id IN ($placeholders) AND (user_id = ? OR user_id = 0 OR user_id IS NULL)',
      whereArgs: [...ids, targetUserId],
    );

    // Sinkronisasi batch soft delete ke Firestore
    try {
      final uid = AuthService.instance.currentUser?.uid ?? 'user_$targetUserId';
      FirestoreService.instance
          .softDeleteNotificationsBatch(uid, docIds)
          .ignore();
    } catch (_) {
      // Supresi aman saat offline atau unauthenticated
    }

    await NotificationNotifier.instance.refresh();
    return res;
  }

  /// Hapus semua notifikasi terkait item pantry tertentu (soft delete)
  Future<int> deleteNotificationsByPantryId(int pantryId, {int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final db = await database;
    final res = await db.update(
      tableNotifications,
      {'is_deleted': 1},
      where: 'related_pantry_id = ? AND (user_id = ? OR user_id = 0 OR user_id IS NULL)',
      whereArgs: [pantryId, targetUserId],
    );

    // Sinkronisasi soft delete notifikasi terkait pantry ke Firestore
    try {
      final uid = AuthService.instance.currentUser?.uid ?? 'user_$targetUserId';
      FirestoreService.instance
          .softDeleteNotificationsByPantryId(uid, pantryId)
          .ignore();
    } catch (_) {}

    await NotificationNotifier.instance.refresh();
    return res;
  }

  /// Hapus notifikasi pengingat jam makan tertentu hari ini (soft delete)
  Future<int> deleteMealReminderNotifications(
    String mealType, {
    int? userId,
  }) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final now = DateTime.now();
    final todayDateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final db = await database;

    final rows = await db.query(
      tableNotifications,
      columns: ['id', 'firestore_id'],
      where:
          "type = '${NotificationModel.typeMealReminder}' AND (LOWER(title) LIKE ? OR LOWER(message) LIKE ?) AND substr(created_at, 1, 10) = ? AND user_id = ? AND is_deleted = 0",
      whereArgs: [
        '%${mealType.toLowerCase()}%',
        '%${mealType.toLowerCase()}%',
        todayDateStr,
        targetUserId,
      ],
    );

    final res = await db.update(
      tableNotifications,
      {'is_deleted': 1},
      where:
          "type = '${NotificationModel.typeMealReminder}' AND (LOWER(title) LIKE ? OR LOWER(message) LIKE ?) AND substr(created_at, 1, 10) = ? AND user_id = ?",
      whereArgs: [
        '%${mealType.toLowerCase()}%',
        '%${mealType.toLowerCase()}%',
        todayDateStr,
        targetUserId,
      ],
    );

    if (rows.isNotEmpty) {
      try {
        final uid =
            AuthService.instance.currentUser?.uid ?? 'user_$targetUserId';
        final docIds = rows.map((r) {
          final fId = r['firestore_id'] as String?;
          final localId = r['id'];
          return (fId != null && fId.isNotEmpty) ? fId : 'notif_$localId';
        }).toList();
        FirestoreService.instance
            .softDeleteNotificationsBatch(uid, docIds)
            .ignore();
      } catch (_) {}
    }

    await NotificationNotifier.instance.refresh();
    return res;
  }

  /// Hapus notifikasi batas nutrisi tertentu hari ini (soft delete)
  Future<int> deleteNutritionNotifications(
    String keyword, {
    int? userId,
  }) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final now = DateTime.now();
    final todayDateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final db = await database;

    final rows = await db.query(
      tableNotifications,
      columns: ['id', 'firestore_id'],
      where:
          "type = '${NotificationModel.typeNutritionExcess}' AND title LIKE ? AND substr(created_at, 1, 10) = ? AND user_id = ? AND is_deleted = 0",
      whereArgs: ['%$keyword%', todayDateStr, targetUserId],
    );

    final res = await db.update(
      tableNotifications,
      {'is_deleted': 1},
      where:
          "type = '${NotificationModel.typeNutritionExcess}' AND title LIKE ? AND substr(created_at, 1, 10) = ? AND user_id = ?",
      whereArgs: ['%$keyword%', todayDateStr, targetUserId],
    );

    if (rows.isNotEmpty) {
      try {
        final uid =
            AuthService.instance.currentUser?.uid ?? 'user_$targetUserId';
        final docIds = rows.map((r) {
          final fId = r['firestore_id'] as String?;
          final localId = r['id'];
          return (fId != null && fId.isNotEmpty) ? fId : 'notif_$localId';
        }).toList();
        FirestoreService.instance
            .softDeleteNotificationsBatch(uid, docIds)
            .ignore();
      } catch (_) {}
    }

    await NotificationNotifier.instance.refresh();
    return res;
  }

  /// Hapus semua notifikasi milik user aktif (soft delete)
  Future<int> clearAllNotifications({int? userId}) async {
    final targetUserId = userId ?? await getActiveUserId();
    if (targetUserId == null) return 0;

    final db = await database;
    final res = await db.update(
      tableNotifications,
      {'is_deleted': 1},
      where: 'user_id = ?',
      whereArgs: [targetUserId],
    );

    // Sinkronisasi soft delete semua notifikasi ke Firestore
    try {
      final uid = AuthService.instance.currentUser?.uid ?? 'user_$targetUserId';
      FirestoreService.instance.softDeleteAllNotifications(uid).ignore();
    } catch (_) {}

    await NotificationNotifier.instance.refresh();
    return res;
  }
}
