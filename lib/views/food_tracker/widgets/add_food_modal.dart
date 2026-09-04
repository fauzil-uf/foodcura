import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_date_formatter.dart';
import '../../../constants/app_food_formatter.dart';
import '../../../constants/app_typography.dart';
import '../../../controllers/food_tracker_controller.dart';
import '../../../models/food_item_model.dart';
import '../../../models/food_log_model.dart';
import '../../widgets/app_food_image.dart';
import '../../widgets/app_snack_bar.dart';

// Modal catat makanan baru ke log harian
class AddFoodModal extends StatefulWidget {
  final String initialMealType;
  final DateTime? targetDate;
  final FoodTrackerController? controller;
  final VoidCallback? onFoodAdded;
  final List<FoodItemModel>? recentFoods;

  const AddFoodModal({
    super.key,
    required this.initialMealType,
    this.targetDate,
    this.controller,
    this.onFoodAdded,
    this.recentFoods,
  });

  @override
  State<AddFoodModal> createState() => _AddFoodModalState();
}

class _AddFoodModalState extends State<AddFoodModal> {
  late final FoodTrackerController _controller;
  late String _selectedMeal;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<FoodItemModel> _catalogFoods = [];
  List<FoodItemModel> _recentFoods = [];
  List<FoodItemModel> _displayedFoods = [];
  FoodItemModel? _selectedFood;
  bool _loading = true;
  bool _isSearching = false;
  bool _isSubmitting = false;
  double _portion = 1.0;

  final List<Map<String, dynamic>> _mealTypes = [
    {
      'name': 'Sarapan',
      'icon': Icons.wb_twilight_rounded,
      'color': AppColors.seaGreen,
      'bg': AppColors.nutriProteinBg,
    },
    {
      'name': 'Makan Siang',
      'icon': Icons.light_mode_rounded,
      'color': AppColors.segera,
      'bg': AppColors.nutriCalorieBg,
    },
    {
      'name': 'Makan Malam',
      'icon': Icons.nights_stay_rounded,
      'color': AppColors.urgent,
      'bg': AppColors.nutriCarbBg,
    },
    {
      'name': 'Camilan',
      'icon': Icons.tapas_rounded,
      'color': AppColors.infoBlue,
      'bg': AppColors.nutriFatBg,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? FoodTrackerController();
    _selectedMeal = widget.initialMealType;
    _loadData();
  }

  // Muat katalog makanan dan riwayat makanan terakhir ditambahkan
  Future<void> _loadData() async {
    final catalog = await _controller.getFoodCatalog();
    final recent =
        widget.recentFoods ?? await _controller.getRecentAddedFoods(limit: 6);
    if (mounted) {
      setState(() {
        _catalogFoods = catalog;
        _recentFoods = recent;
        _displayedFoods = recent;
        _selectedFood = recent.isNotEmpty
            ? recent.first
            : (catalog.isNotEmpty ? catalog.first : null);
        _loading = false;
      });
    }
  }

  // Filter daftar makanan yang ditampilkan berdasarkan kata kunci pencarian
  void _filterFoods(String query) {
    setState(() {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) {
        _isSearching = false;
        _displayedFoods = _recentFoods;
      } else {
        _isSearching = true;
        _displayedFoods = _catalogFoods
            .where(
              (f) =>
                  f.name.toLowerCase().contains(q) ||
                  f.category.toLowerCase().contains(q),
            )
            .take(25)
            .toList();
      }
      if (_displayedFoods.isNotEmpty) {
        if (_selectedFood == null || !_displayedFoods.contains(_selectedFood)) {
          _selectedFood = _displayedFoods.first;
        }
      } else {
        _selectedFood = null;
      }
    });
  }

  // Simpan log makanan baru ke database SQLite
  Future<void> _saveFoodLog() async {
    if (_selectedFood == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final cal = (_selectedFood!.calories * _portion).round();
      final prot = double.parse((_selectedFood!.protein * _portion).toStringAsFixed(1));
      final carbs = double.parse((_selectedFood!.carbs * _portion).toStringAsFixed(1));
      final fat = double.parse((_selectedFood!.fat * _portion).toStringAsFixed(1));
      final chol = double.parse((_selectedFood!.cholesterol * _portion).toStringAsFixed(1));
      final foodDisplayName = AppFoodFormatter.formatFoodWithPortion(
        _selectedFood!.name,
        _portion,
      );

      final log = FoodLogModel(
        foodName: foodDisplayName,
        mealType: _selectedMeal,
        calories: cal,
        protein: prot,
        carbs: carbs,
        fat: fat,
        cholesterol: chol,
        imagePath: _selectedFood!.imagePath,
        time: AppDateFormatter.formatTime(),
        date: AppDateFormatter.formatToday(widget.targetDate ?? now),
        note: _noteController.text.trim(),
      );

      final notif = await _controller.addFoodLog(log);
      widget.onFoodAdded?.call();
      if (mounted) {
        Navigator.pop(context);

        if (notif != null) {
          AppSnackBar.showWarning(
            context,
            title: notif.title,
            message: notif.message,
          );
        } else {
          AppSnackBar.showSuccess(
            context,
            '$foodDisplayName Ditambahkan!',
            subtitle: '$cal kcal dicatat ke $_selectedMeal',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Statis (Handle + Judul + Tombol Tutup)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    Text(
                      'Tambah Makanan',
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, color: AppColors.textGray, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Konten Scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Search Bar
                  Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.textGray, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterFoods,
                            style: AppTextStyles.body.copyWith(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Cari makanan...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            AppSnackBar.showInfo(
                              context,
                              'Fitur Scan Barcode & Foto Makanan segera hadir!',
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.mintTint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Terakhir Ditambahkan / Hasil Pencarian
                  Text(
                    _isSearching
                        ? 'Hasil Pencarian (${_displayedFoods.length})'
                        : 'Terakhir Ditambahkan',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 86,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _displayedFoods.isEmpty
                        ? Center(
                            child: Text(
                              'Makanan "${_searchController.text}" tidak ditemukan',
                              style: AppTextStyles.subtitleSmall,
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _displayedFoods.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final food = _displayedFoods[index];
                              final isSelected = _selectedFood?.name == food.name;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFood = food;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: AppFoodImage(
                                        imagePath: food.imagePath,
                                        width: 56,
                                        height: 56,
                                        borderRadius: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 62,
                                      child: Text(
                                        food.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.subtitleSmall.copyWith(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Pilih Waktu Makan
                  Text(
                    'Pilih Waktu Makan',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _mealTypes.length,
                    itemBuilder: (context, index) {
                      final meal = _mealTypes[index];
                      final isSelected = _selectedMeal == meal['name'];
                      final color = meal['color'] as Color;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMeal = meal['name'] as String;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (meal['bg'] as Color)
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? color : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              if (isSelected)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: (meal['bg'] as Color),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        meal['icon'] as IconData,
                                        size: 16,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      meal['name'] as String,
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? color
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // 4. Kartu Makanan Terpilih & Pengaturan Porsi (Desain Rapi Menyatu)
                  if (_selectedFood != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              AppFoodImage(
                                imagePath: _selectedFood!.imagePath,
                                width: 44,
                                height: 44,
                                borderRadius: 12,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedFood!.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'P ${(_selectedFood!.protein * _portion).toStringAsFixed(1)}g · K ${(_selectedFood!.carbs * _portion).toStringAsFixed(1)}g · L ${(_selectedFood!.fat * _portion).toStringAsFixed(1)}g',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.subtitleSmall.copyWith(
                                        fontSize: 11,
                                        color: AppColors.textGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Stepper Porsi Elegan
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: _portion > 0.5
                                          ? () => setState(() => _portion = _portion - 0.5)
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: _portion > 0.5
                                              ? AppColors.textPrimary
                                              : AppColors.textGray.withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Text(
                                        '${_portion % 1 == 0 ? _portion.toInt() : _portion}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: _portion < 10.0
                                          ? () => setState(() => _portion = _portion + 0.5)
                                          : null,
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.add,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.mintTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Energi (${_portion % 1 == 0 ? _portion.toInt() : _portion} porsi)',
                                  style: AppTextStyles.subtitleSmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.ecoGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${(_selectedFood!.calories * _portion).round()} kcal',
                                  style: AppTextStyles.label.copyWith(
                                    fontSize: 13,
                                    color: AppColors.ecoGreen,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),

                  // 5. Catatan (opsional)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Catatan (opsional)',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_noteController.text.length}/100',
                        style: AppTextStyles.subtitleSmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteController,
                    maxLength: 100,
                    maxLines: 1,
                    onChanged: (_) => setState(() {}),
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tambahkan catatan...',
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. Tombol Lanjutkan
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_selectedFood == null || _isSubmitting)
                            ? AppColors.surfaceContainerHigh
                            : AppColors.primary,
                        foregroundColor: (_selectedFood == null || _isSubmitting)
                            ? AppColors.textGray
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: (_selectedFood == null || _isSubmitting) ? 0 : 1,
                      ),
                      onPressed: (_selectedFood == null || _isSubmitting)
                          ? null
                          : _saveFoodLog,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _selectedFood == null
                                  ? 'Pilih Makanan'
                                  : 'Lanjutkan',
                              style: AppTextStyles.button.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
