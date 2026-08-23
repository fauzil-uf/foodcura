import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../controllers/food_info_controller.dart';
import '../../database/db_helper.dart';
import '../../models/article_model.dart';
import '../dashboard/widgets/quiz_modal.dart';
import '../notification/notification_screen.dart';
import '../widgets/app_filter_chip_row.dart';
import '../widgets/app_top_bar.dart';
import 'widgets/article_detail_modal.dart';

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

  /// Callback saat state controller berubah untuk me-render ulang UI.
  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  /// Callback untuk menyinkronkan counter lencana notifikasi belum terbaca.
  void _onNotifChanged() {
    if (mounted) {
      setState(() {
        _unreadNotifCount = NotificationNotifier.instance.value;
      });
    }
  }

  /// Membuka layar notifikasi saat ikon lonceng ditekan.
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  /// Membuka modal bacaan artikel edukasi lengkap beserta tips praktis pencegahan food waste.
  void _openArticleDetail(ArticleModel article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ArticleDetailModal(article: article),
    );
  }

  /// Membuka modal kuis interaktif gizi dan food waste harian.
  void _startQuiz() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuizModal(),
    );
  }

  /// Membangun tampilan utama FoodInfo yang mencakup bilah pencarian, filter kategori, artikel unggulan, daftar artikel, dan kuis edukasi.
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

                      _buildSearchBar(),

                      const SizedBox(height: 14),

                      AppFilterChipRow(
                        filters: FoodInfoController.categories,
                        selectedIndex: _controller.selectedCategoryIndex,
                        onChanged: _controller.setCategory,
                      ),

                      const SizedBox(height: 24),

                      if (_controller.filteredArticles.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 36,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.surfaceDim),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.menu_book_outlined,
                                size: 44,
                                color: AppColors.textGray,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada artikel ditemukan',
                                style: AppTextStyles.heading2.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coba ubah kata kunci pencarian atau pilih kategori lain.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textGray,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      if (featured != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pilihan Untukmu',
                              style: AppTextStyles.headlineSm.copyWith(
                                color: AppColors.deepForest,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mintTint,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Unggulan',
                                style: AppTextStyles.badgeText.copyWith(
                                  color: AppColors.ecoGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildFeaturedCard(featured),
                        const SizedBox(height: 28),
                      ],

                      if (latestArticles.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _controller.selectedCategoryIndex == 0
                                  ? 'Artikel Terbaru'
                                  : 'Artikel ${FoodInfoController.categories[_controller.selectedCategoryIndex]}',
                              style: AppTextStyles.headlineSm.copyWith(
                                color: AppColors.deepForest,
                              ),
                            ),
                            if (latestArticles.length > 2)
                              GestureDetector(
                                // Toggle ekspansi artikel tanpa perlu navigasi halaman baru (Progressive Disclosure).
                                onTap: _controller.toggleShowAll,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
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
                                            : 'Lihat Semua (${latestArticles.length})',
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
                        ),
                        const SizedBox(height: 12),
                        ...displayedLatestArticles.map(
                          (a) => _buildArticleListItem(a),
                        ),
                        const SizedBox(height: 28),
                      ],

                      _buildMiniQuizCard(),

                      const SizedBox(height: 28),

                      _buildDailyTipCard(),

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

  /// Membangun bilah pencarian artikel dengan ikon cari dan text field dinamis.
  Widget _buildSearchBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surfaceDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textGray, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _controller.setSearchQuery(val),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.deepForest,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Cari topik makanan, nutrisi...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textGray,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun kartu artikel unggulan utama dengan gambar besar dan badge kategori.
  Widget _buildFeaturedCard(ArticleModel article) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Image.network(
                  article.imageUrl,
                  height: 175,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 175,
                    color: AppColors.mintTint,
                    child: const Center(
                      child: Icon(
                        Icons.restaurant,
                        size: 40,
                        color: AppColors.ecoGreen,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    article.category,
                    style: AppTextStyles.badgeText.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: AppTextStyles.button.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.readTime,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.summary,
                  style: AppTextStyles.bodySmall.copyWith(
                    height: 1.5,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _openArticleDetail(article),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Baca Artikel',
                        style: AppTextStyles.buttonSmall.copyWith(
                          fontSize: 12,
                          color: AppColors.ecoGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.ecoGreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun item baris artikel edukasi horizontal pada daftar artikel terbaru.
  Widget _buildArticleListItem(ArticleModel article) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceDim),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                article.imageUrl,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 88,
                  height: 88,
                  color: AppColors.mintTint,
                  child: const Icon(Icons.article, color: AppColors.ecoGreen),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.category,
                    style: AppTextStyles.badgeText.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ecoGreen,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.title,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepForest,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${article.readTime} · ${article.date}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun kartu promosi kuis mini gizi dan food waste berlatar hijau emerald.
  Widget _buildMiniQuizCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'UJI PENGETAHUANMU',
                    style: AppTextStyles.sectionHeader.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Mana yang paling membantu mengurangi food waste?',
                style: AppTextStyles.headlineSm.copyWith(
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih jawaban yang menurutmu benar.',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _startQuiz,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mulai Quiz',
                        style: AppTextStyles.buttonSmall.copyWith(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Membangun kartu tips praktis harian seputar penyimpanan bahan makanan.
  Widget _buildDailyTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintTint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.ecoGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FoodCura Tip',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepForest,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Simpan makanan yang akan kedaluwarsa lebih dulu di bagian depan kulkas agar tidak terlupakan.',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    height: 1.5,
                    color: AppColors.deepForest.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
