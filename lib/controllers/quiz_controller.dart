import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/quiz_model.dart';
import '../services/gemini_service.dart';

/// Controller untuk mengelola siklus kuis edukasi AI, validasi jawaban,
/// kalkulasi skor, dan pemberian reward Eco Points.
class QuizController extends ChangeNotifier {
  final GeminiService _geminiService;

  QuizController({GeminiService? service})
    : _geminiService = service ?? GeminiService.instance;

  List<QuizQuestion> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  int _score = 0;
  bool _answered = false;
  bool _isCompleted = false;
  bool _pointsAwarded = false;

  // Getters
  List<QuizQuestion> get questions => _questions;
  bool get isLoading => _isLoading;
  int get currentIndex => _currentIndex;
  int? get selectedOptionIndex => _selectedOptionIndex;
  int get score => _score;
  bool get answered => _answered;
  bool get isCompleted => _isCompleted;
  bool get pointsAwarded => _pointsAwarded;
  int get totalQuestions => _questions.length;

  QuizQuestion? get currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length
          ? _questions[_currentIndex]
          : null;

  /// Memuat kuis baru (online via Gemini atau offline pool)
  Future<void> fetchQuiz() async {
    _isLoading = true;
    _currentIndex = 0;
    _selectedOptionIndex = null;
    _score = 0;
    _answered = false;
    _isCompleted = false;
    _pointsAwarded = false;
    notifyListeners();

    try {
      _questions = await _geminiService.generateQuiz();
    } catch (e) {
      debugPrint('Error fetching quiz: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memilih salah satu opsi jawaban
  void selectAnswer(int optionIndex) {
    if (_answered || currentQuestion == null) return;

    _selectedOptionIndex = optionIndex;
    _answered = true;

    if (optionIndex == currentQuestion!.correctAnswerIndex) {
      _score += 10;
    }
    notifyListeners();
  }

  /// Melangkah ke pertanyaan selanjutnya atau menyelesaikan kuis
  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _selectedOptionIndex = null;
      _answered = false;
    } else {
      _isCompleted = true;
      _awardPoints();
    }
    notifyListeners();
  }

  /// Memberikan reward Eco Points ke user
  Future<void> _awardPoints() async {
    if (!_pointsAwarded && _score > 0) {
      _pointsAwarded = true;
      await EcoPointsNotifier.instance.addPoints(_score);
      notifyListeners();
    }
  }
}
