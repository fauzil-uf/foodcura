import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_date_formatter.dart';
import '../../../constants/app_typography.dart';
import '../../../database/db_helper.dart';
import '../../../models/food_item_model.dart';
import '../../../models/food_log_model.dart';
import '../../widgets/app_food_image.dart';

class AddFoodModal extends StatefulWidget {
  final String initialMealType;
  final DateTime? targetDate;
  final VoidCallback onFoodAdded;

  const AddFoodModal({
    super.key,
    required this.initialMealType,
    this.targetDate,
    required this.onFoodAdded,
  });

  @override
  State<AddFoodModal> createState() => _AddFoodModalState();
}

class _AddFoodModalState extends State<AddFoodModal> {
  late String _selectedMeal;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<FoodItemModel> _catalogFoods = [];
  List<FoodItemModel> _recentFoods = [];
  List<FoodItemModel> _displayedFoods = [];
  FoodItemModel? _selectedFood;
  bool _loading = true;
  bool _isSearching = false;

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
    _selectedMeal = widget.initialMealType;
    _loadData();
  }

  Future<void> _loadData() async {
    final catalog = await DBHelper().getFoodCatalog();
    final recent = await DBHelper().getRecentAddedFoods(limit: 6);
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

  void _filterFoods(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _isSearching = false;
        _displayedFoods = _recentFoods;
      } else {
        _isSearching = true;
        _displayedFoods = _catalogFoods
            .where(
              (f) =>
                  f.name.toLowerCase().contains(query.toLowerCase()) ||
                  f.category.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
      if (_displayedFoods.isNotEmpty &&
          (_selectedFood == null || !_displayedFoods.contains(_selectedFood))) {
        _selectedFood = _displayedFoods.first;
      }
    });
  }

  Future<void> _saveFoodLog() async {
    if (_selectedFood == null) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final log = FoodLogModel(
      foodName: _selectedFood!.name,
      mealType: _selectedMeal,
      calories: _selectedFood!.calories,
      protein: _selectedFood!.protein,
      carbs: _selectedFood!.carbs,
      fat: _selectedFood!.fat,
      imagePath: _selectedFood!.imagePath,
      time: timeStr,
      date: AppDateFormatter.formatToday(widget.targetDate ?? now),
      note: _noteController.text.trim(),
    );

    final notif = await DBHelper().addFoodLog(log);
    widget.onFoodAdded();
    if (mounted) {
      Navigator.pop(context);

      if (notif != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.urgent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notif.title, style: AppTextStyles.buttonSmall),
                      const SizedBox(height: 2),
                      Text(
                        notif.message,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
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
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle bar
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  Text(
                    'Tambah Makanan',
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textGray),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Input Bar
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textGray),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterFoods,
                        style: AppTextStyles.body.copyWith(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Cari makanan...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fitur Scan Barcode & Foto Makanan belum tersedia',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.mintTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Pick Horizontally Scrollable Section
              Text(
                _isSearching
                    ? 'Hasil Pencarian (${_displayedFoods.length})'
                    : 'Terakhir Ditambahkan',
                style: AppTextStyles.label.copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
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
                                  width: 60,
                                  height: 60,
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
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      food.imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                  Icons.fastfood,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 64,
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
              const SizedBox(height: 16),

              // Select Meal Category Grid
              Text(
                'Pilih Waktu Makan',
                style: AppTextStyles.label.copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih waktu saat kamu mengonsumsi makanan ini.',
                style: AppTextStyles.subtitleSmall,
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: (meal['bg'] as Color),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    meal['icon'] as IconData,
                                    size: 18,
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
                                        : FontWeight.w600,
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
              const SizedBox(height: 16),

              // Selected Food Summary Card
              if (_selectedFood != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      AppFoodImage(
                        imagePath: _selectedFood!.imagePath,
                        width: 44,
                        height: 44,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFood!.name,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Protein ${_selectedFood!.protein}g · Karbo ${_selectedFood!.carbs}g · Lemak ${_selectedFood!.fat}g',
                              style: AppTextStyles.subtitleSmall.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_selectedFood!.calories} kcal',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Optional Notes Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Catatan (opsional)',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${_noteController.text.length}/100',
                    style: AppTextStyles.subtitleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLength: 100,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tambahkan catatan...',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _saveFoodLog,
                  child: Text(
                    'Lanjutkan',
                    style: AppTextStyles.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
}
