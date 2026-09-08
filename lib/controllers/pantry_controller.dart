import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/pantry_item_model.dart';
import '../services/app_notifiers.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
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
      'Suhu Ruang': [],
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

      // 1. Ambil data semua bahan dari SQLite (cukup 1 kali query)
      final allItems = await _db.getPantryItems();

      // Hitung ringkasan status langsung di memori (0.05ms) tanpa query ulang ke SQLite
      int safe = 0, warning = 0, danger = 0, expired = 0;
      for (final item in allItems) {
        final days = item.daysUntilExpiry;
        if (days < 0) {
          expired++;
        } else if (days <= 2) {
          danger++;
        } else if (days <= 5) {
          warning++;
        } else {
          safe++;
        }
      }
      _statusCounts = {
        'safe': safe,
        'warning': warning,
        'danger': danger,
        'expired': expired,
        'urgent': danger + expired,
        'segera': warning,
        'aman': safe,
        'total': allItems.length,
      };

      // 2. Terapkan filter / pencarian secara in-memory untuk responsivitas instan
      var list = _searchQuery.isNotEmpty
          ? allItems
              .where(
                (i) => i.name.toLowerCase().contains(
                  _searchQuery.toLowerCase().trim(),
                ),
              )
              .toList()
          : allItems;

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
        } else if (f == 'suhu ruang' || f == 'lemari kering') {
          list = list
              .where(
                (i) =>
                    i.storage.toLowerCase() == 'suhu ruang' ||
                    i.storage.toLowerCase() == 'lemari kering',
              )
              .toList();
        } else {
          list = list.where((i) => i.storage.toLowerCase() == f).toList();
        }
      }
      _items = list;
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
    // Sinkronisasi ke Firestore (latar belakang)
    try {
      final activeUserId = item.userId ?? await _db.getActiveUserId();
      final uid = AuthService.instance.currentUser?.uid ?? 'user_$activeUserId';
      FirestoreService.instance
          .addPantryItem(uid, item.copyWith(id: id))
          .ignore();
    } catch (_) {}
    await _reminderService.syncPantryExpiryAlarms();
    await _reminderService.checkExpiryAndCreateNotifications(
      force: true,
      specificItemId: id,
    );
    await NotificationNotifier.instance.refresh();
    await loadPantryData();
    return id;
  }

  /// Memperbarui bahan makanan
  Future<void> updatePantryItem(PantryItemModel item) async {
    await _db.updatePantryItem(item);
    // Sinkronisasi ke Firestore (latar belakang)
    try {
      final activeUserId = item.userId ?? await _db.getActiveUserId();
      final uid = AuthService.instance.currentUser?.uid ?? 'user_$activeUserId';
      final firestoreId = item.firestoreId ?? 'pantry_${item.id}';
      FirestoreService.instance
          .updatePantryItem(uid, firestoreId, item)
          .ignore();
    } catch (_) {}
    if (item.id != null) {
      final userId = item.userId ?? await _db.getActiveUserId();
      if (userId != null) {
        await _reminderService.clearPantryNotificationTracking(userId, item.id!);
      }
      // Selalu bersihkan notifikasi lama bahan ini agar status baru dievaluasi segar tanpa duplikasi
      await _db.deleteNotificationsByPantryId(item.id!);
      await NotificationService.instance.cancelPantryNotifications(item.id!);
    }
    await _reminderService.syncPantryExpiryAlarms();
    await _reminderService.checkExpiryAndCreateNotifications(
      force: true,
      specificItemId: item.id,
    );
    await NotificationNotifier.instance.refresh();
    await loadPantryData();
  }

  /// Menandai bahan makanan sudah digunakan
  Future<void> markItemUsed(int id) async {
    await _db.markPantryItemUsed(id);
    // Sinkronisasi status terpakai ke Firestore
    try {
      final activeUserId = await _db.getActiveUserId();
      final uid = AuthService.instance.currentUser?.uid ?? 'user_$activeUserId';
      FirestoreService.instance
          .updatePantryItem(
            uid,
            'pantry_$id',
            PantryItemModel(
              id: id,
              name: '',
              quantity: 0,
              unit: '',
              storage: '',
              expiryDate: DateTime.now(),
              createdAt: DateTime.now(),
              isUsed: true,
            ),
          )
          .ignore();
    } catch (_) {}
    await _db.deleteNotificationsByPantryId(id);
    await NotificationService.instance.cancelPantryNotifications(id);
    await _reminderService.syncPantryExpiryAlarms();
    await NotificationNotifier.instance.refresh();
    await loadPantryData();
  }

  /// Menghapus bahan makanan
  Future<void> deleteItem(int id) async {
    await _db.deletePantryItem(id);
    // Hapus dari Firestore
    try {
      final activeUserId = await _db.getActiveUserId();
      final uid = AuthService.instance.currentUser?.uid ?? 'user_$activeUserId';
      FirestoreService.instance.deletePantryItem(uid, 'pantry_$id').ignore();
    } catch (_) {}
    await _db.deleteNotificationsByPantryId(id);
    await NotificationService.instance.cancelPantryNotifications(id);
    await _reminderService.syncPantryExpiryAlarms();
    await NotificationNotifier.instance.refresh();
    await loadPantryData();
  }

  /// Memperbarui badge hitungan notifikasi belum terbaca secara efisien
  Future<void> refreshUnreadCount() async {
    _unreadNotifications = await _db.getUnreadNotificationCount();
    notifyListeners();
  }
}
