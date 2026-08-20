import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/controllers/auth_controller.dart';
import 'package:foodcura/controllers/dashboard_controller.dart';
import 'package:foodcura/controllers/food_tracker_controller.dart';
import 'package:foodcura/controllers/notification_controller.dart';
import 'package:foodcura/controllers/pantry_controller.dart';
import 'package:foodcura/controllers/quiz_controller.dart';
import 'package:foodcura/models/food_item_model.dart';
import 'package:foodcura/models/food_log_model.dart';
import 'package:foodcura/models/notification_model.dart';
import 'package:foodcura/models/pantry_item_model.dart';
import 'package:foodcura/models/quiz_model.dart';
import 'package:foodcura/services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock test for GeminiService
class FakeGeminiService implements GeminiService {
  @override
  Future<List<QuizQuestion>> generateQuiz() async {
    return const [
      QuizQuestion(
        id: 1,
        question: 'Apa fungsi utama karbohidrat bagi tubuh?',
        options: [
          'Sumber energi utama',
          'Membentuk antibodi',
          'Melarutkan vitamin',
          'Mendinginkan suhu',
        ],
        correctAnswerIndex: 0,
        explanation: 'Karbohidrat adalah sumber energi utama tubuh.',
      ),
      QuizQuestion(
        id: 2,
        question: 'Berapa batas konsumsi kolesterol harian yang dianjurkan?',
        options: ['1000 mg', '500 mg', '300 mg', '50 mg'],
        correctAnswerIndex: 2,
        explanation: 'Batas harian kolesterol umumnya 300 mg.',
      ),
    ];
  }

  @override
  Future<String> evaluateDailyNutrition({
    required int calories,
    required double protein,
    required double carbs,
    double fat = 0,
    double saturatedFat = 0,
    required double cholesterol,
  }) async {
    return 'Mock AI Advice: Pola makanmu hari ini sangat baik dan seimbang.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthController initial state and validation tests', () {
    test('Initial state is not authenticated and not loading', () {
      final auth = AuthController();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.isLoading, isFalse);
      expect(auth.errorMessage, isNull);
    });

    test('Register rejects empty fields and invalid email', () async {
      final auth = AuthController();
      final res1 = await auth.register(
        name: '',
        email: '',
        password: '',
        confirmPassword: '',
      );
      expect(res1, isFalse);
      expect(auth.errorMessage, contains('Isi semua field'));

      final res2 = await auth.register(
        name: 'User',
        email: 'invalid-email',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(res2, isFalse);
      expect(auth.errorMessage, contains('Format email tidak valid'));

      final res3 = await auth.register(
        name: 'User',
        email: 'user@example.com',
        password: '123',
        confirmPassword: '123',
      );
      expect(res3, isFalse);
      expect(auth.errorMessage, contains('minimal 8 karakter'));

      final res4 = await auth.register(
        name: 'User',
        email: 'user@example.com',
        password: 'password123',
        confirmPassword: 'differentpassword',
      );
      expect(res4, isFalse);
      expect(auth.errorMessage, contains('Konfirmasi password tidak cocok'));
    });

    test('Logout clears session and user state', () async {
      SharedPreferences.setMockInitialValues({'logged_in_user_id': 1});
      final auth = AuthController();
      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('logged_in_user_id'), isNull);
    });
  });

  group('DashboardController and AI Nutrition Coach tests', () {
    test('Initial dashboard state and AI advice fetching', () async {
      final fakeGemini = FakeGeminiService();
      final dashCtrl = DashboardController(gemini: fakeGemini);

      expect(dashCtrl.aiNutritionAdvice, isNull);
      expect(dashCtrl.isAiAdviceLoading, isFalse);

      await dashCtrl.fetchAiNutritionAdvice();

      expect(dashCtrl.isAiAdviceLoading, isFalse);
      expect(dashCtrl.aiNutritionAdvice, contains('Mock AI Advice'));
    });
  });

  group('FoodTrackerController tests', () {
    test('Initial tabs and selection', () {
      final tracker = FoodTrackerController();
      expect(tracker.tabs.length, equals(5));
      expect(tracker.currentTabName, equals('Semua'));
      expect(tracker.totalCalories, equals(0));
      expect(tracker.totalProtein, equals(0.0));
      expect(tracker.totalCarbs, equals(0.0));
      expect(tracker.totalFat, equals(0.0));
      expect(tracker.totalCholesterol, equals(0.0));

      tracker.setSelectedTab(1);
      expect(tracker.selectedTabIndex, equals(1));
      expect(tracker.currentTabName, equals('Sarapan'));
    });

    test('Date navigation and relative labels', () {
      final tracker = FoodTrackerController();
      expect(tracker.isToday, isTrue);
      expect(tracker.isYesterday, isFalse);
      expect(tracker.dateDisplayLabel, contains('Hari Ini'));

      tracker.setYesterday();
      expect(tracker.isToday, isFalse);
      expect(tracker.isYesterday, isTrue);
      expect(tracker.dateDisplayLabel, contains('Kemarin'));

      tracker.setToday();
      expect(tracker.isToday, isTrue);
      expect(tracker.isYesterday, isFalse);

      tracker.previousDay();
      expect(tracker.isYesterday, isTrue);

      tracker.nextDay();
      expect(tracker.isToday, isTrue);
    });
  });

  group('NotificationController tests', () {
    test('Initial filter names and tabs', () {
      final notifCtrl = NotificationController();
      expect(notifCtrl.filterNames.length, equals(4));
      expect(notifCtrl.selectedFilterIndex, equals(0));
    });
  });

  group('PantryController tests', () {
    test('Initial storage groups', () {
      final pantryCtrl = PantryController();
      final grouped = pantryCtrl.groupedItems;
      expect(grouped.containsKey('Kulkas'), isTrue);
      expect(grouped.containsKey('Freezer'), isTrue);
      expect(grouped.containsKey('Lemari Kering'), isTrue);
    });
  });

  group('QuizController tests', () {
    test('Quiz state progression, scoring, and eco points award', () async {
      final quizCtrl = QuizController(service: FakeGeminiService());
      await quizCtrl.fetchQuiz();

      expect(quizCtrl.isLoading, isFalse);
      expect(quizCtrl.questions.length, equals(2));
      expect(quizCtrl.currentIndex, equals(0));
      expect(quizCtrl.score, equals(0));

      // Select correct answer for Q1
      quizCtrl.selectAnswer(0);
      expect(quizCtrl.answered, isTrue);
      expect(quizCtrl.score, equals(10));

      // Move to Q2
      quizCtrl.nextQuestion();
      expect(quizCtrl.currentIndex, equals(1));
      expect(quizCtrl.answered, isFalse);

      // Select wrong answer for Q2
      quizCtrl.selectAnswer(0);
      expect(quizCtrl.answered, isTrue);
      expect(quizCtrl.score, equals(10));

      // Complete quiz
      quizCtrl.nextQuestion();
      expect(quizCtrl.isCompleted, isTrue);
      expect(quizCtrl.pointsAwarded, isTrue);
    });
  });

  group('Multi-User Data Isolation model tests', () {
    test('PantryItemModel, NotificationModel, and FoodLogModel serialize userId correctly', () {
      final now = DateTime.now();
      final pantryItem = PantryItemModel(
        id: 1,
        userId: 42,
        name: 'Apel Fuji',
        quantity: 2,
        unit: 'kg',
        storage: 'Kulkas',
        expiryDate: now.add(const Duration(days: 4)),
        createdAt: now,
      );

      final pantryMap = pantryItem.toMap();
      expect(pantryMap['user_id'], equals(42));
      final parsedPantry = PantryItemModel.fromMap(pantryMap);
      expect(parsedPantry.userId, equals(42));
      expect(parsedPantry.name, equals('Apel Fuji'));

      final notif = NotificationModel(
        id: 1,
        userId: 42,
        title: 'Pengingat Sarapan',
        message: 'Jangan lupa sarapan!',
        type: 'meal_reminder',
        iconType: 'restaurant',
        createdAt: now,
      );
      final notifMap = notif.toMap();
      expect(notifMap['user_id'], equals(42));
      final parsedNotif = NotificationModel.fromMap(notifMap);
      expect(parsedNotif.userId, equals(42));

      const log = FoodLogModel(
        id: 1,
        userId: 42,
        foodName: 'Nasi Uduk',
        mealType: 'Sarapan',
        calories: 350,
        protein: 10,
        carbs: 55,
        fat: 8,
        cholesterol: 0.0,
        imagePath: '',
        time: '07:30',
        date: '2026-08-20',
      );
      final logMap = log.toMap();
      expect(logMap['user_id'], equals(42));
      expect(logMap['cholesterol'], equals(0.0));
      final parsedLog = FoodLogModel.fromMap(logMap);
      expect(parsedLog.userId, equals(42));
      expect(parsedLog.cholesterol, equals(0.0));
    });

    test('FoodItemModel handles TKPI cholesterol parsing correctly', () {
      const plantItem = FoodItemModel(
        name: 'Tempe Goreng',
        calories: 200,
        protein: 18,
        carbs: 12,
        fat: 10,
        cholesterol: 0.0,
        category: 'Makan Siang',
        imagePath: '',
      );
      expect(plantItem.cholesterol, equals(0.0));
      expect(plantItem.toMap()['cholesterol'], equals(0.0));

      const meatItem = FoodItemModel(
        name: 'Dada Ayam',
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
        cholesterol: 85.0,
        category: 'Makan Siang',
        imagePath: '',
      );
      expect(meatItem.cholesterol, equals(85.0));
      expect(meatItem.toMap()['cholesterol'], equals(85.0));

      final parsedFromMap = FoodItemModel.fromMap(meatItem.toMap());
      expect(parsedFromMap.cholesterol, equals(85.0));
    });
  });
}
