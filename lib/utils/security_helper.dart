import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Helper hashing & verifikasi password (SHA-256 + salt)
class SecurityHelper {
  SecurityHelper._();

  static const String _salt = 'FoodCura_Secured_App_Salt_2026_x9k!';

  static final RegExp _sha256Regex = RegExp(
    r'^[a-f0-9]{64}$',
    caseSensitive: false,
  );

  /// Hash password dengan SHA-256 + salt
  static String hashPassword(String password) {
    final bytes = utf8.encode('$_salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifikasi kecocokan password input dengan nilai di database (support legacy)
  static bool verifyPassword(String inputPassword, String storedValue) {
    if (inputPassword.isEmpty || storedValue.isEmpty) {
      return false;
    }

    // Keamanan: Marker akun OAuth tidak boleh pernah cocok dengan input password pengguna
    if (storedValue == 'google_oauth_user' ||
        storedValue.startsWith('GOOGLE_OAUTH_') ||
        storedValue.startsWith('GOOGLE_AUTH_')) {
      return false;
    }

    final computedHash = hashPassword(inputPassword);
    if (computedHash == storedValue) {
      return true;
    }

    // Fallback data legacy plaintext
    if (inputPassword == storedValue) {
      return true;
    }

    return false;
  }

  /// Cek apakah string sudah berbentuk hash SHA-256
  static bool isHashed(String storedValue) {
    return _sha256Regex.hasMatch(storedValue.trim());
  }
}
