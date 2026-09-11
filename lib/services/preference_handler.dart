import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Helper SharedPreferences untuk session login & preferensi lokal
class PreferenceHandler {
  PreferenceHandler._();

  static late SharedPreferences _prefs;

  /// Inisialisasi SharedPreferences saat start aplikasi
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- AUTH & LOGIN SESSION ---

  /// Simpan user ID yang sedang login
  static Future<void> setLoggedInUserId(int id) async {
    await _prefs.setInt(AppConstants.keyLoggedInUserId, id);
  }

  // Ambil user ID yang sedang aktif
  static int? get loggedInUserId =>
      _prefs.getInt(AppConstants.keyLoggedInUserId);

  // Cek apakah user sudah login
  static bool get isLogin =>
      _prefs.getInt(AppConstants.keyLoggedInUserId) != null;

  /// Hapus session login (logout)
  static Future<void> logout() async {
    await _prefs.remove(AppConstants.keyLoggedInUserId);
  }

  // --- ONBOARDING PREFERENCE ---

  /// Simpan status onboarding sudah dilihat
  static Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool('hasSeenOnboarding', value);
  }

  // Cek apakah onboarding sudah dilihat
  static bool get hasSeenOnboarding =>
      _prefs.getBool('hasSeenOnboarding') ?? false;

  static SharedPreferences get prefs => _prefs;
}
