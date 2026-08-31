import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/pantry_item_model.dart';
import '../services/app_notifiers.dart';
import '../services/reminder_service.dart';

// Controller inventaris pantry & pemantau kedaluwarsa
class PantryController extends ChangeNotifier {
  final DBHelper _db;
  final ReminderService _reminderService;

  PantryController({DBHelper? db, ReminderService? reminderService})
    : _db = db ?? DBHelper(),
      _reminderService =
          reminderService ?? ReminderService(db: db ?? DBHelper());

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

  /// Mengelompokkan item berdasarkan status kedaluwarsa (urgent/expired, segera, aman)
  Map<String, List<PantryItemModel>> get groupedByExpiry {
    final urgent = <PantryItemModel>[];
    final segera = <PantryItemModel>[];
    final aman = <PantryItemModel>[];
    for (final item in _items) {
      switch (item.expiryStatus) {
        case 'expired':
        case 'urgent':
          urgent.add(item);
          break;
        case 'segera':
          segera.add(item);
          break;
        default:
          aman.add(item);
      }
    }
    return {'urgent': urgent, 'segera': segera, 'aman': aman};
  }

  /// Memuat data inventaris dan menghitung ringkasan status
  Future<void> loadPantryData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Periksa tanggal kedaluwarsa dan sinkronisasi notifikasi otomatis
      await _reminderService.checkExpiryAndCreateNotifications();

      // 1. Ambil data bahan (sesuai pencarian atau filter)
      if (_searchQuery.isNotEmpty) {
        var list = await _db.searchPantryItems(_searchQuery);
        if (_selectedFilter == 'urgent') {
          list = list
              .where(
                (i) =>
                    i.expiryStatus == 'urgent' ||
                    i.expiryStatus == 'expired' ||
                    i.daysUntilExpiry <= 2,
              )
              .toList();
        } else if (_selectedFilter == 'segera') {
          list = list
              .where(
                (i) =>
                    i.expiryStatus == 'segera' ||
                    (i.daysUntilExpiry > 2 && i.daysUntilExpiry <= 5),
              )
              .toList();
        } else if (_selectedFilter == 'aman') {
          list = list
              .where((i) => i.expiryStatus == 'aman' || i.daysUntilExpiry > 5)
              .toList();
        }
        _items = list;
      } else {
        var list = await _db.getPantryItems();
        if (_selectedFilter != null && _selectedFilter != 'Semua') {
          final f = _selectedFilter!.toLowerCase();
          if (f == 'urgent' || f == 'danger') {
            list = list
                .where(
                  (i) =>
                      i.expiryStatus == 'urgent' ||
                      i.expiryStatus == 'expired' ||
                      i.daysUntilExpiry <= 2,
                )
                .toList();
          } else if (f == 'segera' || f == 'warning') {
            list = list
                .where(
                  (i) =>
                      i.expiryStatus == 'segera' ||
                      (i.daysUntilExpiry > 2 && i.daysUntilExpiry <= 5),
                )
                .toList();
          } else if (f == 'aman' || f == 'safe') {
            list = list
                .where((i) => i.expiryStatus == 'aman' || i.daysUntilExpiry > 5)
                .toList();
          } else {
            list = list.where((i) => i.storage.toLowerCase() == f).toList();
          }
        }
        _items = list;
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
    await _reminderService.checkExpiryAndCreateNotifications();
    await NotificationNotifier.instance.refresh();
    await loadPantryData();
    return id;
  }

  /// Memperbarui bahan makanan
  Future<void> updatePantryItem(PantryItemModel item) async {
    await _db.updatePantryItem(item);
    await _reminderService.checkExpiryAndCreateNotifications();
    await NotificationNotifier.instance.refresh();
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

  /// Memperbarui badge hitungan notifikasi belum terbaca secara efisien
  Future<void> refreshUnreadCount() async {
    _unreadNotifications = await _db.getUnreadNotificationCount();
    notifyListeners();
  }
}
