import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
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
  StreamSubscription? _cloudSubscription;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Pasang listener dan muat daftar notifikasi dari SQLite
    _controller.addListener(_onControllerChanged);
    _controller.loadNotifications();
    _setupCloudNotificationsListener();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _cloudSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupCloudNotificationsListener() {
    try {
      _authSubscription?.cancel();
      _authSubscription = AuthService.instance.authStateChanges.listen((user) {
        final uid = user?.uid;
        if (uid != null) {
          _subscribeToCloudNotifications(uid);
        }
      });

      final currentUid = AuthService.instance.currentUser?.uid;
      if (currentUid != null) {
        _subscribeToCloudNotifications(currentUid);
      }
    } catch (_) {}
  }

  void _subscribeToCloudNotifications(String uid) {
    _cloudSubscription?.cancel();
    _cloudSubscription = FirestoreService.instance
        .streamNotifications(uid)
        .listen((_) {
          _controller.syncCloudNotifications();
        });
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

  // Hapus satu notifikasi saat di-swipe
  Future<void> _deleteNotification(NotificationModel notif) async {
    await _controller.deleteNotification(notif);
    if (mounted) {
      AppSnackBar.showSuccess(context, 'Notifikasi dihapus');
    }
  }

  // Dialog konfirmasi hapus notifikasi terpilih
  Future<void> _confirmDeleteSelected() async {
    final count = _controller.selectedCount;
    if (count == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus $count Notifikasi?',
          style: AppTextStyles.heading2.copyWith(fontSize: 18),
        ),
        content: Text(
          'Sebanyak $count notifikasi yang dipilih akan dihapus secara permanen.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.urgent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _controller.deleteSelectedNotifications();
      if (mounted) {
        AppSnackBar.showSuccess(context, '$count notifikasi telah dihapus');
      }
    }
  }

  // Header kontekstual saat masuk mode multi-seleksi
  Widget _buildSelectionTopBar() {
    final visibleCount = _controller.notifications
        .where((n) => n.id != null)
        .length;
    final isAllSelected = _controller.selectedCount > 0 &&
        _controller.selectedCount == visibleCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundWarm,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _controller.clearSelection(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.topBarButtonBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.topBarButtonBorder,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.deepForest,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '${_controller.selectedCount} Dipilih',
              style: AppTextStyles.heading2.copyWith(
                fontSize: 18,
                color: AppColors.deepForest,
              ),
            ),
          ),
          // Tombol Pilih Semua / Batal Semua
          GestureDetector(
            onTap: () => _controller.selectAll(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isAllSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.topBarButtonBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isAllSelected
                      ? AppColors.primary
                      : AppColors.topBarButtonBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAllSelected
                        ? Icons.check_box_rounded
                        : Icons.select_all_rounded,
                    size: 18,
                    color: isAllSelected
                        ? AppColors.primary
                        : AppColors.deepForest,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAllSelected ? 'Batal Semua' : 'Pilih Semua',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isAllSelected
                          ? AppColors.primary
                          : AppColors.deepForest,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tombol Hapus Terpilih
          GestureDetector(
            onTap: _confirmDeleteSelected,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.urgent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.urgent.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.urgent,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_controller.isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _controller.isSelectionMode) {
          _controller.clearSelection();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundWarm,
        body: SafeArea(
          child: Column(
            children: [
              if (_controller.isSelectionMode)
                _buildSelectionTopBar()
              else
                AppTopBar(
                  title: 'Notifikasi',
                  showBackButton: true,
                  onBack: () => Navigator.pop(context),
                  actions: [
                    GestureDetector(
                      onTap: _markAllRead,
                      child: Container(
                        width: 40,
                        height: 40,
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
                          size: 20,
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
                      onRefresh: () => _controller.syncCloudNotifications(),
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
                                          (n) => _buildDismissibleItem(
                                            n,
                                            isEarlier: false,
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
                                          (n) => _buildDismissibleItem(
                                            n,
                                            isEarlier: true,
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
    ),
  );
}

  // Item notifikasi yang bisa di-swipe ke kiri untuk menghapus atau dipilih lewat multi-select
  Widget _buildDismissibleItem(
    NotificationModel notif, {
    required bool isEarlier,
  }) {
    final isSelected = notif.id != null &&
        _controller.selectedNotificationIds.contains(notif.id);

    return Dismissible(
      key: ValueKey('notif_${notif.id ?? notif.createdAt}'),
      direction: _controller.isSelectionMode
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.urgent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
      onDismissed: (_) => _deleteNotification(notif),
      child: NotificationCard(
        notif: notif,
        isEarlier: isEarlier,
        isSelectionMode: _controller.isSelectionMode,
        isSelected: isSelected,
        onTap: () {
          if (_controller.isSelectionMode) {
            if (notif.id != null) {
              _controller.toggleSelection(notif.id!);
            }
          } else {
            _markRead(notif);
          }
        },
        onLongPress: () {
          if (notif.id != null) {
            _controller.startSelection(notif.id!);
          }
        },
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
