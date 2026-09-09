import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/constants/app_constants.dart';
import 'package:foodcura/controllers/food_info_controller.dart';
import 'package:foodcura/models/article_model.dart';
import 'package:foodcura/models/notification_model.dart';
import 'package:foodcura/services/app_notifiers.dart';
import 'package:foodcura/services/firestore_service.dart';
import 'package:foodcura/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyLoggedInUserId: 1,
      'last_cloud_sync_timestamp': '2026-09-09T08:00:00.000',
    });
  });

  group('FirestoreService Tests', () {
    test('Firestore collection names and constants are correctly defined', () {
      expect(FirestoreService.colFoods, equals('foods'));
      expect(FirestoreService.colUsers, equals('users'));
      expect(FirestoreService.colPantryItems, equals('pantry_items'));
      expect(FirestoreService.colFoodLogs, equals('food_logs'));
      expect(FirestoreService.colNotifications, equals('notifications'));
      expect(FirestoreService.colArticles, equals('articles'));
    });

    test('FirestoreService handles uninitialized Firebase gracefully', () async {
      final service = FirestoreService.instance;
      // Di test environment tanpa mock FirebaseCore, isAvailable harus false atau ditangani aman
      final foods = await service.getFoods();
      expect(foods, isEmpty);

      final articles = await service.getArticles();
      expect(articles, isEmpty);

      final notifs = await service.getNotifications('test_uid');
      expect(notifs, isEmpty);

      final profile = await service.getUserProfile('test_uid');
      expect(profile, isNull);

      final prefs = await service.getUserPreferences('test_uid');
      expect(prefs, isNull);
    });
  });

  group('SyncService Tests', () {
    test('SyncService initializes last sync timestamp properly from SharedPreferences', () async {
      final sync = SyncService.instance;
      await sync.init();

      expect(sync.lastSyncTime, isNotNull);
      expect(sync.lastSyncTime?.year, equals(2026));
      expect(sync.lastSyncTime?.month, equals(9));
      expect(sync.lastSyncTime?.day, equals(9));
      expect(sync.isSyncing, isFalse);
    });

    test('SyncResult holds correct state attributes', () {
      const result = SyncResult(
        success: true,
        pantrySynced: 5,
        logsSynced: 3,
        notifsSynced: 2,
        message: 'Berhasil mencadangkan data',
      );

      expect(result.success, isTrue);
      expect(result.pantrySynced, equals(5));
      expect(result.logsSynced, equals(3));
      expect(result.notifsSynced, equals(2));
      expect(result.message, equals('Berhasil mencadangkan data'));
    });
  });

  group('EcoPointsNotifier setPoints Tests', () {
    test('setPoints updates SharedPreferences and notifies listeners', () async {
      final notifier = EcoPointsNotifier.instance;
      await notifier.init();

      await notifier.setPoints(150);
      expect(notifier.value, equals(150));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('user_eco_points_1'), equals(150));
    });
  });

  group('FoodInfoController Cloud Fallback Tests', () {
    test('FoodInfoController loads fallback articles when offline', () {
      final controller = FoodInfoController();
      expect(controller.articles, isNotEmpty);
      expect(controller.filteredArticles, isNotEmpty);
      expect(controller.featuredArticle, isNotNull);
      expect(controller.featuredArticle?.title, isNotEmpty);
      expect(controller.latestArticles, isNotEmpty);
    });

    test('FoodInfoController filters categories correctly', () {
      final controller = FoodInfoController();

      // Kategori 1: GIZI & NUTRISI
      controller.setCategory(1);
      for (final a in controller.filteredArticles) {
        expect(a.category == 'GIZI' || a.category == 'NUTRISI', isTrue);
      }

      // Kategori 2: FOOD WASTE
      controller.setCategory(2);
      for (final a in controller.filteredArticles) {
        expect(a.category, equals('FOOD WASTE'));
      }
    });

    test('FoodInfoController search filters titles and summaries', () {
      final controller = FoodInfoController();
      controller.setSearchQuery('piring');
      expect(controller.filteredArticles.any((a) => a.title.toLowerCase().contains('piring')), isTrue);
    });
  });

  group('Notification Model & Deterministic ID Tests', () {
    test('NotificationModel serializes correctly with optional id and read status', () {
      final notif = NotificationModel(
        id: 42,
        title: 'Bahan Segera Kedaluwarsa',
        message: 'Tomat akan kedaluwarsa dalam 2 hari',
        type: 'expiry_warning',
        iconType: 'warning',
        isRead: false,
        relatedPantryId: 10,
        createdAt: DateTime(2026, 9, 9, 8, 30),
      );

      final map = notif.toMap();
      expect(map['id'], equals(42));
      expect(map['title'], equals('Bahan Segera Kedaluwarsa'));
      expect(map['is_read'], equals(0));
      expect(map['related_pantry_id'], equals(10));

      final restored = NotificationModel.fromMap(map);
      expect(restored.id, equals(42));
      expect(restored.title, equals('Bahan Segera Kedaluwarsa'));
      expect(restored.isRead, isFalse);
    });
  });
}
