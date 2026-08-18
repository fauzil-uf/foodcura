class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json, int id) {
    return QuizQuestion(
      id: id,
      question: json['question'] as String? ?? 'Pertanyaan seputar Food Waste',
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Jawaban A', 'Jawaban B', 'Jawaban C', 'Jawaban D'],
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
      explanation: json['explanation'] as String? ?? '',
    );
  }
}
