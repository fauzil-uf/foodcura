import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/user_model.dart';

/// Controller untuk mengelola state autentikasi dan sesi pengguna.
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

    _setLoading(true);
    try {
      final user = await _db.loginUser(cleanEmail, password);
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      }
      _setLoading(false, 'Login gagal! Email atau password salah.');
      return false;
    } catch (e) {
      _setLoading(false, 'Terjadi kesalahan saat login: $e');
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
    if (cleanName.isEmpty || cleanEmail.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
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
  Future<bool> updateProfile({required String name, required String email}) async {
    if (_currentUser == null) return false;
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty || cleanEmail.isEmpty) {
      _setLoading(false, 'Nama dan email tidak boleh kosong!');
      return false;
    }

    _setLoading(true);
    try {
      final updated = _currentUser!.copyWith(name: cleanName, email: cleanEmail);
      final success = await _db.updateUser(updated);
      if (success) _currentUser = updated;
      _setLoading(false);
      return success;
    } catch (e) {
      _setLoading(false, 'Gagal memperbarui profil: $e');
      return false;
    }
  }

  /// Mengeluarkan pengguna dan membersihkan sesi lokal
  Future<void> logout() async {
    await _db.logoutUser();
    _currentUser = null;
    notifyListeners();
  }

  /// Mengecek apakah email terdaftar
  Future<bool> isEmailRegistered(String email) => _db.isEmailRegistered(email.trim());
}
