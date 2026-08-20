import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_date_formatter.dart';
import '../../../constants/app_typography.dart';
import '../../../database/db_helper.dart';
import '../../../database/pantry_grocery_catalog.dart';
import '../../../models/pantry_ingredient_model.dart';
import '../../../models/pantry_item_model.dart';
import '../../widgets/app_food_image.dart';

/// Modal untuk menambah dan mengedit bahan makanan mentah di dalam inventaris dapur (Pantry).
class AddPantryItemModal extends StatefulWidget {
  final VoidCallback onItemAdded;
  final PantryItemModel? itemToEdit;

  const AddPantryItemModal({
    super.key,
    required this.onItemAdded,
    this.itemToEdit,
  });

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
  String? _selectedImageUrl;
  bool _saving = false;

  // Auto-suggest khusus bahan baku mentah
  List<PantryIngredientModel> _suggestions = [];
  bool _showSuggestions = false;

  final List<String> _units = [
    'g',
    'kg',
    'ml',
    'L',
    'pcs',
    'ikat',
    'butir',
    'pack',
    'kaleng',
    'botol',
    'jar',
    'bungkus',
    'sisir',
    'papan',
    'box',
  ];
  final List<String> _storages = ['Kulkas', 'Freezer', 'Suhu Ruang'];

  // Rekomendasi Bahan Populer
  static const List<String> _popularIngredients = [
    'Susu UHT Plain',
    'Keju Cheddar Block',
    'Telur Ayam Ras',
    'Sarden Saus Tomat Kaleng',
    'Mentega / Butter',
    'Bayam Segar',
    'Dada Ayam Fillet',
    'Pasta Spaghetti',
    'Tomat Merah',
    'Tahu Putih / Sutra',
    'Bawang Merah',
    'Madu Murni Asli',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _nameController.text = item.name;
      _quantityController.text = item.quantity % 1 == 0
          ? item.quantity.toInt().toString()
          : item.quantity.toString();
      _selectedUnit = _units.contains(item.unit) ? item.unit : 'g';
      _selectedStorage = _storages.contains(item.storage)
          ? item.storage
          : 'Kulkas';
      _selectedDate = item.expiryDate;
      _selectedImageUrl = item.imageUrl;
    } else {
      // Nilai kuantitas awal default 1 agar tidak kosong
      _quantityController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _searchIngredients(String query) {
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final results = PantryGroceryCatalog.search(query);
    setState(() {
      _suggestions = results.take(5).toList();
      _showSuggestions = results.isNotEmpty;
    });
  }

  void _selectIngredient(PantryIngredientModel ing) {
    setState(() {
      _nameController.text = ing.name;
      _selectedStorage = _storages.contains(ing.defaultStorage)
          ? ing.defaultStorage
          : 'Kulkas';
      _selectedUnit = _units.contains(ing.defaultUnit) ? ing.defaultUnit : 'g';
      _selectedDate = DateTime.now().add(
        Duration(days: ing.defaultShelfLifeDays),
      );
      _selectedImageUrl = ing.imageUrl;
      if (_quantityController.text.trim().isEmpty ||
          _quantityController.text.trim() == '0') {
        _quantityController.text = '1';
      }
      _showSuggestions = false;
      _suggestions = [];
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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
      _showError('Masukkan nama bahan makanan');
      return;
    }
    if (quantityText.isEmpty) {
      _showError('Masukkan jumlah kuantitas bahan');
      return;
    }
    if (_selectedDate == null) {
      _showError('Pilih tanggal kedaluwarsa');
      return;
    }

    final quantity = double.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      _showError('Jumlah kuantitas tidak valid');
      return;
    }

    setState(() => _saving = true);

    // Auto resolve image from catalog if not already attached
    final resolvedImage =
        _selectedImageUrl ??
        widget.itemToEdit?.imageUrl ??
        PantryGroceryCatalog.getImageFor(name);

    final item = PantryItemModel(
      id: widget.itemToEdit?.id,
      userId: widget.itemToEdit?.userId,
      name: name,
      quantity: quantity,
      unit: _selectedUnit,
      storage: _selectedStorage,
      expiryDate: _selectedDate!,
      imageUrl: resolvedImage,
      createdAt: widget.itemToEdit?.createdAt ?? DateTime.now(),
    );

    if (widget.itemToEdit != null) {
      await _db.updatePantryItem(item);
    } else {
      await _db.addPantryItem(item);
    }

    setState(() => _saving = false);

    if (mounted) {
      widget.onItemAdded();
      Navigator.pop(context);

      if (widget.itemToEdit != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name berhasil diperbarui')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name berhasil ditambahkan ke inventaris Pantry!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.urgent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final quantityVal = double.tryParse(_quantityController.text.trim());
    final isQtyInvalid = _quantityController.text.trim().isNotEmpty &&
        (quantityVal == null || quantityVal <= 0);
    final isQtyValid = quantityVal != null && quantityVal > 0;
    final isNameValid = _nameController.text.trim().isNotEmpty;
    final isDateValid = _selectedDate != null;
    final isFormValid = isNameValid && isQtyValid && isDateValid;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.itemToEdit != null
                      ? 'Edit Bahan Dapur'
                      : 'Tambah Stok Dapur',
                  style: AppTextStyles.headlineMd.copyWith(
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

          // Form content (scrollable)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rekomendasi Bahan Populer (Khusus saat tambah baru)
                  if (widget.itemToEdit == null) ...[
                    _buildLabel('Rekomendasi Bahan Populer'),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _popularIngredients.map((name) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              backgroundColor: AppColors.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: AppColors.borderSoft,
                                ),
                              ),
                              label: Text(
                                name,
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 11.5,
                                  color: AppColors.deepForest,
                                ),
                              ),
                              onPressed: () {
                                final matches = PantryGroceryCatalog.search(
                                  name,
                                );
                                if (matches.isNotEmpty) {
                                  _selectIngredient(matches.first);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Nama bahan
                  _buildLabel('Nama Bahan Makanan'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (_selectedImageUrl != null &&
                          _selectedImageUrl!.isNotEmpty) ...[
                        AppFoodImage(
                          imagePath: _selectedImageUrl,
                          width: 48,
                          height: 48,
                          borderRadius: 12,
                          fallbackIcon: Icons.eco_rounded,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: _buildTextField(
                          controller: _nameController,
                          placeholder:
                              'Contoh: Susu UHT, Keju, Dada Ayam, Tomat',
                          onChanged: _searchIngredients,
                        ),
                      ),
                    ],
                  ),
                  if (_showSuggestions && _suggestions.isNotEmpty)
                    _buildSuggestionsList(),
                  const SizedBox(height: 16),

                  // Jumlah + Unit dengan Stepper yang Jelas
                  _buildLabel('Jumlah & Satuan'),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Counter Jumlah (+/-)
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: isQtyInvalid
                                ? AppColors.warningBg
                                : AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isQtyInvalid
                                  ? AppColors.error
                                  : AppColors.surfaceDim,
                              width: isQtyInvalid ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Tombol Kurang (-)
                              InkWell(
                                onTap: () {
                                  final current =
                                      double.tryParse(
                                        _quantityController.text,
                                      ) ??
                                      1;
                                  if (current > 1) {
                                    final nextVal = current - 1;
                                    _quantityController.text = nextVal % 1 == 0
                                        ? nextVal.toInt().toString()
                                        : nextVal.toString();
                                    setState(() {});
                                  }
                                },
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(16),
                                ),
                                child: const SizedBox(
                                  width: 40,
                                  height: 48,
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              // Field Input Angka Jelas
                              Expanded(
                                child: TextField(
                                  controller: _quantityController,
                                  textAlign: TextAlign.center,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: AppTextStyles.bodyMd.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: isQtyInvalid
                                        ? AppColors.error
                                        : AppColors.deepForest,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '1',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              // Tombol Tambah (+)
                              InkWell(
                                onTap: () {
                                  final current =
                                      double.tryParse(
                                        _quantityController.text,
                                      ) ??
                                      0;
                                  final nextVal = current + 1;
                                  _quantityController.text = nextVal % 1 == 0
                                      ? nextVal.toInt().toString()
                                      : nextVal.toString();
                                  setState(() {});
                                },
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(16),
                                ),
                                child: const SizedBox(
                                  width: 40,
                                  height: 48,
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Dropdown Satuan
                      Container(
                        width: 105,
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
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
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
                  if (isQtyInvalid) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Jumlah harus lebih dari 0',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Tanggal kadaluwarsa
                  _buildLabel('Tanggal Kadaluwarsa (Estimasi Basi)'),
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
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? AppDateFormatter.formatShortDate(
                                      _selectedDate!,
                                    )
                                  : 'Pilih tanggal...',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: _selectedDate != null
                                    ? AppColors.deepForest
                                    : AppColors.textGray,
                                fontWeight: _selectedDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.textGray,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lokasi penyimpanan
                  _buildLabel('Lokasi Penyimpanan'),
                  const SizedBox(height: 8),
                  Row(
                    children: _storages.map((st) {
                      final isSel = _selectedStorage == st;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedStorage = st),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: st != _storages.last ? 8 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.mintTint
                                  : AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel
                                    ? AppColors.primary
                                    : AppColors.surfaceDim,
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                st,
                                style: AppTextStyles.badgeText.copyWith(
                                  color: isSel
                                      ? AppColors.primary
                                      : AppColors.textGray,
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Action Button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.surfaceDim)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFormValid
                      ? AppColors.primary
                      : AppColors.surfaceDim,
                  foregroundColor:
                      isFormValid ? Colors.white : AppColors.textGray,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: isFormValid ? 2 : 0,
                ),
                onPressed: (isFormValid && !_saving) ? _save : null,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.itemToEdit != null
                            ? 'Simpan Perubahan'
                            : 'Simpan ke Pantry',
                        style: AppTextStyles.button.copyWith(
                          fontSize: 15,
                          color:
                              isFormValid ? Colors.white : AppColors.textGray,
                          fontWeight: FontWeight.w700,
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
        style: AppTextStyles.sectionHeader.copyWith(
          color: AppColors.deepForest,
          fontSize: 12,
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
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.deepForest),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: AppTextStyles.bodyMd.copyWith(
            color: AppColors.textGray,
            fontSize: 13,
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
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
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
          final ing = _suggestions[index];
          return ListTile(
            dense: true,
            leading: AppFoodImage(
              imagePath: ing.imageUrl,
              width: 38,
              height: 38,
              borderRadius: 8,
              fallbackIcon: Icons.inventory_2_outlined,
            ),
            title: Text(
              ing.name,
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.deepForest,
              ),
            ),
            subtitle: Text(
              '${ing.category} · Lokasi: ${ing.defaultStorage} · Awet: ~${ing.defaultShelfLifeDays} hari',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: AppColors.textGray,
              ),
            ),
            onTap: () => _selectIngredient(ing),
          );
        },
      ),
    );
  }
}
