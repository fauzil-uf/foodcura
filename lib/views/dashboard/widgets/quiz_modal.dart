import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';
import '../../../controllers/quiz_controller.dart';
import '../../../models/quiz_model.dart';

class QuizModal extends StatefulWidget {
  const QuizModal({super.key});

  @override
  State<QuizModal> createState() => _QuizModalState();
}

class _QuizModalState extends State<QuizModal> {
  final _controller = QuizController();

  List<QuizQuestion> get _questions => _controller.questions;
  bool get _loading => _controller.isLoading;
  int get _currentIndex => _controller.currentIndex;
  int? get _selectedOptionIndex => _controller.selectedOptionIndex;
  int get _score => _controller.score;
  bool get _answered => _controller.answered;
  bool get _completed => _controller.isCompleted;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.fetchQuiz();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchQuiz() async {
    await _controller.fetchQuiz();
  }

  void _selectAnswer(int index) {
    _controller.selectAnswer(index);
  }

  void _nextQuestion() {
    _controller.nextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.mintTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.quiz_outlined,
                        color: AppColors.ecoGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Mini Quiz FoodCura',
                      style: AppTextStyles.headlineMd.copyWith(
                        fontSize: 18,
                        color: AppColors.deepForest,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textGray,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.surfaceDim),

          if (_loading)
            SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.ecoGreen),
                    const SizedBox(height: 16),
                    Text(
                      'AI sedang menyiapkan kuis...',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_completed)
            _buildResultView()
          else
            _buildQuizContent(),
        ],
      ),
    );
  }

  Widget _buildQuizContent() {
    final currentQ = _questions[_currentIndex];

    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pertanyaan ${_currentIndex + 1} dari ${_questions.length}',
                  style: AppTextStyles.badgeText.copyWith(
                    fontSize: 12,
                    color: AppColors.ecoGreen,
                  ),
                ),
                Text(
                  'Skor: $_score Poin',
                  style: AppTextStyles.badgeText.copyWith(
                    fontSize: 12,
                    color: AppColors.deepForest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: AppColors.surfaceContainer,
                color: AppColors.ecoGreen,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 20),

            // Question Box
            Text(
              currentQ.question,
              style: AppTextStyles.headlineSm.copyWith(
                fontSize: 17,
                color: AppColors.deepForest,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Options List
            ...List.generate(currentQ.options.length, (index) {
              final isSelected = _selectedOptionIndex == index;
              final isCorrect = index == currentQ.correctAnswerIndex;

              Color optionBg = Colors.white;
              Color optionBorder = AppColors.surfaceDim;
              Color textColor = AppColors.deepForest;
              Widget iconWidget = Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.5,
                  ),
                ),
              );
              double opacity = 1.0;

              if (_answered) {
                if (isCorrect) {
                  optionBg = const Color(0xFFE8F5E9);
                  optionBorder = const Color(0xFF2E7D32);
                  textColor = const Color(0xFF1B5E20);
                  iconWidget = const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 22,
                  );
                  opacity = 1.0;
                } else if (isSelected) {
                  optionBg = const Color(0xFFFFEBEE);
                  optionBorder = const Color(0xFFD32F2F);
                  textColor = const Color(0xFFB71C1C);
                  iconWidget = const Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFFD32F2F),
                    size: 22,
                  );
                  opacity = 1.0;
                } else {
                  optionBg = const Color(0xFFF9FAF9);
                  optionBorder = AppColors.borderSoft.withValues(alpha: 0.5);
                  textColor = AppColors.textGray.withValues(alpha: 0.5);
                  iconWidget = Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.borderSoft.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                  );
                  opacity = 0.45;
                }
              }

              return AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: opacity,
                child: GestureDetector(
                  onTap: _answered ? null : () => _selectAnswer(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: optionBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: optionBorder,
                        width: _answered && (isCorrect || isSelected) ? 2 : 1,
                      ),
                      boxShadow: (!_answered || isCorrect || isSelected)
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        iconWidget,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            currentQ.options[index],
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight:
                                  (_answered && (isCorrect || isSelected))
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              color: textColor,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Explanation box after answer
            if (_answered) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedOptionIndex == currentQ.correctAnswerIndex
                      ? const Color(0xFFF1F8E9)
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _selectedOptionIndex == currentQ.correctAnswerIndex
                        ? const Color(0xFFA5D6A7)
                        : const Color(0xFFFFE082),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _selectedOptionIndex == currentQ.correctAnswerIndex
                              ? Icons.check_circle_outline_rounded
                              : Icons.info_outline_rounded,
                          size: 18,
                          color:
                              _selectedOptionIndex == currentQ.correctAnswerIndex
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFE65100),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedOptionIndex == currentQ.correctAnswerIndex
                              ? 'Jawaban Tepat!'
                              : 'Penjelasan:',
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color:
                                _selectedOptionIndex ==
                                        currentQ.correctAnswerIndex
                                    ? const Color(0xFF1B5E20)
                                    : const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentQ.explanation,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12.5,
                        color: AppColors.textPrimary.withValues(alpha: 0.85),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Next button as primary focus
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 2,
                ),
                onPressed: _nextQuestion,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentIndex < _questions.length - 1
                          ? 'Pertanyaan Selanjutnya'
                          : 'Lihat Hasil Quiz',
                      style: AppTextStyles.button.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final totalPossible = _questions.length * 10;
    final isGreat = _score >= (totalPossible * 0.7);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isGreat ? AppColors.mintTint : AppColors.warningBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGreat ? Icons.emoji_events_rounded : Icons.psychology_rounded,
              size: 44,
              color: isGreat ? AppColors.ecoGreen : AppColors.segera,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isGreat ? 'Luar Biasa!' : 'Tetap Semangat!',
            style: AppTextStyles.heading1.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda mendapatkan skor $_score dari $totalPossible poin.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
          if (_score > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mintTint,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.ecoGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, color: AppColors.ecoGreen, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '+$_score Eco Poin berhasil ditambahkan!',
                    style: AppTextStyles.badgeText.copyWith(
                      fontSize: 12,
                      color: AppColors.ecoGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _fetchQuiz,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.mintTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.refresh,
                          color: AppColors.ecoGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Coba Lagi',
                          style: AppTextStyles.buttonSmall.copyWith(
                            fontSize: 13,
                            color: AppColors.ecoGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      child: Text(
                        'Selesai',
                        style: AppTextStyles.buttonSmall.copyWith(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
