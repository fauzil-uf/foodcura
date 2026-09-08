import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/preference_handler.dart';

// Controller state autentikasi (login, register, logout, session user)
class AuthController extends ChangeNotifier {
  final DBHelper _db;

  AuthController({DBHelper? db}) : _db = db ?? DBHelper();

  UserModelSQL? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModelSQL? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  void _setLoading(bool value, [String? error]) {
    _isLoading = value;
    _errorMessage = error;
    notifyListeners();
  }

  /// Memuat profil pengguna dari session lokal
  Future<void> loadCurrentUser() async {
    _setLoading(true);
    try {
      _currentUser = await _db.getLoggedInUser();
      _setLoading(false);
    } catch (e) {
      _setLoading(false, 'Gagal memuat profil pengguna: $e');
    }
  }

  /// Melakukan login pengguna
  Future<bool> login(String email, String password) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      _setLoading(false, 'Isi semua field!');
      return false;
    }

    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(cleanEmail)) {
      _setLoading(false, 'Format email tidak valid!');
      return false;
    }

    _setLoading(true);
    try {
      // 1. Coba verifikasi login ke database SQLite lokal
      var user = await _db.loginUser(cleanEmail, password);
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        try {
          final uid = AuthService.instance.currentUser?.uid ?? 'user_${user.id}';
          FirestoreService.instance.saveUserProfile(
            uid: uid,
            email: user.email,
            name: user.name,
          ).ignore();
        } catch (_) {}
        return true;
      }

      // 2. Jika verifikasi lokal gagal, periksa apakah password baru saja di-reset via email Firebase
      final fbCred = await AuthService.instance.signInWithEmailPassword(
        email: cleanEmail,
        password: password,
      );
      if (fbCred != null && fbCred.user != null) {
        // Password baru di Firebase valid! Sinkronkan kata sandi baru ke SQLite lokal
        await _db.updatePasswordForEmail(cleanEmail, password);
        user = await _db.loginUser(cleanEmail, password);
        if (user != null) {
          _currentUser = user;
          _setLoading(false);
          try {
            FirestoreService.instance.saveUserProfile(
              uid: fbCred.user!.uid,
              email: user.email,
              name: user.name,
            ).ignore();
          } catch (_) {}
          return true;
        }
      }

      _setLoading(false, 'Login gagal! Email atau password salah.');
      return false;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _setLoading(false, msg);
      return false;
    }
  }

  /// Mendaftarkan akun baru dengan validasi format email dan kata sandi
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    // Validasi kelengkapan form pendaftaran.
    if (cleanName.isEmpty ||
        cleanEmail.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _setLoading(false, 'Isi semua field!');
      return false;
    }
    // Validasi sintaks alamat email dengan pola regular expression standar.
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(cleanEmail)) {
      _setLoading(false, 'Format email tidak valid!');
      return false;
    }
    // Validasi panjang minimum kata sandi untuk keamanan akun.
    if (password.length < 8) {
      _setLoading(false, 'Password minimal 8 karakter!');
      return false;
    }
    // Validasi kecocokan kata sandi dengan kolom konfirmasi.
    if (password != confirmPassword) {
      _setLoading(false, 'Konfirmasi password tidak cocok!');
      return false;
    }

    _setLoading(true);
    try {
      // Simpan kredensial pengguna baru ke tabel users di SQLite.
      final success = await _db.registerUser(
        UserModelSQL(name: cleanName, email: cleanEmail, password: password),
      );
      if (success) {
        // Daftarkan juga ke Firebase Auth agar fitur Lupa Password via email berfungsi
        try {
          final fbCred = await AuthService.instance.createFirebaseUser(
            email: cleanEmail,
            password: password,
          );
          if (fbCred?.user != null) {
            FirestoreService.instance.saveUserProfile(
              uid: fbCred!.user!.uid,
              email: cleanEmail,
              name: cleanName,
            ).ignore();
          }
        } catch (_) {}

        _setLoading(false);
        return true;
      }
      _setLoading(false, 'Email sudah terdaftar!');
      return false;
    } catch (e) {
      _setLoading(false, 'Gagal mendaftar: $e');
      return false;
    }
  }

  /// Memperbarui nama dan email profil pengguna
  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    if (_currentUser == null) return false;
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty || cleanEmail.isEmpty) {
      _setLoading(false, 'Nama dan email tidak boleh kosong!');
      return false;
    }

    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(cleanEmail)) {
      _setLoading(false, 'Format email tidak valid!');
      return false;
    }

    if (cleanEmail.toLowerCase() != _currentUser!.email.toLowerCase()) {
      final isRegistered = await _db.isEmailRegistered(cleanEmail);
      if (isRegistered) {
        _setLoading(false, 'Email sudah digunakan oleh akun lain!');
        return false;
      }
    }

    _setLoading(true);
    try {
      final updated = _currentUser!.copyWith(
        name: cleanName,
        email: cleanEmail,
      );
      final success = await _db.updateUser(updated);
      if (success) {
        _currentUser = updated;
        try {
          final uid = AuthService.instance.currentUser?.uid ?? 'user_${updated.id}';
          FirestoreService.instance.saveUserProfile(
            uid: uid,
            email: updated.email,
            name: updated.name,
          ).ignore();
        } catch (_) {}
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setLoading(false, 'Gagal memperbarui profil: $e');
      return false;
    }
  }

  /// Mengubah password akun pengguna
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null || _currentUser!.id == null) return false;
    if (newPassword.length < 8) {
      _setLoading(false, 'Password baru minimal 8 karakter!');
      return false;
    }

    _setLoading(true);
    try {
      final success = await _db.changePassword(
        userId: _currentUser!.id!,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      if (!success) {
        _setLoading(false, 'Password lama tidak sesuai!');
        return false;
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false, 'Gagal mengubah password: $e');
      return false;
    }
  }

  /// Mengeluarkan pengguna dan membersihkan sesi lokal serta Firebase
  Future<void> logout() async {
    await _db.logoutUser();
    await AuthService.instance.signOut();
    await NotificationService.instance.cancelAllNotifications();
    _currentUser = null;
    notifyListeners();
  }

  /// Masuk menggunakan akun Google via Firebase Auth dan menyinkronkan dengan SQLite lokal
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (credential == null || credential.user == null) {
        _setLoading(false);
        return false;
      }

      final fbUser = credential.user!;
      final email = fbUser.email ?? '';
      final name =
          fbUser.displayName ??
          (email.isNotEmpty ? email.split('@').first : 'Pengguna FoodCura');

      if (email.isEmpty) {
        _setLoading(false, 'Gagal mengambil email dari akun Google.');
        return false;
      }

      final user = await _db.findOrCreateGoogleUser(
        email,
        name,
        creationTime: fbUser.metadata.creationTime,
      );
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        try {
          FirestoreService.instance.saveUserProfile(
            uid: fbUser.uid,
            email: email,
            name: name,
          ).ignore();
        } catch (_) {}
        return true;
      }

      _setLoading(false, 'Gagal menyinkronkan akun dengan database.');
      return false;
    } catch (e) {
      _setLoading(false, e.toString());
      return false;
    }
  }

  /// Mengirimkan tautan reset kata sandi ke email pengguna
  Future<bool> sendPasswordReset(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      _setLoading(false, 'Masukkan alamat email terlebih dahulu!');
      return false;
    }

    _setLoading(true);
    try {
      // 1. Cek apakah email terdaftar di database FoodCura
      final user = await _db.getUserByEmail(cleanEmail);
      if (user == null) {
        _setLoading(false, 'Email ini belum terdaftar di FoodCura.');
        return false;
      }

      // 2. Jika akun Google, arahkan untuk login via Google
      if (user.isGoogleAccount) {
        _setLoading(
          false,
          'Akun ini terhubung via Google Sign-In. Silakan masuk menggunakan tombol "Lanjutkan dengan Google".',
        );
        return false;
      }

      // 3. Kirim link reset password ke email via Firebase Auth
      await AuthService.instance.sendPasswordReset(cleanEmail);
      _setLoading(false);
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _setLoading(false, msg);
      return false;
    }
  }

  /// Mengecek apakah email terdaftar
  Future<bool> isEmailRegistered(String email) =>
      _db.isEmailRegistered(email.trim());

  /// Menandai bahwa pengguna telah menyelesaikan alur orientasi (onboarding)
  Future<void> completeOnboarding() async {
    await PreferenceHandler.setHasSeenOnboarding(true);
  }

  /// Status apakah pengguna telah melewati orientasi awal
  bool get hasSeenOnboarding => PreferenceHandler.hasSeenOnboarding;

  /// Mereset status orientasi awal (misal untuk pendaftaran baru)
  Future<void> resetOnboarding() async {
    await PreferenceHandler.setHasSeenOnboarding(false);
  }
}
