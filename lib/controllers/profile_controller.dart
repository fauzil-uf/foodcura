import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/user_model.dart';
import '../services/app_notifiers.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';
import '../services/streak_service.dart';
import '../services/sync_service.dart';
import 'mixins/cloud_sync_controller_mixin.dart';

/// Controller profil pengguna, statistik (Eco Points, streak), & pengaturan akun.
class ProfileController extends ChangeNotifier with CloudSyncControllerMixin {
  final DBHelper _db;
  final StreakService _streakService;

  ProfileController({DBHelper? db, StreakService? streakService})
    : _db = db ?? DBHelper(),
      _streakService = streakService ?? StreakService(db: db ?? DBHelper()) {
    initListeners();
  }

  UserModelSQL? _user;
  int _streak = 0;
  int _ecoPoints = 0;
  int _unreadNotifications = 0;
  bool _isLoading = true;
  String? _errorMessage;

  UserModelSQL? get user => _user;
  int get streak => _streak;
  int get ecoPoints => _ecoPoints;
  int get unreadNotifications => _unreadNotifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _onEcoPointsChanged() {
    _ecoPoints = EcoPointsNotifier.instance.value;
    notifyListeners();
  }

  /// Pasang listener perubahan Eco Points real-time
  void initListeners() {
    EcoPointsNotifier.instance.removeListener(_onEcoPointsChanged);
    EcoPointsNotifier.instance.addListener(_onEcoPointsChanged);
    _ecoPoints = EcoPointsNotifier.instance.value;
  }

  /// Lepas listener Eco Points saat controller selesai digunakan
  void removeListeners() {
    EcoPointsNotifier.instance.removeListener(_onEcoPointsChanged);
  }

  @override
  void dispose() {
    cancelCloudSyncSubscription();
    removeListeners();
    super.dispose();
  }

  /// Memulai sinkronisasi otomatis stream profil Cloud Firestore ke SQLite lokal.
  void startCloudSync() {
    initCloudSyncSubscription<Map<String, dynamic>?>(
      streamFactory: (uid) => FirestoreService.instance.streamUserProfile(uid),
      onDataTriggered: () => syncCloudProfile(),
    );
  }

  /// Memuat profil pengguna, kalkulasi streak deterministik, dan jumlah notifikasi.
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _db.getLoggedInUser();
      final streakCount = await _streakService.computeAndSaveStreak(
        userId: user?.id,
      );
      final unread = await _db.getUnreadNotificationCount(userId: user?.id);
      await EcoPointsNotifier.instance.refresh();

      _user = user;
      _streak = streakCount;
      _ecoPoints = EcoPointsNotifier.instance.value;
      _unreadNotifications = unread;
    } catch (e) {
      _errorMessage = 'Gagal memuat profil: $e';
      debugPrint('ProfileController error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Status proses sinkronisasi aktif.
  bool get isSyncing => SyncService.instance.isSyncing;

  /// Waktu sinkronisasi terakhir.
  DateTime? get lastSyncTime => SyncService.instance.lastSyncTime;

  /// Sinkronisasi profil user dari Cloud Firestore ke database lokal.
  Future<bool> syncCloudProfile() async {
    final updated = await SyncService.instance.syncUserProfileFromCloud();
    await loadProfile();
    return updated;
  }

  /// Mencadangkan seluruh data pengguna ke Cloud Firestore.
  Future<SyncResult> backupAllToCloud() async {
    final res = await SyncService.instance.backupAllToCloud();
    await loadProfile();
    return res;
  }

  /// Memulihkan seluruh data pengguna dari Cloud Firestore.
  Future<SyncResult> restoreFromCloud() async {
    final res = await SyncService.instance.restoreFromCloud();
    await loadProfile();
    return res;
  }

  /// Memperbarui nama dan email pengguna
  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty || cleanEmail.isEmpty) {
      _errorMessage = 'Nama dan email tidak boleh kosong!';
      notifyListeners();
      return false;
    }

    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(cleanEmail)) {
      _errorMessage = 'Format email tidak valid!';
      notifyListeners();
      return false;
    }

    if (_user == null) {
      _errorMessage = 'Sesi pengguna tidak ditemukan!';
      notifyListeners();
      return false;
    }

    if (cleanEmail.toLowerCase() != _user!.email.toLowerCase()) {
      final isRegistered = await _db.isEmailRegistered(cleanEmail);
      if (isRegistered) {
        _errorMessage = 'Email sudah digunakan oleh akun lain!';
        notifyListeners();
        return false;
      }
    }

    try {
      final updated = _user!.copyWith(name: cleanName, email: cleanEmail);
      final success = await _db.updateUser(updated);
      if (success) {
        _user = updated;
        _errorMessage = null;
        UserProfileUpdateNotifier.instance.notifyUserChanged();
        notifyListeners();

        // Sinkronisasi profil ke Firestore
        try {
          final uid = AuthService.instance.currentUser?.uid ?? 'user_${_user!.id}';
          await FirestoreService.instance.saveUserProfile(
            uid: uid,
            email: cleanEmail,
            name: cleanName,
            ecoPoints: _ecoPoints,
            streakCount: _streak,
          );
        } catch (e) {
          debugPrint('[ProfileController] Gagal sync profil ke Firestore: $e');
        }
      } else {
        _errorMessage = 'Gagal memperbarui profil ke database.';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui profil: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mengubah password akun pengguna
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      _errorMessage = 'Password baru minimal 8 karakter!';
      notifyListeners();
      return false;
    }

    if (_user == null || _user!.id == null) {
      _errorMessage = 'Sesi pengguna tidak ditemukan!';
      notifyListeners();
      return false;
    }

    try {
      final success = await _db.changePassword(
        userId: _user!.id!,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      if (!success) {
        _errorMessage = 'Password lama tidak sesuai!';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Gagal mengubah password: $e';
      notifyListeners();
      return false;
    }
  }

  /// Logout dan hapus sesi pengguna
  Future<void> logout() async {
    await _db.logoutUser();
    await AuthService.instance.signOut();
    _user = null;
    _streak = 0;
    _ecoPoints = 0;
    _unreadNotifications = 0;
    notifyListeners();
  }

  /// Menyegarkan hitungan notifikasi belum dibaca
  Future<void> refreshNotifications() async {
    if (_user?.id != null) {
      _unreadNotifications = await _db.getUnreadNotificationCount(
        userId: _user!.id,
      );
      notifyListeners();
    }
  }

  /// Memuat konfigurasi preferensi notifikasi dari SharedPreferences
  Future<Map<String, dynamic>> loadNotificationSettings() async {
    return await ReminderService().loadNotificationSettings();
  }

  /// Menyimpan preferensi notifikasi dan jadwal pengingat makan
  Future<void> saveNotificationSettings({
    required bool expiryAlert,
    required bool nutritionExcess,
    required bool dailyMealLog,
    bool ecoTips = false,
    required bool breakfastEnabled,
    required String breakfastTime,
    required bool lunchEnabled,
    required String lunchTime,
    required bool dinnerEnabled,
    required String dinnerTime,
  }) async {
    final reminderService = ReminderService();
    await reminderService.saveNotificationSettings(
      expiryAlert: expiryAlert,
      nutritionExcess: nutritionExcess,
      dailyMealLog: dailyMealLog,
      ecoTips: ecoTips,
      breakfastEnabled: breakfastEnabled,
      breakfastTime: breakfastTime,
      lunchEnabled: lunchEnabled,
      lunchTime: lunchTime,
      dinnerEnabled: dinnerEnabled,
      dinnerTime: dinnerTime,
    );
  }

  /// Memeriksa status izin notifikasi sistem Android OS
  Future<bool> areNotificationsEnabled() async {
    return await NotificationService.instance.areNotificationsEnabled();
  }

  /// Meminta izin notifikasi sistem Android OS
  Future<bool> requestNotificationPermissions() async {
    return await NotificationService.instance.requestPermissions();
  }

  /// Membuka pengaturan notifikasi aplikasi di level OS Android
  Future<void> openNotificationSettings() async {
    await NotificationService.instance.openNotificationSettings();
  }

  /// Memeriksa apakah sistem mengizinkan penjadwalan alarm tepat waktu (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    return await NotificationService.instance.canScheduleExactAlarms();
  }

  /// Membuka pengaturan izin exact alarm di OS Android
  Future<void> openExactAlarmSettings() async {
    await NotificationService.instance.openExactAlarmSettings();
  }

  /// Cek apakah FoodCura dikecualikan dari battery optimization
  Future<bool> isBatteryOptimizationIgnored() async {
    return await NotificationService.instance.isBatteryOptimizationIgnored();
  }

  /// Buka halaman battery optimization (user bisa set FoodCura ke Unrestricted)
  Future<void> openBatteryOptimizationSettings() async {
    await NotificationService.instance.openBatteryOptimizationSettings();
  }
}
