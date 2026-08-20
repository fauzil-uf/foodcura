import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_date_formatter.dart';
import '../../../constants/app_typography.dart';
import '../../../database/db_helper.dart';
import '../../../models/pantry_item_model.dart';
import '../../widgets/app_food_image.dart';
import 'add_pantry_item_modal.dart';

class PantryItemDetailModal extends StatefulWidget {
  final PantryItemModel item;
  final VoidCallback onItemUpdated;

  const PantryItemDetailModal({
    super.key,
    required this.item,
    required this.onItemUpdated,
  });

  @override
  State<PantryItemDetailModal> createState() => _PantryItemDetailModalState();
}

class _PantryItemDetailModalState extends State<PantryItemDetailModal> {
  final DBHelper _db = DBHelper();
  late PantryItemModel _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
  }

  /// Menandai bahan makanan telah digunakan/dimasak dan memperbarui data inventaris.
  Future<void> _markAsUsed() async {
    if (_currentItem.id != null) {
      final savedItem = _currentItem;
      await _db.markPantryItemUsed(_currentItem.id!);

      if (mounted) {
        widget.onItemUpdated();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${savedItem.name} berhasil ditandai telah dimasak/digunakan.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// Menampilkan dialog konfirmasi sebelum menghapus bahan makanan dari database SQLite.
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Hapus Bahan Makanan',
              style: AppTextStyles.heading2.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.deepForest,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 13.5,
                  color: AppColors.textGray,
                  height: 1.45,
                ),
                children: [
                  const TextSpan(text: 'Apakah Anda yakin ingin menghapus '),
                  TextSpan(
                    text: _currentItem.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepForest,
                    ),
                  ),
                  const TextSpan(
                    text: ' dari pantry? Data yang dihapus tidak dapat dikembalikan.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Batal',
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      'Hapus',
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true && _currentItem.id != null) {
      await _db.deletePantryItem(_currentItem.id!);
      if (mounted) {
        widget.onItemUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_currentItem.name} telah dihapus'),
            backgroundColor: AppColors.urgent,
          ),
        );
      }
    }
  }

  /// Membuka modal edit form untuk memperbarui data stok atau tanggal kedaluwarsa bahan.
  void _openEditModal() {
    Navigator.pop(context); // Close detail modal first
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPantryItemModal(
        itemToEdit: _currentItem,
        onItemAdded: widget.onItemUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _currentItem.daysUntilExpiry;

    Color statusColor;
    Color statusBgColor;
    String statusLabel;

    switch (_currentItem.expiryStatus) {
      case 'expired':
        statusColor = AppColors.urgent;
        statusBgColor = AppColors.warningBg;
        statusLabel = 'KADALUWARSA';
        break;
      case 'urgent':
        statusColor = AppColors.urgent;
        statusBgColor = AppColors.warningBg;
        statusLabel = 'HARUS SEGERA (< 2 HARI)';
        break;
      case 'segera':
        statusColor = AppColors.segera;
        statusBgColor = AppColors.warningBgLight;
        statusLabel = 'SEGERA (3-5 HARI)';
        break;
      case 'aman':
      default:
        statusColor = AppColors.ecoGreen;
        statusBgColor = AppColors.mintTint;
        statusLabel = 'AMAN (> 5 HARI)';
        break;
    }

    final formattedExpiry = AppDateFormatter.formatToday(
      _currentItem.expiryDate,
    );
    final formattedCreated = AppDateFormatter.formatToday(
      _currentItem.createdAt,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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

          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail Bahan Makanan',
                  style: AppTextStyles.headlineMd.copyWith(
                    fontSize: 18,
                    color: AppColors.deepForest,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textGray,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.surfaceDim),

          // Content Scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Hero Info
                  Row(
                    children: [
                      // Image / Avatar
                      AppFoodImage(
                        imagePath: _currentItem.imageUrl,
                        width: 80,
                        height: 80,
                        borderRadius: 20,
                        fallbackIcon: Icons.kitchen_rounded,
                      ),
                      const SizedBox(width: 16),

                      // Name + Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusLabel,
                                style: AppTextStyles.badgeText.copyWith(
                                  fontSize: 10,
                                  color: statusColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _currentItem.name,
                              style: AppTextStyles.heading1.copyWith(
                                fontSize: 20,
                                color: AppColors.deepForest,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Jumlah: ${_currentItem.quantityDisplay}',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Expiry Status Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: statusColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  days < 0
                                      ? 'Telah Kadaluwarsa'
                                      : days == 0
                                      ? 'Kadaluwarsa Hari Ini'
                                      : 'Sisa $days Hari Lagi',
                                  style: AppTextStyles.badgeText.copyWith(
                                    fontSize: 14,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              formattedExpiry,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepForest,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _currentItem.expiryProgress.clamp(
                              0.0,
                              1.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Detail Info List
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.surfaceDim),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.kitchen_outlined,
                          label: 'Tempat Penyimpanan',
                          value: _currentItem.storage,
                        ),
                        const Divider(height: 20, color: AppColors.surfaceDim),
                        _buildInfoRow(
                          icon: Icons.scale_outlined,
                          label: 'Jumlah / Kuantitas',
                          value: _currentItem.quantityDisplay,
                        ),
                        const Divider(height: 20, color: AppColors.surfaceDim),
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Tanggal Ditambahkan',
                          value: formattedCreated,
                        ),
                        const Divider(height: 20, color: AppColors.surfaceDim),
                        _buildInfoRow(
                          icon: Icons.event_busy_outlined,
                          label: 'Tanggal Kadaluwarsa',
                          value: formattedExpiry,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                top: BorderSide(color: AppColors.surfaceDim),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primary: Tandai Habis
                GestureDetector(
                  onTap: _markAsUsed,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.ecoGreen,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ecoGreen.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text('Tandai Habis', style: AppTextStyles.buttonSmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Secondary: Edit & Delete Row
                Row(
                  children: [
                    // Edit Button
                    Expanded(
                      child: GestureDetector(
                        onTap: _openEditModal,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.surfaceDim),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.edit_outlined,
                                color: AppColors.deepForest,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Edit Bahan',
                                style: AppTextStyles.buttonSmall.copyWith(
                                  fontSize: 13,
                                  color: AppColors.deepForest,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Delete Button
                    Expanded(
                      child: GestureDetector(
                        onTap: _confirmDelete,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.urgent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.delete_outline,
                                color: AppColors.urgent,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Hapus Bahan',
                                style: AppTextStyles.buttonSmall.copyWith(
                                  fontSize: 13,
                                  color: AppColors.urgent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textGray),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 13,
              color: AppColors.textGray,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.badgeText.copyWith(
            fontSize: 13,
            color: AppColors.deepForest,
          ),
        ),
      ],
    );
  }
}
