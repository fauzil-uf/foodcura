import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/user_model.dart';
import '../services/streak_service.dart';

/// Controller untuk mengelola data profil, statistik bento (Eco Points, Streak),
/// pengaturan keamanan/password, dan unread notifikasi pengguna.
class ProfileController extends ChangeNotifier {
  final DBHelper _db;
  final StreakService _streakService;

  ProfileController({DBHelper? db, StreakService? streakService})
      : _db = db ?? DBHelper(),
        _streakService = streakService ?? StreakService(db: db ?? DBHelper());

  UserModelSQL? _user;
  int _streak = 0;
  int _ecoPoints = 0;
  int _unreadNotifications = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // Getters
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

  /// Inisialisasi listener real-time Eco Points
  void initListeners() {
    EcoPointsNotifier.instance.addListener(_onEcoPointsChanged);
    _ecoPoints = EcoPointsNotifier.instance.value;
  }

  /// Membersihkan listener saat controller di-dispose
  void removeListeners() {
    EcoPointsNotifier.instance.removeListener(_onEcoPointsChanged);
  }

  @override
  void dispose() {
    removeListeners();
    super.dispose();
  }

  /// Memuat profil pengguna, kalkulasi streak deterministik, dan jumlah notifikasi
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _db.getLoggedInUser();
      final streakCount = await _streakService.computeAndSaveStreak(userId: user?.id);
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

  /// Memperbarui nama dan email pengguna
  Future<bool> updateProfile({required String name, required String email}) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty || cleanEmail.isEmpty) {
      _errorMessage = 'Nama dan email tidak boleh kosong!';
      notifyListeners();
      return false;
    }

    if (_user == null) {
      _errorMessage = 'Sesi pengguna tidak ditemukan!';
      notifyListeners();
      return false;
    }

    try {
      final updated = _user!.copyWith(name: cleanName, email: cleanEmail);
      final success = await _db.updateUser(updated);
      if (success) {
        _user = updated;
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
    _user = null;
    _streak = 0;
    _ecoPoints = 0;
    _unreadNotifications = 0;
    notifyListeners();
  }

  /// Menyegarkan hitungan notifikasi belum dibaca
  Future<void> refreshNotifications() async {
    if (_user?.id != null) {
      _unreadNotifications = await _db.getUnreadNotificationCount(userId: _user!.id);
      notifyListeners();
    }
  }
}
