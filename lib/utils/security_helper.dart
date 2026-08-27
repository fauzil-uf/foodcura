import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utilitas kriptografi dan keamanan untuk autentikasi pengguna FoodCura.
///
/// Menggunakan algoritma SHA-256 dengan kombinasi Salted string
/// untuk mencegah serangan reverse engineering, dictionary attack,
/// dan rainbow table pada database SQLite lokal.
class SecurityHelper {
  SecurityHelper._();

  /// Salt rahasia aplikasi untuk memperkuat keamanan hashing password
  static const String _salt = 'FoodCura_Secured_App_Salt_2026_x9k!';

  /// Pola regex untuk mendeteksi apakah sebuah nilai sudah berupa hash SHA-256 (64 hex characters)
  static final RegExp _sha256Regex = RegExp(r'^[a-f0-9]{64}$', caseSensitive: false);

  /// Menghasilkan hash SHA-256 satu arah yang aman dari kata sandi teks biasa
  static String hashPassword(String password) {
    final bytes = utf8.encode('$_salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Memverifikasi kecocokan antara kata sandi yang diinput pengguna dengan nilai di database.
  ///
  /// Mendukung **backward compatibility**:
  /// - Memverifikasi hash SHA-256 yang valid.
  /// - Mendukung akun legacy (jika sebelumnya tersimpan dalam plain text).
  static bool verifyPassword(String inputPassword, String storedValue) {
    if (inputPassword.isEmpty || storedValue.isEmpty) {
      return false;
    }

    // 1. Cek kecocokan dengan hash SHA-256 standar
    final computedHash = hashPassword(inputPassword);
    if (computedHash == storedValue) {
      return true;
    }

    // 2. Fallback untuk data legacy plaintext (sebelum fitur hashing aktif)
    if (inputPassword == storedValue) {
      return true;
    }

    return false;
  }

  /// Mengecek apakah string di database sudah berupa hash SHA-256 yang aman
  static bool isHashed(String storedValue) {
    return _sha256Regex.hasMatch(storedValue.trim());
  }
}
