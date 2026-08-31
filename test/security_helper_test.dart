import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/utils/security_helper.dart';

void main() {
  group('SecurityHelper Password Hashing & Verification Tests', () {
    test(
      'hashPassword produces a valid 64-character hexadecimal SHA-256 string',
      () {
        final hash = SecurityHelper.hashPassword('Rahasia123!');
        expect(hash.length, equals(64));
        expect(SecurityHelper.isHashed(hash), isTrue);
      },
    );

    test('hashPassword is deterministic for same input', () {
      final hash1 = SecurityHelper.hashPassword('SuperSecret123');
      final hash2 = SecurityHelper.hashPassword('SuperSecret123');
      expect(hash1, equals(hash2));
    });

    test(
      'hashPassword produces different hashes for different inputs (Salted Avalanche effect)',
      () {
        final hash1 = SecurityHelper.hashPassword('Password123');
        final hash2 = SecurityHelper.hashPassword('Password124');
        expect(hash1, isNot(equals(hash2)));
      },
    );

    test('verifyPassword correctly validates matching hashed passwords', () {
      final plain = 'P@ssw0rdSecure!';
      final hash = SecurityHelper.hashPassword(plain);

      expect(SecurityHelper.verifyPassword(plain, hash), isTrue);
      expect(SecurityHelper.verifyPassword('WrongPassword!', hash), isFalse);
    });

    test(
      'verifyPassword supports backward compatibility for legacy plaintext passwords',
      () {
        final legacyPlain = 'myOldPlainPassword123';

        // Akun lama yang passwordnya masih disimpan plain text di SQLite
        expect(SecurityHelper.verifyPassword(legacyPlain, legacyPlain), isTrue);
        expect(SecurityHelper.verifyPassword('wrong', legacyPlain), isFalse);
        expect(SecurityHelper.isHashed(legacyPlain), isFalse);
      },
    );

    test('verifyPassword handles empty inputs gracefully', () {
      expect(SecurityHelper.verifyPassword('', 'someHash'), isFalse);
      expect(SecurityHelper.verifyPassword('somePass', ''), isFalse);
      expect(SecurityHelper.verifyPassword('', ''), isFalse);
    });

    test('isHashed correctly identifies SHA-256 hex vs plaintext', () {
      final validHash = SecurityHelper.hashPassword('testing123');
      expect(SecurityHelper.isHashed(validHash), isTrue);
      expect(SecurityHelper.isHashed('password123'), isFalse);
      expect(SecurityHelper.isHashed('12345678'), isFalse);
      expect(SecurityHelper.isHashed(''), isFalse);
    });
  });
}
