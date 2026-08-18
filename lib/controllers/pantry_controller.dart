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
  bool _isLoading = true;

  // Getters
  List<PantryItemModel> get items => _items;
  String? get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  Map<String, int> get statusCounts => _statusCounts;
  int get unreadNotifications => _unreadNotifications;
  bool get isLoading => _isLoading;

  /// Mengelompokkan item berdasarkan lokasi penyimpanan (Kulkas, Freezer, Lemari Kering)
  Map<String, List<PantryItemModel>> get groupedItems {
    final Map<String, List<PantryItemModel>> grouped = {
      'Kulkas': [],
      'Freezer': [],
      'Lemari Kering': [],
    };

    for (final item in _items) {
      if (grouped.containsKey(item.storage)) {
        grouped[item.storage]!.add(item);
      } else {
        grouped.putIfAbsent(item.storage, () => []).add(item);
      }
    }
    return grouped;
  }

  /// Memuat data inventaris dan menghitung ringkasan status
  Future<void> loadPantryData() async {
    _isLoading = true;
    notifyListeners();

    try {
      List<PantryItemModel> list;
      if (_searchQuery.isNotEmpty) {
        list = await _db.searchPantryItems(_searchQuery);
        if (_selectedFilter != null) {
          list = list.where((i) {
            if (_selectedFilter == 'urgent') {
              return i.expiryStatus == 'urgent' || i.expiryStatus == 'expired';
            }
            return i.expiryStatus == _selectedFilter;
          }).toList();
        }
      } else {
        list = await _db.getPantryItems(filter: _selectedFilter);
      }

      final counts = await _db.getPantryStatusCounts();
      final unread = await _db.getUnreadNotificationCount();

      // Cek otomatis dan buat notifikasi kadaluwarsa
      await _db.checkExpiryAndCreateNotifications();

      _items = list;
      _statusCounts = counts;
      _unreadNotifications = unread;
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
  Future<String> getEcoRescueImpact(
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
    );
  }

  /// Menghapus bahan makanan
  Future<void> deleteItem(int id) async {
    await _db.deletePantryItem(id);
    await loadPantryData();
  }
}
