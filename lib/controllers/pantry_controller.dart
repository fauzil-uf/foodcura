import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/db_helper.dart';
import '../models/pantry_item_model.dart';
import '../services/gemini_service.dart';

/// Controller untuk mengelola inventaris dapur (Pantry), status kedaluwarsa,
/// pencarian stok, serta filter urgensi.
class PantryController extends ChangeNotifier {
  final DBHelper _db;
  final GeminiService _gemini;

  PantryController({DBHelper? db, GeminiService? gemini})
    : _db = db ?? DBHelper(),
      _gemini = gemini ?? GeminiService.instance;

  List<PantryItemModel> _items = [];
  String? _selectedFilter;
  String _searchQuery = '';
  Map<String, int> _statusCounts = {
    'urgent': 0,
    'segera': 0,
    'aman': 0,
    'total': 0,
  };
  int _unreadNotifications = 0;
  int _rescuedCount = 0;
  bool _isLoading = true;

  // Getters
  List<PantryItemModel> get items => _items;
  String? get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  Map<String, int> get statusCounts => _statusCounts;
  int get unreadNotifications => _unreadNotifications;
  int get rescuedCount => _rescuedCount;
  double get totalKgCO2Prevented => double.parse((_rescuedCount * 1.2).toStringAsFixed(1));
  int get totalMoneySaved => _rescuedCount * 15000;
  bool get isLoading => _isLoading;

  /// Mengelompokkan item berdasarkan lokasi penyimpanan
  Map<String, List<PantryItemModel>> get groupedItems {
    final Map<String, List<PantryItemModel>> grouped = {
      'Kulkas': [],
      'Freezer': [],
      'Lemari Kering': [],
    };
    for (final item in _items) {
      (grouped[item.storage] ??= []).add(item);
    }
    return grouped;
  }

  /// Memuat data inventaris dan menghitung ringkasan status
  Future<void> loadPantryData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Ambil data bahan (sesuai pencarian atau filter)
      if (_searchQuery.isNotEmpty) {
        var list = await _db.searchPantryItems(_searchQuery);
        if (_selectedFilter == 'urgent') {
          list = list.where((i) => i.expiryStatus == 'urgent' || i.expiryStatus == 'expired').toList();
        } else if (_selectedFilter != null) {
          list = list.where((i) => i.expiryStatus == _selectedFilter).toList();
        }
        _items = list;
      } else {
        _items = await _db.getPantryItems(filter: _selectedFilter);
      }

      // 2. Ambil data ringkasan status & notifikasi
      _statusCounts = await _db.getPantryStatusCounts();
      _unreadNotifications = await _db.getUnreadNotificationCount();
      _rescuedCount = await _db.getUsedPantryItemsCount();
    } catch (e) {
      debugPrint('Error loading pantry data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String? filter) {
    _selectedFilter = filter;
    loadPantryData();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadPantryData();
  }

  /// Menambah bahan makanan baru ke inventaris
  Future<int> addPantryItem(PantryItemModel item) async {
    final id = await _db.addPantryItem(item);
    await loadPantryData();
    return id;
  }

  /// Memperbarui bahan makanan
  Future<void> updatePantryItem(PantryItemModel item) async {
    await _db.updatePantryItem(item);
    await loadPantryData();
  }

  /// Menandai bahan makanan sudah digunakan (terselamatkan)
  Future<void> markItemUsed(int id) async {
    await _db.markPantryItemUsed(id);
    await loadPantryData();
  }

  /// Menghitung dampak lingkungan & apresiasi AI saat menyelamatkan bahan
  Future<EcoImpactResult> getEcoRescueImpact(
    PantryItemModel item, {
    int? rescuedCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPoints = prefs.getInt(EcoPointsNotifier.keyEcoPoints) ?? 0;
    int totalUsed = rescuedCount ?? 0;
    if (rescuedCount == null) {
      try {
        totalUsed = await _db.getUsedPantryItemsCount();
      } catch (_) {
        totalUsed = 1;
      }
    }

    return await _gemini.generateEcoImpactInsight(
      rescuedCount: totalUsed > 0 ? totalUsed : 1,
      ecoPoints: currentPoints,
      lastRescuedItem: item.name,
      quantity: item.quantity,
      unit: item.unit,
      category: item.storage,
    );
  }

  /// Menghitung estimasi preview dampak penghematan untuk 1 item (Mode Offline Cepat)
  EcoImpactResult getEstimatedImpactForItem(PantryItemModel item) {
    return GeminiService.calculateCategoryEcoImpact(
      itemName: item.name,
      category: item.storage,
      quantity: item.quantity,
      unit: item.unit,
    );
  }

  /// Menghapus bahan makanan
  Future<void> deleteItem(int id) async {
    await _db.deletePantryItem(id);
    await loadPantryData();
  }
}
