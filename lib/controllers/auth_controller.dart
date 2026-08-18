import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';

/// Controller untuk mengelola state dan business logic autentikasi serta sesi pengguna.
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

  /// Memuat profil pengguna yang sedang login dari session lokal
  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _db.getLoggedInUser();
    } catch (e) {
      _errorMessage = 'Gagal memuat profil pengguna: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Melakukan login dengan email dan password
  Future<bool> login(String email, String password) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      _errorMessage = 'Isi semua field!';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _db.loginUser(cleanEmail, password);
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Login gagal! Email atau password salah.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat login: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mendaftarkan akun baru
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty ||
        cleanEmail.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _errorMessage = 'Isi semua field!';
      notifyListeners();
      return false;
    }

    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(cleanEmail)) {
      _errorMessage = 'Format email tidak valid!';
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      _errorMessage = 'Password minimal 6 karakter!';
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Konfirmasi password tidak cocok!';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = UserModelSQL(
        name: cleanName,
        email: cleanEmail,
        password: password,
      );
      final success = await _db.registerUser(newUser);

      _isLoading = false;
      if (success) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Email sudah terdaftar!';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Gagal mendaftar: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui informasi nama dan email pengguna
  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    if (_currentUser == null) return false;
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty || cleanEmail.isEmpty) {
      _errorMessage = 'Nama dan email tidak boleh kosong!';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final updated = _currentUser!.copyWith(
        name: cleanName,
        email: cleanEmail,
      );
      final success = await _db.updateUser(updated);
      if (success) {
        _currentUser = updated;
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui profil: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mengeluarkan pengguna dan menghapus sesi tersimpan
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyLoggedInUserId);
    await prefs.remove(AppConstants.keyStreakCount);
    await prefs.remove(AppConstants.keyStreakLastDate);
    _currentUser = null;
    notifyListeners();
  }

  /// Mengecek apakah email sudah terdaftar
  Future<bool> isEmailRegistered(String email) async {
    return await _db.isEmailRegistered(email.trim());
  }
}
