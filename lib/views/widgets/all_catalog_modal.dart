import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_date_formatter.dart';
import '../../constants/app_typography.dart';
import '../../database/db_helper.dart';
import '../../models/food_item_model.dart';
import '../../models/food_log_model.dart';
import 'app_food_image.dart';

class AllCatalogModal extends StatefulWidget {
  final String currentMealType;
  final VoidCallback onFoodAdded;

  const AllCatalogModal({
    super.key,
    required this.currentMealType,
    required this.onFoodAdded,
  });

  @override
  State<AllCatalogModal> createState() => _AllCatalogModalState();
}

class _AllCatalogModalState extends State<AllCatalogModal> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodItemModel> _allCatalog = [];
  List<FoodItemModel> _filteredCatalog = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final list = await DBHelper().getFoodCatalog();
    if (mounted) {
      setState(() {
        _allCatalog = list;
        _filteredCatalog = list;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredCatalog = _allCatalog;
      } else {
        _filteredCatalog = _allCatalog
            .where(
              (item) =>
                  item.name.toLowerCase().contains(query.toLowerCase()) ||
                  item.category.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _addFoodToLog(FoodItemModel food) async {
    final newLog = FoodLogModel(
      foodName: food.name,
      mealType: widget.currentMealType,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      imagePath: food.imagePath,
      time: AppDateFormatter.formatTime(),
      date: AppDateFormatter.formatToday(),
    );

    await DBHelper().addFoodLog(newLog);
    widget.onFoodAdded();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${food.name} berhasil ditambahkan ke ${widget.currentMealType}!',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Semua Makanan & Minuman',
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
          Text(
            'Daftar lengkap database makanan (${_filteredCatalog.length} item)',
            style: AppTextStyles.subtitleSmall,
          ),
          const SizedBox(height: 14),

          // Search Bar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textGray),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: AppTextStyles.body.copyWith(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Cari makanan, minuman, atau bahan...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List of Catalog Items
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCatalog.isEmpty
                ? Center(
                    child: Text(
                      'Makanan tidak ditemukan',
                      style: AppTextStyles.subtitle,
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredCatalog.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final food = _filteredCatalog[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            AppFoodImage(
                              imagePath: food.imagePath,
                              width: 56,
                              height: 56,
                              borderRadius: 14,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food.name,
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Protein ${food.protein}g · Karbo ${food.carbs}g · Lemak ${food.fat}g',
                                    style: AppTextStyles.subtitleSmall.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.infoContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      food.category,
                                      style: AppTextStyles.label.copyWith(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${food.calories}',
                                  style: AppTextStyles.heading2.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'kcal',
                                  style: AppTextStyles.subtitleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _addFoodToLog(food),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
