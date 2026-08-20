import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/pantry_item_model.dart';

/// Controller untuk mengelola inventaris dapur (Pantry), status kedaluwarsa,
/// pencarian stok, serta filter urgensi.
class PantryController extends ChangeNotifier {
  final DBHelper _db;

  PantryController({DBHelper? db}) : _db = db ?? DBHelper();

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
          list = list.where((i) => i.expiryStatus == 'urgent' || i.expiryStatus == 'expired' || i.daysUntilExpiry <= 2).toList();
        } else if (_selectedFilter == 'segera') {
          list = list.where((i) => i.expiryStatus == 'segera' || (i.daysUntilExpiry > 2 && i.daysUntilExpiry <= 5)).toList();
        } else if (_selectedFilter == 'aman') {
          list = list.where((i) => i.expiryStatus == 'aman' || i.daysUntilExpiry > 5).toList();
        }
        _items = list;
      } else {
        _items = await _db.getPantryItems(filter: _selectedFilter);
      }

      // 2. Ambil data ringkasan status & notifikasi
      _statusCounts = await _db.getPantryStatusCounts();
      _unreadNotifications = await _db.getUnreadNotificationCount();
    } catch (e) {
      debugPrint('Error loading pantry data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mengatur filter status kedaluwarsa ('urgent', 'segera', 'aman', atau null untuk semua).
  void setFilter(String? filter) {
    _selectedFilter = filter;
    loadPantryData();
  }

  /// Mengatur kata kunci pencarian bahan dan memuat ulang data yang cocok.
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

  /// Menandai bahan makanan sudah digunakan
  Future<void> markItemUsed(int id) async {
    await _db.markPantryItemUsed(id);
    await loadPantryData();
  }

  /// Menghapus bahan makanan
  Future<void> deleteItem(int id) async {
    await _db.deletePantryItem(id);
    await loadPantryData();
  }
}
