import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';
import '../../../models/article_model.dart';

class ArticleDetailModal extends StatelessWidget {
  final ArticleModel article;

  const ArticleDetailModal({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.deepForest,
                      size: 20,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mintTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    article.category,
                    style: AppTextStyles.badgeText.copyWith(
                      color: AppColors.ecoGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: 22,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppColors.textGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${article.readTime} · ${article.date}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      article.imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 200,
                        color: AppColors.mintTint,
                        child: const Center(
                          child: Icon(
                            Icons.article_outlined,
                            size: 48,
                            color: AppColors.ecoGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mintTint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.ecoGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.bookmark_outline,
                          color: AppColors.ecoGreen,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            article.summary,
                            style: AppTextStyles.bodyMd.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepForest,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ArticleContentRenderer(content: article.content),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleContentRenderer extends StatelessWidget {
  final String content;
  const _ArticleContentRenderer({required this.content});

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final widgets = <Widget>[];
    for (final line in lines) {
      final raw = line.trim();
      if (raw.isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }
      final listMatch = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(raw);
      if (listMatch != null) {
        widgets.add(_buildListItem(listMatch.group(1)!, listMatch.group(2)!));
        widgets.add(const SizedBox(height: 10));
      } else {
        widgets.add(_buildRichParagraph(raw));
        widgets.add(const SizedBox(height: 14));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildListItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.only(top: 2, right: 10),
          decoration: const BoxDecoration(
            color: AppColors.mintTint,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.badgeText.copyWith(
                color: AppColors.ecoGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Expanded(child: _buildRichParagraph(text)),
      ],
    );
  }

  Widget _buildRichParagraph(String text) {
    return RichText(text: TextSpan(children: _parseInline(text)));
  }

  List<TextSpan> _parseInline(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;
    final normalStyle = AppTextStyles.bodyMd.copyWith(
      color: AppColors.deepForest,
      height: 1.75,
    );
    final boldStyle = AppTextStyles.bodyMd.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.deepForest,
      height: 1.75,
    );
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: normalStyle,
          ),
        );
      }
      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: normalStyle));
    }
    return spans.isEmpty ? [TextSpan(text: text, style: normalStyle)] : spans;
  }
}
