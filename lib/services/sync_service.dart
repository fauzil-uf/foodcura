import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../database/db_helper.dart';
import 'app_notifiers.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

/// Status hasil sinkronisasi Cloud
class SyncResult {
  final bool success;
  final int pantrySynced;
  final int logsSynced;
  final int notifsSynced;
  final String? message;

  const SyncResult({
    required this.success,
    this.pantrySynced = 0,
    this.logsSynced = 0,
    this.notifsSynced = 0,
    this.message,
  });
}

/// Service sinkronisasi dua arah antara database lokal (SQLite) dan Cloud Firestore.
/// Mendukung Offline-First: SQLite tetap menjadi sumber data utama yang cepat,
/// sementara Cloud Firestore menjadi cadangan terpusat dan sinkronisasi multi-perangkat.
class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._internal();
  factory SyncService({DBHelper? db, FirestoreService? firestore}) => instance;
  SyncService._internal();

  final DBHelper _db = DBHelper();
  final FirestoreService _firestore = FirestoreService.instance;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastError;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;

  static const String _keyLastSync = 'last_cloud_sync_timestamp';

  /// Inisialisasi waktu sinkronisasi terakhir dari SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTime = prefs.getString(_keyLastSync);
      if (savedTime != null) {
        _lastSyncTime = DateTime.tryParse(savedTime);
      }
    } catch (_) {}
  }

  /// Backup seluruh data SQLite lokal pengguna ke Cloud Firestore
  Future<SyncResult> backupAllToCloud({String? explicitUid}) async {
    if (_isSyncing) {
      return const SyncResult(success: false, message: 'Sinkronisasi sedang berjalan.');
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final user = await _db.getLoggedInUser();
      final targetUserId = user?.id;
      final uid = explicitUid ??
          AuthService.instance.currentUser?.uid ??
          (targetUserId != null ? 'user_$targetUserId' : null);

      if (uid == null) {
        throw 'Pengguna belum terautentikasi.';
      }

      int pantryCount = 0;
      int logsCount = 0;
      int notifsCount = 0;

      // 1. Profil Pengguna & Eco Points
      if (user != null) {
        await _firestore.saveUserProfile(
          uid: uid,
          email: user.email,
          name: user.name,
          ecoPoints: user.ecoPoints,
          streakCount: user.streakCount,
        );
      }

      // 2. Inventaris Pantry
      final pantryItems = await _db.getPantryItems(userId: targetUserId);
      for (final item in pantryItems) {
        await _firestore.addPantryItem(uid, item);
        pantryCount++;
      }

      // 3. Catatan Makanan Harian
      final foodLogs = await _db.getFoodLogs(userId: targetUserId);
      for (final log in foodLogs) {
        await _firestore.addFoodLog(uid, log);
        logsCount++;
      }

      // 4. Riwayat Notifikasi
      final notifs = await _db.getNotifications(userId: targetUserId);
      for (final notif in notifs) {
        await _firestore.addNotification(uid, notif);
        notifsCount++;
      }

      // 5. Preferensi Notifikasi & Jam Makan
      final prefs = await SharedPreferences.getInstance();
      await _firestore.saveUserPreferences(uid, {
        'expiryAlert': prefs.getBool(AppConstants.keyNotifExpiryAlert) ?? true,
        'nutritionExcess': prefs.getBool(AppConstants.keyNotifNutritionExcess) ?? true,
        'dailyMealLog': prefs.getBool(AppConstants.keyNotifDailyMealLog) ?? true,
        'ecoTips': prefs.getBool(AppConstants.keyNotifEcoTips) ?? true,
        'breakfastEnabled': prefs.getBool(AppConstants.keyNotifBreakfastEnabled) ?? true,
        'breakfastTime': prefs.getString(AppConstants.keyNotifBreakfastTime) ?? '07:30',
        'lunchEnabled': prefs.getBool(AppConstants.keyNotifLunchEnabled) ?? true,
        'lunchTime': prefs.getString(AppConstants.keyNotifLunchTime) ?? '12:30',
        'dinnerEnabled': prefs.getBool(AppConstants.keyNotifDinnerEnabled) ?? true,
        'dinnerTime': prefs.getString(AppConstants.keyNotifDinnerTime) ?? '19:00',
      });

      _lastSyncTime = DateTime.now();
      await prefs.setString(_keyLastSync, _lastSyncTime!.toIso8601String());

      return SyncResult(
        success: true,
        pantrySynced: pantryCount,
        logsSynced: logsCount,
        notifsSynced: notifsCount,
        message: 'Berhasil mencadangkan $pantryCount bahan, $logsCount catatan makan, dan $notifsCount notifikasi ke cloud.',
      );
    } catch (e) {
      _lastError = e.toString();
      return SyncResult(success: false, message: 'Gagal sinkronisasi ke cloud: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Memulihkan data dari Cloud Firestore ke database SQLite lokal
  /// (Sangat berguna saat pengguna login di perangkat baru / instal ulang aplikasi)
  Future<SyncResult> restoreFromCloud({String? explicitUid}) async {
    if (_isSyncing) {
      return const SyncResult(success: false, message: 'Sinkronisasi sedang berjalan.');
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final user = await _db.getLoggedInUser();
      final targetUserId = user?.id;
      final uid = explicitUid ??
          AuthService.instance.currentUser?.uid ??
          (targetUserId != null ? 'user_$targetUserId' : null);

      if (uid == null) {
        throw 'Pengguna belum terautentikasi.';
      }

      int pantryRestored = 0;
      int notifsRestored = 0;

      // 1. Pulihkan Profil & Eco Points
      final cloudProfile = await _firestore.getUserProfile(uid);
      if (cloudProfile != null && user != null) {
        final cloudEcoPoints = (cloudProfile['eco_points'] as num?)?.toInt();
        final cloudStreak = (cloudProfile['streak_count'] as num?)?.toInt();
        if (cloudEcoPoints != null) {
          await EcoPointsNotifier.instance.setPoints(cloudEcoPoints);
        }
        if (cloudStreak != null && user.id != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_streak_${user.id}', cloudStreak);
        }
      }

      // 2. Pulihkan Inventaris Pantry
      final localPantry = await _db.getPantryItems(userId: targetUserId);
      final cloudPantry = await _firestore.getPantryItems(uid);
      for (final cItem in cloudPantry) {
        final alreadyExists = localPantry.any((l) =>
            l.name.toLowerCase() == cItem.name.toLowerCase() &&
            l.storage == cItem.storage &&
            l.expiryDate.year == cItem.expiryDate.year &&
            l.expiryDate.month == cItem.expiryDate.month &&
            l.expiryDate.day == cItem.expiryDate.day);

        if (!alreadyExists) {
          await _db.addPantryItem(cItem.copyWith(userId: targetUserId));
          pantryRestored++;
        }
      }

      // 3. Pulihkan Notifikasi
      final localNotifs = await _db.getNotifications(userId: targetUserId);
      final cloudNotifs = await _firestore.getNotifications(uid);
      for (final cNotif in cloudNotifs) {
        final alreadyExists = localNotifs.any((l) =>
            l.title == cNotif.title &&
            l.createdAt.year == cNotif.createdAt.year &&
            l.createdAt.month == cNotif.createdAt.month &&
            l.createdAt.day == cNotif.createdAt.day);

        if (!alreadyExists) {
          await _db.addNotification(cNotif.copyWith(userId: targetUserId));
          notifsRestored++;
        }
      }

      // 4. Pulihkan Preferensi Notifikasi & Jam Makan
      final cloudPrefs = await _firestore.getUserPreferences(uid);
      if (cloudPrefs != null) {
        final prefs = await SharedPreferences.getInstance();
        if (cloudPrefs.containsKey('expiryAlert')) {
          await prefs.setBool(AppConstants.keyNotifExpiryAlert, cloudPrefs['expiryAlert'] == true);
        }
        if (cloudPrefs.containsKey('nutritionExcess')) {
          await prefs.setBool(AppConstants.keyNotifNutritionExcess, cloudPrefs['nutritionExcess'] == true);
        }
        if (cloudPrefs.containsKey('dailyMealLog')) {
          await prefs.setBool(AppConstants.keyNotifDailyMealLog, cloudPrefs['dailyMealLog'] == true);
        }
        if (cloudPrefs.containsKey('ecoTips')) {
          await prefs.setBool(AppConstants.keyNotifEcoTips, cloudPrefs['ecoTips'] == true);
        }
        if (cloudPrefs.containsKey('breakfastEnabled')) {
          await prefs.setBool(AppConstants.keyNotifBreakfastEnabled, cloudPrefs['breakfastEnabled'] == true);
        }
        if (cloudPrefs.containsKey('breakfastTime')) {
          await prefs.setString(AppConstants.keyNotifBreakfastTime, cloudPrefs['breakfastTime']?.toString() ?? '07:30');
        }
        if (cloudPrefs.containsKey('lunchEnabled')) {
          await prefs.setBool(AppConstants.keyNotifLunchEnabled, cloudPrefs['lunchEnabled'] == true);
        }
        if (cloudPrefs.containsKey('lunchTime')) {
          await prefs.setString(AppConstants.keyNotifLunchTime, cloudPrefs['lunchTime']?.toString() ?? '12:30');
        }
        if (cloudPrefs.containsKey('dinnerEnabled')) {
          await prefs.setBool(AppConstants.keyNotifDinnerEnabled, cloudPrefs['dinnerEnabled'] == true);
        }
        if (cloudPrefs.containsKey('dinnerTime')) {
          await prefs.setString(AppConstants.keyNotifDinnerTime, cloudPrefs['dinnerTime']?.toString() ?? '19:00');
        }
      }

      // Refresh seluruh notifier
      PantryUpdateNotifier.instance.notifyPantryChanged();
      await NotificationNotifier.instance.refresh();
      await EcoPointsNotifier.instance.refresh();

      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSync, _lastSyncTime!.toIso8601String());

      return SyncResult(
        success: true,
        pantrySynced: pantryRestored,
        notifsSynced: notifsRestored,
        message: 'Berhasil memulihkan $pantryRestored bahan dan $notifsRestored notifikasi dari cloud.',
      );
    } catch (e) {
      _lastError = e.toString();
      return SyncResult(success: false, message: 'Gagal memulihkan dari cloud: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
