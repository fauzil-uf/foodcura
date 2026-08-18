import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_date_formatter.dart';
import '../../constants/app_typography.dart';
import '../../controllers/pantry_controller.dart';
import '../../database/db_helper.dart';
import '../../models/pantry_item_model.dart';
import '../notification/notification_screen.dart';
import '../widgets/app_top_bar.dart';
import 'widgets/add_pantry_item_modal.dart';
import 'widgets/pantry_item_detail_modal.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _controller = PantryController();
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0; // 0=Semua, 1=Urgent, 2=Segera, 3=Aman
  int _unreadNotifCount = 0;

  final List<String> _filters = [
    'Semua',
    'Urgent',
    'Segera (3-5 hari)',
    'Aman (>5 hari)',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.loadPantryData();
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

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onNotifChanged() {
    if (mounted) {
      setState(() {
        _unreadNotifCount = NotificationNotifier.instance.value;
      });
    }
  }

  void _onFilterChanged(int index) {
    _selectedFilter = index;
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

  void _onSearch(String query) {
    _controller.setSearchQuery(query);
  }

  Future<void> _markAsUsed(PantryItemModel item) async {
    if (item.id == null) return;
    await _controller.markItemUsed(item.id!);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${item.name} ditandai habis')));
    }
  }

  void _openAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddPantryItemModal(onItemAdded: () => _controller.loadPantryData()),
    );
  }

  void _openItemDetailModal(PantryItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PantryItemDetailModal(
        item: item,
        onItemUpdated: () => _controller.loadPantryData(),
      ),
    );
  }

  void refreshData() => _controller.loadPantryData();

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    ).then((_) => _controller.loadPantryData());
  }

  // Group items by status
  Map<String, List<PantryItemModel>> get _groupedItems {
    final urgentItems = <PantryItemModel>[];
    final segeraItems = <PantryItemModel>[];
    final amanItems = <PantryItemModel>[];

    for (var item in _controller.items) {
      switch (item.expiryStatus) {
        case 'expired':
        case 'urgent':
          urgentItems.add(item);
          break;
        case 'segera':
          segeraItems.add(item);
          break;
        case 'aman':
          amanItems.add(item);
          break;
      }
    }

    return {'urgent': urgentItems, 'segera': segeraItems, 'aman': amanItems};
  }

  int get _urgentAndSegeraCount {
    return _groupedItems['urgent']!.length + _groupedItems['segera']!.length;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedItems;

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            slivers: [
              // Clean Modern Top App Bar
              // Clean Modern Top App Bar
              SliverAppBar(
                pinned: true,
                floating: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: const Color(0xFFF7F5EE),
                toolbarHeight: 70,
                automaticallyImplyLeading: false,
                flexibleSpace: AppTopBar(
                  title: 'Pantry & Expiry',
                  unreadNotifications: _unreadNotifCount,
                  onNotificationTap: _openNotifications,
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search bar
                      _buildSearchBar(),
                      const SizedBox(height: 16),

                      // Filter tabs
                      _buildFilterTabs(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              if (_controller.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.ecoGreen),
                  ),
                )
              else ...[
                // Summary alert
                if (_urgentAndSegeraCount > 0 && _selectedFilter == 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSummaryAlert(),
                    ),
                  ),

                // Items
                if (_controller.items.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Urgent section
                          if (grouped['urgent']!.isNotEmpty) ...[
                            _buildSectionHeader(
                              'HARUS SEGERA (< 2 HARI)',
                              AppColors.urgent,
                            ),
                            ...grouped['urgent']!.map(
                              (item) => _buildItemCard(item),
                            ),
                          ],

                          // Segera section
                          if (grouped['segera']!.isNotEmpty) ...[
                            _buildSectionHeader(
                              'SEGERA (3–5 HARI)',
                              AppColors.segera,
                            ),
                            ...grouped['segera']!.map(
                              (item) => _buildItemCard(item),
                            ),
                          ],

                          // Aman section
                          if (grouped['aman']!.isNotEmpty) ...[
                            _buildSectionHeader(
                              'AMAN (> 5 HARI)',
                              AppColors.ecoGreen,
                            ),
                            ...grouped['aman']!.map(
                              (item) => _buildItemCard(item),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Tips Food Rescue
                          _buildTipsCard(),

                          const SizedBox(height: 180),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),

          // FAB - Tambah Bahan
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 90,
            child: GestureDetector(
              onTap: _openAddModal,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Tambah Bahan',
                      style: AppTextStyles.buttonSmall.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surfaceDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: AppColors.textGray, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: AppTextStyles.body.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari bahan makanan...',
                hintStyle: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  color: AppColors.textGray,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textGray,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryAlert() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBgLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.segera.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: AppColors.segera,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_urgentAndSegeraCount bahan perlu segera digunakan',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepForest,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gunakan sebelum kadaluwarsa untuk mengurangi food waste.',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: AppTextStyles.sectionHeader.copyWith(color: color, fontSize: 12),
      ),
    );
  }

  Widget _buildItemCard(PantryItemModel item) {
    final days = item.daysUntilExpiry;
    Color statusColor;
    switch (item.expiryStatus) {
      case 'expired':
      case 'urgent':
        statusColor = AppColors.urgent;
        break;
      case 'segera':
        statusColor = AppColors.segera;
        break;
      default:
        statusColor = AppColors.ecoGreen;
    }

    final expiryLabel = days < 0
        ? 'Kadaluwarsa'
        : days == 0
        ? 'Hari ini'
        : '$days hari lagi';

    final formattedDate = AppDateFormatter.formatShortDate(item.expiryDate);

    return GestureDetector(
      onTap: () => _openItemDetailModal(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _buildImagePlaceholder(item.name),
                    )
                  : _buildImagePlaceholder(item.name),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + chevron
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepForest,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textGray,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Quantity + storage
                  Text(
                    item.quantityDisplay,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Progress bar + days
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: item.expiryProgress.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            expiryLabel,
                            style: AppTextStyles.badgeText.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            '($formattedDate)',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tandai Habis button
                  GestureDetector(
                    onTap: () => _markAsUsed(item),
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.ecoGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tandai Habis',
                            style: AppTextStyles.buttonSmall.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildImagePlaceholder(String name) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.mintTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppTextStyles.avatarInitial.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.ecoGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintTint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.ecoGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Food Rescue',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepForest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gunakan bahan yang paling dekat tanggal kadaluwarsa untuk mengurangi food waste.',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.deepForest.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 140),
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
                Icons.inventory_2_outlined,
                size: 40,
                color: AppColors.ecoGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pantry Kosong',
              style: AppTextStyles.headlineMd.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.deepForest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan bahan makanan ke pantry\nuntuk memantau tanggal kadaluwarsa.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontSize: 13,
                color: AppColors.textGray,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
