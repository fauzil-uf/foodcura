import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/controllers/auth_controller.dart';
import 'package:foodcura/controllers/dashboard_controller.dart';
import 'package:foodcura/controllers/food_tracker_controller.dart';
import 'package:foodcura/controllers/notification_controller.dart';
import 'package:foodcura/controllers/pantry_controller.dart';
import 'package:foodcura/controllers/quiz_controller.dart';
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
        question: 'Apa fungsi utama serat bagi pencernaan?',
        options: [
          'Melancarkan BAB',
          'Meningkatkan gula',
          'Membuat lemas',
          'Tidak ada',
        ],
        correctAnswerIndex: 0,
        explanation: 'Serat membantu melancarkan saluran pencernaan.',
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

  @override
  Future<EcoImpactResult> generateEcoImpactInsight({
    required int rescuedCount,
    required int ecoPoints,
    required String lastRescuedItem,
    double quantity = 1.0,
    String unit = 'pcs',
    String? category,
  }) async {
    return EcoImpactResult(
      kgCO2: 1.2,
      savedRupiah: 15000,
      narrative: 'Mock AI Eco Insight: Hebat! $lastRescuedItem terselamatkan.',
      isAiGenerated: true,
    );
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

  group('PantryController tests and AI Eco Impact', () {
    test('Initial storage groups', () {
      final pantryCtrl = PantryController(gemini: FakeGeminiService());
      final grouped = pantryCtrl.groupedItems;
      expect(grouped.containsKey('Kulkas'), isTrue);
      expect(grouped.containsKey('Freezer'), isTrue);
      expect(grouped.containsKey('Lemari Kering'), isTrue);
    });

    test('getEcoRescueImpact generates appreciation narrative and metrics', () async {
      final pantryCtrl = PantryController(gemini: FakeGeminiService());
      final testItem = PantryItemModel(
        id: 1,
        name: 'Bayam Segar',
        quantity: 1,
        unit: 'ikat',
        storage: 'Kulkas',
        expiryDate: DateTime(2026, 8, 20),
        createdAt: DateTime.now(),
      );

      final impact = await pantryCtrl.getEcoRescueImpact(testItem);
      expect(impact.narrative, contains('Mock AI Eco Insight'));
      expect(impact.narrative, contains('Bayam Segar'));
      expect(impact.kgCO2, greaterThan(0));
      expect(impact.savedRupiah, greaterThan(0));

      // Test offline category impact calculator
      final categoryImpact = pantryCtrl.getEstimatedImpactForItem(testItem);
      expect(categoryImpact.kgCO2, equals(0.2));
      expect(categoryImpact.savedRupiah, equals(3500));
      expect(categoryImpact.isAiGenerated, isFalse);
    });
  });

  group('QuizController tests', () {
    test('Quiz state progression and scoring', () async {
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
    });
  });
}
