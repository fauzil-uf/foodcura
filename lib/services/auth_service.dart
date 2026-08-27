import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Layanan untuk mengelola integrasi Firebase Authentication dan Google Sign-In.
class AuthService {
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '767149958522-7spce6nk3sl942m4d3c0506rimaqh1ui.apps.googleusercontent.com',
  );

  /// Pengguna Firebase yang saat ini sedang aktif
  User? get currentUser => _auth?.currentUser;

  /// Stream untuk memantau perubahan status autentikasi pengguna
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  /// Mengirimkan tautan reset kata sandi ke email pengguna via Firebase Auth
  Future<void> sendPasswordReset(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      throw 'Masukkan alamat email terlebih dahulu.';
    }

    final auth = _auth;
    if (auth == null) {
      throw 'Firebase belum diinisialisasi.';
    }

    try {
      await auth.sendPasswordResetEmail(email: cleanEmail);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw 'Email ini tidak terdaftar di sistem.';
        case 'invalid-email':
          throw 'Format alamat email tidak valid.';
        case 'network-request-failed':
          throw 'Koneksi internet bermasalah. Periksa jaringan Anda.';
        default:
          throw e.message ?? 'Gagal mengirim email reset kata sandi.';
      }
    } catch (e) {
      throw 'Terjadi kesalahan saat memproses permintaan reset: $e';
    }
  }

  /// Menjalankan alur autentikasi Google Sign-In dan menghubungkannya dengan Firebase
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Memulai dialog interaktif Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Pengguna membatalkan dialog sign-in
        return null;
      }

      // 2. Mengambil token otorisasi dari akun Google yang dipilih
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Membuat kredensial otentikasi Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Masuk ke Firebase menggunakan kredensial Google
      final auth = _auth;
      if (auth == null) {
        throw 'Firebase belum diinisialisasi.';
      }
      return await auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw 'Akun sudah terdaftar dengan metode autentikasi lain.';
        case 'invalid-credential':
          throw 'Kredensial Google kadaluarsa atau tidak valid.';
        case 'network-request-failed':
          throw 'Koneksi internet bermasalah. Periksa jaringan Anda.';
        default:
          throw e.message ?? 'Gagal masuk dengan Google.';
      }
    } catch (e) {
      throw 'Gagal melakukan Google Sign-In: $e';
    }
  }

  /// Melakukan sign-out dari Firebase dan akun Google serta memutus cache akun
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    try {
      await _auth?.signOut();
    } catch (_) {}
  }
}
