import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/controllers/profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProfileController tests', () {
    test('Initial state has default values', () {
      final controller = ProfileController();
      expect(controller.user, isNull);
      expect(controller.streak, equals(0));
      expect(controller.ecoPoints, equals(0));
      expect(controller.unreadNotifications, equals(0));
      expect(controller.isLoading, isTrue);
      expect(controller.errorMessage, isNull);
    });

    test('Validation on empty update profile fields returns false', () async {
      final controller = ProfileController();
      final result = await controller.updateProfile(name: '', email: '');
      expect(result, isFalse);
      expect(controller.errorMessage, isNotNull);
    });

    test('Validation on short password change returns false', () async {
      final controller = ProfileController();
      final result = await controller.changePassword(
        oldPassword: 'old',
        newPassword: 'short',
      );
      expect(result, isFalse);
      expect(controller.errorMessage, contains('8 karakter'));
    });
  });
}
