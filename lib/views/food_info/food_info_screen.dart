import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../controllers/food_info_controller.dart';
import '../../models/article_model.dart';
import '../../services/app_notifiers.dart';
import '../dashboard/widgets/quiz_modal.dart';
import '../notification/notification_screen.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_filter_chip_row.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/app_top_bar.dart';
import 'widgets/article_detail_modal.dart';
import 'widgets/article_list_item.dart';
import 'widgets/daily_tip_card.dart';
import 'widgets/featured_article_card.dart';
import 'widgets/food_info_quiz_card.dart';

// Layar artikel edukasi gizi & info food waste
class FoodInfoScreen extends StatefulWidget {
  const FoodInfoScreen({super.key});

  @override
  State<FoodInfoScreen> createState() => _FoodInfoScreenState();
}

class _FoodInfoScreenState extends State<FoodInfoScreen> {
  final _controller = FoodInfoController();
  final TextEditingController _searchController = TextEditingController();
  int _unreadNotifCount = 0;

  @override
  void initState() {
    super.initState();
    // Inisialisasi unread notifikasi dan pasang listener controller
    _unreadNotifCount = NotificationNotifier.instance.value;
    _controller.addListener(_onControllerChanged);
    NotificationNotifier.instance.addListener(_onNotifChanged);
    NotificationNotifier.instance.refresh();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    NotificationNotifier.instance.removeListener(_onNotifChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Update tampilan saat kategori artikel atau hasil pencarian berubah
  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  // Update badge notifikasi
  void _onNotifChanged() {
    if (mounted) {
      setState(() {
        _unreadNotifCount = NotificationNotifier.instance.value;
      });
    }
  }

  // Buka layar notifikasi
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    ).then((_) => NotificationNotifier.instance.refresh());
  }

  // Buka modal baca detail artikel lengkap
  void _openArticleDetail(ArticleModel article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ArticleDetailModal(article: article),
    );
  }

  // Buka modal kuis gizi interaktif
  void _startQuiz() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuizModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featured = _controller.featuredArticle;
    final latestArticles = _controller.latestArticles;
    final displayedLatestArticles = _controller.displayedLatestArticles;

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'FoodInfo',
              unreadNotifications: _unreadNotifCount,
              onNotificationTap: _openNotifications,
            ),

            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => NotificationNotifier.instance.refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),

                      AppSearchBar(
                        controller: _searchController,
                        hintText: 'Cari topik makanan, nutrisi...',
                        onChanged: _controller.setSearchQuery,
                      ),

                      const SizedBox(height: 14),

                      AppFilterChipRow(
                        filters: FoodInfoController.categories,
                        selectedIndex: _controller.selectedCategoryIndex,
                        onChanged: _controller.setCategory,
                      ),

                      const SizedBox(height: 24),

                      // Tampilan saat pencarian tidak menemukan artikel
                      if (_controller.filteredArticles.isEmpty) ...[
                        _buildEmptySearchState(),
                        const SizedBox(height: 28),
                      ],

                      // Seksi artikel sorotan utama
                      if (featured != null) ...[
                        _buildSectionHeaderWithBadge(
                          title: 'Pilihan Untukmu',
                          badge: 'Unggulan',
                        ),
                        const SizedBox(height: 12),
                        FeaturedArticleCard(
                          article: featured,
                          onTap: () => _openArticleDetail(featured),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Seksi daftar artikel terbaru
                      if (latestArticles.isNotEmpty) ...[
                        _buildLatestArticlesHeader(latestArticles.length),
                        const SizedBox(height: 12),
                        ...displayedLatestArticles.map(
                          (a) => ArticleListItem(
                            article: a,
                            onTap: () => _openArticleDetail(a),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Banner kuis & tips harian
                      FoodInfoQuizCard(onStartQuiz: _startQuiz),
                      const SizedBox(height: 28),
                      const DailyTipCard(),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header seksi dengan label badge
  Widget _buildSectionHeaderWithBadge({
    required String title,
    required String badge,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineSm.copyWith(color: AppColors.deepForest),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.mintTint,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badge,
            style: AppTextStyles.badgeText.copyWith(
              color: AppColors.ecoGreen,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  // Header daftar artikel terbaru beserta toggle ekspansi
  Widget _buildLatestArticlesHeader(int totalCount) {
    final title = _controller.selectedCategoryIndex == 0
        ? 'Artikel Terbaru'
        : 'Artikel ${FoodInfoController.categories[_controller.selectedCategoryIndex]}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineSm.copyWith(color: AppColors.deepForest),
        ),
        if (totalCount > 2)
          GestureDetector(
            onTap: _controller.toggleShowAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _controller.showAllArticles
                    ? AppColors.surfaceDim
                    : AppColors.mintTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _controller.showAllArticles
                        ? 'Tampilkan Sedikit'
                        : 'Lihat Semua ($totalCount)',
                    style: AppTextStyles.badgeText.copyWith(
                      color: _controller.showAllArticles
                          ? AppColors.textGray
                          : AppColors.ecoGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    _controller.showAllArticles
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: _controller.showAllArticles
                        ? AppColors.textGray
                        : AppColors.ecoGreen,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Tampilan placeholder saat pencarian tidak ditemukan
  Widget _buildEmptySearchState() {
    return const AppEmptyState(
      icon: Icons.menu_book_outlined,
      title: 'Belum ada artikel ditemukan',
      message: 'Coba ubah kata kunci pencarian atau pilih kategori lain.',
      iconColor: AppColors.textGray,
      iconBgColor: AppColors.surfaceContainer,
      padding: EdgeInsets.symmetric(vertical: 36, horizontal: 20),
    );
  }
}
