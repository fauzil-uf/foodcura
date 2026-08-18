class ArticleModel {
  final int id;
  final String title;
  final String category;
  final String readTime;
  final String date;
  final String summary;
  final String imageUrl;
  final String content;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.category,
    required this.readTime,
    required this.date,
    required this.summary,
    required this.imageUrl,
    required this.content,
  });
}
