import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_date_formatter.dart';
import '../../constants/app_typography.dart';
import '../../database/db_helper.dart';
import '../../models/food_item_model.dart';
import '../../models/pantry_item_model.dart';

class AddPantryItemModal extends StatefulWidget {
  final VoidCallback onItemAdded;

  const AddPantryItemModal({super.key, required this.onItemAdded});

  @override
  State<AddPantryItemModal> createState() => _AddPantryItemModalState();
}

class _AddPantryItemModalState extends State<AddPantryItemModal> {
  final DBHelper _db = DBHelper();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String _selectedUnit = 'g';
  String _selectedStorage = 'Kulkas';
  DateTime? _selectedDate;
  bool _saving = false;

  // Auto-suggest
  List<FoodItemModel> _suggestions = [];
  bool _showSuggestions = false;
  FoodItemModel? _selectedFood;

  final List<String> _units = ['g', 'kg', 'ml', 'L', 'pcs'];
  final List<String> _storages = ['Kulkas', 'Freezer', 'Suhu Ruang'];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _searchFoodCatalog(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final results = await _db.searchFoodCatalog(query);
    setState(() {
      _suggestions = results.take(5).toList();
      _showSuggestions = results.isNotEmpty;
    });
  }

  void _selectSuggestion(FoodItemModel food) {
    setState(() {
      _nameController.text = food.name;
      _selectedFood = food;
      _showSuggestions = false;
      _suggestions = [];
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.deepForest,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final quantityText = _quantityController.text.trim();

    if (name.isEmpty) {
      _showError('Masukkan nama bahan');
      return;
    }
    if (quantityText.isEmpty) {
      _showError('Masukkan jumlah');
      return;
    }
    if (_selectedDate == null) {
      _showError('Pilih tanggal kadaluwarsa');
      return;
    }

    final quantity = double.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      _showError('Jumlah tidak valid');
      return;
    }

    setState(() => _saving = true);

    // Try to find image URL from food catalog
    String? imageUrl;
    if (_selectedFood != null) {
      imageUrl = _selectedFood!.imagePath;
    } else {
      final catalogMatch = await _db.searchFoodCatalog(name);
      if (catalogMatch.isNotEmpty) {
        imageUrl = catalogMatch.first.imagePath;
      }
    }

    final item = PantryItemModel(
      name: name,
      quantity: quantity,
      unit: _selectedUnit,
      storage: _selectedStorage,
      expiryDate: _selectedDate!,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    await _db.addPantryItem(item);

    setState(() => _saving = false);

    if (mounted) {
      widget.onItemAdded();
      Navigator.pop(context);

      final days = item.daysUntilExpiry;
      if (days <= 5) {
        final alertColor = days <= 2 ? AppColors.urgent : AppColors.segera;
        final alertTitle = days <= 2 ? '$name hampir kadaluwarsa!' : '$name perlu segera digunakan!';
        final alertMsg = 'Kadaluwarsa dalam $days hari (${AppDateFormatter.formatShortDate(item.expiryDate)}).';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: alertColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alertTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alertMsg,
                        style: TextStyle(
                          fontSize: 12,
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name berhasil ditambahkan ke pantry')),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.urgent),
    );
  }

  String get _formattedDate {
    if (_selectedDate == null) return '';
    return AppDateFormatter.formatShortDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
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

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tambah Bahan',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepForest,
                      ),
                    ),
                    SizedBox(height: 2),
                    const Text(
                      'Tambahkan bahan ke Pantry',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
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

          // Form content (scrollable)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama bahan
                  _buildLabel('Nama bahan'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _nameController,
                    placeholder: 'Contoh: Bayam',
                    onChanged: _searchFoodCatalog,
                  ),
                  if (_showSuggestions && _suggestions.isNotEmpty)
                    _buildSuggestionsList(),
                  const SizedBox(height: 16),

                  // Jumlah + Unit
                  _buildLabel('Jumlah'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _quantityController,
                          placeholder: '0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 90,
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceDim),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedUnit,
                            isExpanded: true,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              color: AppColors.deepForest,
                            ),
                            items: _units.map((u) {
                              return DropdownMenuItem(value: u, child: Text(u));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedUnit = v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tanggal kadaluwarsa
                  _buildLabel('Tanggal kadaluwarsa'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceDim),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? _formattedDate
                                  : 'Pilih tanggal',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                color: _selectedDate != null
                                    ? AppColors.deepForest
                                    : AppColors.textGray,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: AppColors.textGray,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lokasi penyimpanan
                  _buildLabel('Lokasi penyimpanan'),
                  const SizedBox(height: 6),
                  Row(
                    children: _storages.map((storage) {
                      final isSelected = _selectedStorage == storage;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedStorage = storage),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(
                              right: storage != _storages.last ? 8 : 0,
                            ),
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.mintTint
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.ecoGreen
                                    : AppColors.surfaceDim,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                storage,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.ecoGreen
                                      : AppColors.textGray,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Footer action button
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _saving
                      ? AppColors.primary.withValues(alpha: 0.6)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Tambah Bahan',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.deepForest,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceDim),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          color: AppColors.deepForest,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: AppColors.textGray,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final food = _suggestions[index];
          return ListTile(
            dense: true,
            title: Text(
              food.name,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.deepForest,
              ),
            ),
            subtitle: Text(
              '${food.calories} kcal · P:${food.protein.toStringAsFixed(1)}g · K:${food.carbs.toStringAsFixed(1)}g · L:${food.fat.toStringAsFixed(1)}g',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                color: AppColors.textGray,
              ),
            ),
            onTap: () => _selectSuggestion(food),
          );
        },
      ),
    );
  }
}
