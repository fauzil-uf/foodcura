import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_filter_chip_row.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/app_top_bar.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_info_tip.dart';

// Layar pusat notifikasi (peringatan kedaluwarsa & nutrisi)
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
    // Pasang listener dan muat daftar notifikasi dari SQLite
    _controller.addListener(_onControllerChanged);
    _controller.loadNotifications();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  // Update tampilan saat status baca atau filter berubah
  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  // Ganti filter kategori notifikasi
  void _onFilterChanged(int index) {
    _controller.setFilter(index);
  }

  // Tandai seluruh notifikasi telah dibaca
  Future<void> _markAllRead() async {
    await _controller.markAllRead();
    if (mounted) {
      AppSnackBar.showSuccess(context, 'Semua notifikasi ditandai dibaca');
    }
  }

  // Tandai satu notifikasi tertentu telah dibaca
  Future<void> _markRead(NotificationModel notif) async {
    await _controller.markRead(notif);
  }

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
                      color: AppColors.topBarButtonBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.topBarButtonBorder,
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
              child: AppFilterChipRow(
                filters: _filters,
                selectedIndex: _selectedFilter,
                onChanged: _onFilterChanged,
              ),
            ),

            Expanded(
              child: _controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _controller.loadNotifications(),
                      child: _controller.notifications.isEmpty
                          ? const SingleChildScrollView(
                              physics: AlwaysScrollableScrollPhysics(),
                              child: AppEmptyState(
                                icon: Icons.notifications_none_rounded,
                                title: 'Tidak Ada Notifikasi',
                                message:
                                    'Belum ada notifikasi saat ini.\nKami akan memberitahumu jika ada hal penting.',
                              ),
                            )
                          : SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_controller
                                      .groupedNotifications['Hari Ini']!
                                      .isNotEmpty) ...[
                                    _buildSectionLabel('Hari Ini'),
                                    const SizedBox(height: 10),
                                    ..._controller
                                        .groupedNotifications['Hari Ini']!
                                        .map(
                                          (n) => NotificationCard(
                                            notif: n,
                                            isEarlier: false,
                                            onTap: () => _markRead(n),
                                          ),
                                        ),
                                    const SizedBox(height: 16),
                                  ],

                                  if (_controller
                                      .groupedNotifications['Sebelumnya']!
                                      .isNotEmpty) ...[
                                    _buildSectionLabel('Sebelumnya'),
                                    const SizedBox(height: 10),
                                    ..._controller
                                        .groupedNotifications['Sebelumnya']!
                                        .map(
                                          (n) => NotificationCard(
                                            notif: n,
                                            isEarlier: true,
                                            onTap: () => _markRead(n),
                                          ),
                                        ),
                                    const SizedBox(height: 16),
                                  ],

                                  const NotificationInfoTip(),
                                  const SizedBox(height: 32),
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

  // Label pembatas kelompok waktu notifikasi
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
}
