import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import '../widgets/app_top_bar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _controller = NotificationController();

  List<String> get _filters => _controller.filterNames;
  int get _selectedFilter => _controller.selectedFilterIndex;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.loadNotifications();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Callback saat data notifikasi di controller berubah untuk me-render ulang tampilan UI.
  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  /// Mengubah filter kategori notifikasi (Semua, Belum Dibaca, Kadaluwarsa, Info) berdasarkan indeks filter.
  void _onFilterChanged(int index) {
    _controller.setFilter(index);
  }

  /// Menandai seluruh notifikasi telah dibaca di database SQLite dan memunculkan snackbar konfirmasi.
  Future<void> _markAllRead() async {
    await _controller.markAllRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua notifikasi ditandai dibaca')),
      );
    }
  }

  /// Menandai satu item notifikasi spesifik telah dibaca di database SQLite.
  Future<void> _markRead(NotificationModel notif) async {
    await _controller.markRead(notif);
  }

  /// Membangun antarmuka notifikasi dengan filter kategori dan pengelompokan waktu (Hari Ini & Sebelumnya).
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Notifikasi',
              showBackButton: true,
              onBack: () => Navigator.pop(context),
              actions: [
                GestureDetector(
                  onTap: _markAllRead,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBE6D8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFDFD7C2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.done_all_rounded,
                      color: AppColors.deepForest,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedFilter == index;
                    return GestureDetector(
                      onTap: () => _onFilterChanged(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: isSelected
                              ? null
                              : Border.all(color: AppColors.surfaceDim),
                        ),
                        child: Center(
                          child: Text(
                            _filters[index],
                            style: AppTextStyles.chipText.copyWith(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textGray,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            Expanded(
              child: _controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.ecoGreen,
                      ),
                    )
                  : _controller.notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _controller.loadNotifications(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kelompokkan notifikasi ke dalam bucket 'Hari Ini' dan 'Sebelumnya' untuk kemudahan navigasi kronologis pengguna.
                            if (_controller
                                .groupedNotifications['Hari Ini']!
                                .isNotEmpty) ...[
                              _buildSectionLabel('Hari Ini'),
                              const SizedBox(height: 10),
                              ..._controller
                                  .groupedNotifications['Hari Ini']!
                                  .map((n) => _buildNotificationCard(n, false)),
                            ],

                            if (_controller
                                .groupedNotifications['Sebelumnya']!
                                .isNotEmpty) ...[
                              if (_controller
                                  .groupedNotifications['Hari Ini']!
                                  .isNotEmpty)
                                const SizedBox(height: 24),
                              _buildSectionLabel('Sebelumnya'),
                              const SizedBox(height: 10),
                              ..._controller
                                  .groupedNotifications['Sebelumnya']!
                                  .map((n) => _buildNotificationCard(n, true)),
                            ],

                            const SizedBox(height: 16),

                            _buildInfoTip(),

                            const SizedBox(height: 80),
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

  /// Membangun label pemisah kelompok waktu (cth: 'HARI INI', 'SEBELUMNYA').
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.sectionHeader.copyWith(
          color: AppColors.ecoGreen,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Membangun kartu notifikasi interaktif dengan warna aksen, ikon, tag kategori, dan status unread.
  Widget _buildNotificationCard(NotificationModel notif, bool isEarlier) {
    IconData iconData;
    Color accentColor;
    Color iconBgColor;
    String categoryTag;

    // Petakan tipe notifikasi ke warna aksen dan ikon khusus agar pengguna dapat mengidentifikasi tingkat urgensi secara visual.
    switch (notif.type) {
      case 'meal_reminder':
        categoryTag = 'Pengingat Waktu Makan';
        accentColor = AppColors.primary;
        iconData = Icons.restaurant_rounded;
        iconBgColor = AppColors.mintTint;
        break;
      case 'expiry_warning':
        categoryTag = 'Pantry & Expiry';
        accentColor = AppColors.urgent;
        iconData = Icons.warning_amber_rounded;
        iconBgColor = AppColors.warningBg;
        break;
      case 'nutrition_excess':
        categoryTag = 'Tracker Nutrisi';
        accentColor = AppColors.segera;
        iconData = Icons.analytics_rounded;
        iconBgColor = AppColors.warningBgLight;
        break;
      case 'tips':
        categoryTag = 'Tips Food Rescue';
        accentColor = AppColors.ecoGreen;
        iconData = notif.iconType == 'restaurant'
            ? Icons.restaurant_rounded
            : Icons.lightbulb_rounded;
        iconBgColor = AppColors.mintTint;
        break;
      case 'system':
      default:
        categoryTag = 'System & Info';
        accentColor = AppColors.infoBlueDark;
        iconData = notif.iconType == 'eco'
            ? Icons.eco_rounded
            : Icons.system_update_rounded;
        iconBgColor = AppColors.infoBlueBg;
        break;
    }

    return GestureDetector(
      onTap: () => _markRead(notif),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notif.isRead
                ? AppColors.surfaceDim
                : accentColor.withValues(alpha: 0.3),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepForest.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left accent border strip
                Container(
                  width: 5,
                  color: notif.isRead
                      ? accentColor.withValues(alpha: 0.4)
                      : accentColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Opacity(
                      opacity: isEarlier ? 0.85 : 1.0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon Circle
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: accentColor, size: 22),
                          ),
                          const SizedBox(width: 12),

                          // Main Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Category tag + Unread dot
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        categoryTag,
                                        style: AppTextStyles.badgeText.copyWith(
                                          fontSize: 10,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                    if (!notif.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: accentColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Title
                                Text(
                                  notif.title,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    fontWeight: notif.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                    color: AppColors.deepForest,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),

                                // Message
                                Text(
                                  notif.message,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),

                                // Time ago
                                Text(
                                  notif.timeAgo,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun banner hijau informasi tentang kebijakan pengiriman notifikasi FoodCura.
  Widget _buildInfoTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_active,
            color: AppColors.ecoGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kami hanya mengirim notifikasi penting terkait bahan makananmu dan pengingat yang kamu atur.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun tampilan kosong ketika tidak ada notifikasi yang sesuai filter.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.mintTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 40,
                color: AppColors.ecoGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tidak Ada Notifikasi',
              style: AppTextStyles.headlineMd.copyWith(
                fontSize: 18,
                color: AppColors.deepForest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada notifikasi saat ini.\nKami akan memberitahumu jika ada hal penting.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
