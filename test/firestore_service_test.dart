import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/models/food_item_model.dart';
import 'package:foodcura/models/food_log_model.dart';
import 'package:foodcura/models/pantry_item_model.dart';
import 'package:foodcura/models/user_model.dart';
import 'package:foodcura/services/firestore_service.dart';

void main() {
  group('Firestore Models & Serialization Tests', () {
    test('FoodItemModel toFirestore serialization retains core nutrition fields', () {
      const food = FoodItemModel(
        id: 101,
        name: 'Nasi Merah',
        calories: 149,
        protein: 2.8,
        carbs: 32.5,
        fat: 0.9,
        category: 'Karbohidrat',
        imagePath: 'assets/images/nasi_merah.png',
      );

      final map = food.toFirestore();
      expect(map['id'], 101);
      expect(map['name'], 'Nasi Merah');
      expect(map['calories'], 149);
      expect(map['protein'], 2.8);
      expect(map['carbs'], 32.5);
      expect(map['fat'], 0.9);
      expect(map['category'], 'Karbohidrat');
      expect(map['image_path'], 'assets/images/nasi_merah.png');
    });

    test('PantryItemModel toFirestore serialization formats date and booleans accurately', () {
      final now = DateTime(2026, 9, 8, 12, 0);
      final item = PantryItemModel(
        id: 1,
        userId: 99,
        name: 'Bayam Segar',
        quantity: 2.0,
        unit: 'ikat',
        storage: 'Chiller',
        expiryDate: now.add(const Duration(days: 3)),
        isUsed: false,
        createdAt: now,
      );

      final map = item.toFirestore();
      expect(map['name'], 'Bayam Segar');
      expect(map['quantity'], 2.0);
      expect(map['unit'], 'ikat');
      expect(map['storage'], 'Chiller');
      expect(map['is_used'], false);
      expect(map['expiry_date'], contains('2026-09-11'));
      expect(map['created_at'], contains('2026-09-08'));
    });

    test('FoodLogModel toFirestore serialization handles macronutrients and note', () {
      const log = FoodLogModel(
        id: 5,
        userId: 99,
        foodName: 'Ayam Panggang',
        mealType: 'Makan Siang',
        calories: 280,
        protein: 31.0,
        carbs: 0.0,
        fat: 14.5,
        imagePath: 'assets/images/ayam_panggang.png',
        time: '12:30',
        date: '2026-09-08',
        note: 'Tanpa kulit',
      );

      final map = log.toFirestore();
      expect(map['food_name'], 'Ayam Panggang');
      expect(map['meal_type'], 'Makan Siang');
      expect(map['calories'], 280);
      expect(map['protein'], 31.0);
      expect(map['carbs'], 0.0);
      expect(map['fat'], 14.5);
      expect(map['date'], '2026-09-08');
      expect(map['note'], 'Tanpa kulit');
    });

    test('UserModelSQL toFirestore serialization handles Firebase UID and eco points', () {
      const user = UserModelSQL(
        id: 1,
        name: 'Fauzil',
        email: 'fauzil@example.com',
        password: 'hashed_password',
        firebaseUid: 'firebase_uid_12345',
        ecoPoints: 450,
        streakCount: 12,
        createdAt: '2026-08-01',
      );

      final map = user.toFirestore();
      expect(map['uid'], 'firebase_uid_12345');
      expect(map['name'], 'Fauzil');
      expect(map['email'], 'fauzil@example.com');
      expect(map['eco_points'], 450);
      expect(map['streak_count'], 12);
      expect(map['created_at'], '2026-08-01');
      // Password must NEVER be exported to Firestore
      expect(map.containsKey('password'), isFalse);
    });

    test('FirestoreService singleton instance initializes gracefully in test environment', () {
      final service = FirestoreService.instance;
      expect(service, isNotNull);
      // In standalone unit tests without Firebase core initialized, calls degrade gracefully
      expect(service.isAvailable, isFalse);
    });
  });
}
