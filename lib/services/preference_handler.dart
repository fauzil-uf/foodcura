import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Pengelola SharedPreferences terpusat sesuai standar kurikulum Local Storage.
///
/// Digunakan untuk menyimpan data kecil seperti status login, user id aktif,
/// dan preferensi aplikasi antar sesi.
class PreferenceHandler {
  PreferenceHandler._();

  static late SharedPreferences _prefs;

  /// Inisialisasi SharedPreferences sekali di main.dart sebelum runApp()
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- AUTH & LOGIN SESSION ---

  /// Menyimpan ID pengguna yang sedang login
  static Future<void> setLoggedInUserId(int id) async {
    await _prefs.setInt(AppConstants.keyLoggedInUserId, id);
  }

  /// Mengambil ID pengguna yang sedang aktif (null jika belum login)
  static int? get loggedInUserId => _prefs.getInt(AppConstants.keyLoggedInUserId);

  /// Status apakah ada user yang sedang login
  static bool get isLogin => _prefs.getInt(AppConstants.keyLoggedInUserId) != null;

  /// Menghapus sesi login saat pengguna logout
  static Future<void> logout() async {
    await _prefs.remove(AppConstants.keyLoggedInUserId);
  }

  // --- ONBOARDING PREFERENCE ---

  /// Menyimpan status apakah user sudah melihat onboarding
  static Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool('hasSeenOnboarding', value);
  }

  /// Mengecek apakah onboarding sudah pernah dilihat
  static bool get hasSeenOnboarding => _prefs.getBool('hasSeenOnboarding') ?? false;

  /// Mengambil jumlah hari beruntun (streak) mencatat makanan milik pengguna.
  static int getStreak(int userId) {
    return _prefs.getInt('user_streak_$userId') ?? 0;
  }

  /// Memperbarui jumlah hari beruntun (streak) pengguna ke SharedPreferences.
  static Future<void> setStreak(int userId, int streak) async {
    await _prefs.setInt('user_streak_$userId', streak);
  }

  static SharedPreferences get prefs => _prefs;
}
