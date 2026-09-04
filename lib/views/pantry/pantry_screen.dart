import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../controllers/pantry_controller.dart';
import '../../models/pantry_item_model.dart';
import '../../services/app_notifiers.dart';
import '../notification/notification_screen.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_filter_chip_row.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/app_top_bar.dart';
import 'widgets/add_pantry_item_modal.dart';
import 'widgets/pantry_item_card.dart';
import 'widgets/pantry_item_detail_modal.dart';
import 'widgets/pantry_summary_alert.dart';
import 'widgets/pantry_tips_card.dart';

// Layar stok dapur & pemantau kedaluwarsa bahan
class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _controller = PantryController();
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0;

  static const List<String> _filters = [
    'Semua',
    'Urgent',
    'Segera (3-5 hari)',
    'Aman (>5 hari)',
  ];

  @override
  void initState() {
    super.initState();
    // Sinkronisasi data pantry dan notifikasi real-time
    _controller.addListener(_onControllerChanged);
    _controller.loadPantryData();
    PantryUpdateNotifier.instance.addListener(_onPantryChanged);
    NotificationNotifier.instance.addListener(_onNotifChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    PantryUpdateNotifier.instance.removeListener(_onPantryChanged);
    NotificationNotifier.instance.removeListener(_onNotifChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Render ulang UI jika state pantry berubah
  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  // Muat ulang daftar bahan pantry jika ada update dari modal/layar lain
  void _onPantryChanged() {
    if (mounted) _controller.loadPantryData();
  }

  // Refresh jumlah notifikasi unread
  void _onNotifChanged() {
    if (mounted) _controller.refreshUnreadCount();
  }

  // Filter bahan berdasarkan tingkat urgensi kedaluwarsa
  void _onFilterChanged(int index) {
    setState(() => _selectedFilter = index);
    String? filter;
    switch (index) {
      case 1:
        filter = 'urgent';
        break;
      case 2:
        filter = 'segera';
        break;
      case 3:
        filter = 'aman';
        break;
    }
    _controller.setFilter(filter);
  }

  // Cari bahan pantry berdasarkan nama
  void _onSearch(String query) {
    _controller.setSearchQuery(query);
  }

  // Tandai bahan telah dimasak & berikan reward poin
  Future<void> _markAsUsed(PantryItemModel item) async {
    if (item.id == null) return;
    await _controller.markItemUsed(item.id!);

    if (mounted) {
      final isExpired = item.daysUntilExpiry < 0;
      AppSnackBar.showSuccess(
        context,
        isExpired
            ? '${item.name} ditandai telah habis'
            : '${item.name} ditandai telah dimasak!',
        subtitle: isExpired
            ? 'Bahan dihapus dari daftar pantry'
            : '+5 Eco Points telah ditambahkan',
      );
    }
  }

  // Buka modal tambah bahan makanan ke pantry
  void _openAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPantryItemModal(controller: _controller),
    );
  }

  // Buka modal detail bahan dan aksi kelola stok
  void _openItemDetailModal(PantryItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          PantryItemDetailModal(item: item, controller: _controller),
    );
  }

  // Buka layar notifikasi
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    ).then((_) => _controller.refreshUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _controller.groupedByExpiry;
    final urgentCount = _controller.statusCounts['urgent'] ?? 0;
    final soonCount = _controller.statusCounts['segera'] ?? 0;
    final atRiskCount = urgentCount + soonCount;
    final totalItems = _controller.items.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                AppTopBar(
                  title: 'Pantry Tracker',
                  unreadNotifications: _controller.unreadNotifications,
                  onNotificationTap: _openNotifications,
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
                          onRefresh: () => _controller.loadPantryData(),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 18),

                                AppSearchBar(
                                  controller: _searchController,
                                  hintText: 'Cari bahan makanan...',
                                  onChanged: _onSearch,
                                ),

                                const SizedBox(height: 14),

                                AppFilterChipRow(
                                  filters: _filters,
                                  selectedIndex: _selectedFilter,
                                  onChanged: _onFilterChanged,
                                ),

                                const SizedBox(height: 20),

                                // Peringatan bahan rawan kedaluwarsa
                                if (atRiskCount > 0 && _selectedFilter == 0)
                                  PantrySummaryAlert(count: atRiskCount),

                                // Tampilan kosong saat tidak ada item
                                if (totalItems == 0)
                                  AppEmptyState(
                                    padding: const EdgeInsets.fromLTRB(40, 40, 40, 150),
                                    icon: _searchController.text.isNotEmpty
                                        ? Icons.search_off_rounded
                                        : Icons.kitchen_outlined,
                                    title: _searchController.text.isNotEmpty
                                        ? 'Bahan tidak ditemukan'
                                        : 'Inventaris Dapur Kosong',
                                    message: _searchController.text.isNotEmpty
                                        ? 'Coba gunakan kata kunci lain untuk mencari bahan di pantry.'
                                        : 'Catat bahan makananmu sekarang agar tidak ada yang terbuang sia-sia.',
                                    action: _searchController.text.isEmpty
                                        ? ElevatedButton.icon(
                                            onPressed: _openAddModal,
                                            icon: const Icon(Icons.add, size: 18),
                                            label: const Text('Tambah Bahan Pertama'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              elevation: 0,
                                            ),
                                          )
                                        : null,
                                  )
                                else ...[
                                  _buildExpirySection(
                                    title: 'HARUS SEGERA (< 2 HARI)',
                                    items: grouped['urgent'] ?? [],
                                    color: AppColors.urgent,
                                  ),
                                  _buildExpirySection(
                                    title: 'SEGERA (3–5 HARI)',
                                    items: grouped['segera'] ?? [],
                                    color: AppColors.segera,
                                  ),
                                  _buildExpirySection(
                                    title: 'AMAN (> 5 HARI)',
                                    items: grouped['aman'] ?? [],
                                    color: AppColors.ecoGreen,
                                  ),
                                ],

                                if (totalItems > 0) ...[
                                  const SizedBox(height: 8),
                                  const PantryTipsCard(),
                                ],

                                const SizedBox(height: 160),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),

            // Tombol Tambah Bahan Presisi & Elegan (Floating Pill Bar)
            Positioned(
              left: 24,
              right: 24,
              bottom: 92,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openAddModal,
                  borderRadius: BorderRadius.circular(999),
                  child: Ink(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryDark,
                          AppColors.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepForest.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tambah Bahan',
                          style: AppTextStyles.button.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Seksi kelompok bahan berdasarkan urgensi kedaluwarsa (Urgent, Segera, Aman)
  Widget _buildExpirySection({
    required String title,
    required List<PantryItemModel> items,
    required Color color,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Text(
            title,
            style: AppTextStyles.sectionHeader.copyWith(
              color: color,
              fontSize: 12,
            ),
          ),
        ),
        ...items.map(
          (item) => PantryItemCard(
            item: item,
            onTap: () => _openItemDetailModal(item),
            onMarkUsed: () => _markAsUsed(item),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
