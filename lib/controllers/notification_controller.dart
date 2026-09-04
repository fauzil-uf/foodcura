import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/notification_model.dart';
import '../services/app_notifiers.dart';
import '../services/notification_service.dart';
import '../services/nutrition_service.dart';
import '../services/reminder_service.dart';

// Controller daftar notifikasi & filter status baca
class NotificationController extends ChangeNotifier {
  final DBHelper _db;
  final ReminderService _reminderService;

  NotificationController({DBHelper? db, ReminderService? reminderService})
    : _db = db ?? DBHelper(),
      _reminderService =
          reminderService ?? ReminderService(db: db ?? DBHelper());

  List<NotificationModel> _notifications = [];
  final Set<int> _selectedNotificationIds = {};
  int _selectedFilterIndex = 0;
  int _unreadCount = 0;
  bool _isLoading = true;

  static const List<String> _filterNames = [
    'Semua',
    'Belum Dibaca',
    'Kedaluwarsa',
    'Pengingat Makan',
    'Info & Tips',
  ];

  static const List<String?> _filterArgs = [
    null,
    'unread',
    'expiry',
    'meal_reminder',
    'foodcura',
  ];

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get selectedFilterIndex => _selectedFilterIndex;
  List<String> get filterNames => _filterNames;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isSelectionMode => _selectedNotificationIds.isNotEmpty;
  Set<int> get selectedNotificationIds => _selectedNotificationIds;
  int get selectedCount => _selectedNotificationIds.length;
  bool isNotificationSelected(int id) => _selectedNotificationIds.contains(id);

  /// Mengelompokkan notifikasi ke dalam section 'Hari Ini' dan 'Sebelumnya'
  Map<String, List<NotificationModel>> get groupedNotifications {
    final Map<String, List<NotificationModel>> grouped = {
      'Hari Ini': [],
      'Sebelumnya': [],
    };
    for (final notif in _notifications) {
      grouped[notif.isToday ? 'Hari Ini' : 'Sebelumnya']!.add(notif);
    }
    return grouped;
  }

  /// Memulai mode seleksi dengan memilih satu notifikasi (misal via long-press)
  void startSelection(int id) {
    _selectedNotificationIds.add(id);
    notifyListeners();
  }

  /// Toggle seleksi notifikasi tertentu
  void toggleSelection(int id) {
    if (_selectedNotificationIds.contains(id)) {
      _selectedNotificationIds.remove(id);
    } else {
      _selectedNotificationIds.add(id);
    }
    notifyListeners();
  }

  /// Memilih semua notifikasi yang sedang tampil (atau batalkan jika sudah semua dipilih)
  void selectAll() {
    final visibleIds = _notifications
        .where((n) => n.id != null)
        .map((n) => n.id!)
        .toSet();

    if (_selectedNotificationIds.length == visibleIds.length &&
        _selectedNotificationIds.containsAll(visibleIds)) {
      _selectedNotificationIds.clear();
    } else {
      _selectedNotificationIds.addAll(visibleIds);
    }
    notifyListeners();
  }

  /// Membatalkan dan keluar dari mode seleksi
  void clearSelection() {
    if (_selectedNotificationIds.isNotEmpty) {
      _selectedNotificationIds.clear();
      notifyListeners();
    }
  }

  /// Memuat notifikasi berdasarkan filter yang dipilih
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.cleanDuplicateNotifications();
      final filterArg =
          _filterArgs[_selectedFilterIndex.clamp(0, _filterArgs.length - 1)];
      _notifications = await _db.getNotifications(filter: filterArg);
      _unreadCount = await _db.getUnreadNotificationCount();
      // Bersihkan id seleksi yang tidak ada lagi di daftar
      final existingIds = _notifications.map((n) => n.id).toSet();
      _selectedNotificationIds.removeWhere((id) => !existingIds.contains(id));
      await NotificationNotifier.instance.refresh();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mengatur indeks filter (Semua, Belum Dibaca, Kedaluwarsa, Info) dan memuat ulang notifikasi.
  void setFilter(int index) {
    _selectedFilterIndex = index;
    _selectedNotificationIds.clear();
    loadNotifications();
  }

  /// Menandai satu notifikasi sudah dibaca
  Future<void> markRead(NotificationModel notif) async {
    if (notif.id == null || notif.isRead) return;
    await _db.markNotificationRead(notif.id!);
    await loadNotifications();
  }

  /// Menandai seluruh notifikasi sudah dibaca
  Future<void> markAllRead() async {
    await _db.markAllNotificationsRead();
    await loadNotifications();
  }

  /// Menghapus satu notifikasi (misal saat di-swipe)
  Future<void> deleteNotification(NotificationModel notif) async {
    if (notif.id == null) return;
    final userId = notif.userId ?? await _db.getActiveUserId();
    await _handleNotificationDismissal(notif, userId);
    await _db.deleteNotification(notif.id!);
    _selectedNotificationIds.remove(notif.id!);
    await loadNotifications();
  }

  /// Menghapus semua notifikasi milik user
  Future<void> clearAllNotifications() async {
    final userId = await _db.getActiveUserId();
    for (final notif in _notifications) {
      await _handleNotificationDismissal(notif, userId, rescheduleMeal: false);
    }
    await _db.clearAllNotifications();
    try {
      await NotificationService.instance.cancelAllNotifications();
      await _reminderService.syncMealAlarms();
      await _reminderService.syncPantryExpiryAlarms(userId: userId);
    } catch (_) {}
    _selectedNotificationIds.clear();
    await loadNotifications();
  }

  /// Menghapus seluruh notifikasi yang sedang dipilih dalam mode multi-seleksi
  Future<void> deleteSelectedNotifications() async {
    if (_selectedNotificationIds.isEmpty) return;

    final selectedList = _notifications
        .where((n) => n.id != null && _selectedNotificationIds.contains(n.id))
        .toList();

    final userId = await _db.getActiveUserId();
    for (final notif in selectedList) {
      await _handleNotificationDismissal(notif, userId);
    }

    final idsToDelete = selectedList.map((n) => n.id!).toList();
    await _db.deleteNotifications(idsToDelete);

    _selectedNotificationIds.clear();
    await loadNotifications();
  }

  /// Helper terpusat untuk menangani pembatalan alarm dan pencatatan dismissal
  /// saat notifikasi dihapus dari sistem.
  Future<void> _handleNotificationDismissal(
    NotificationModel notif,
    int? userId, {
    bool rescheduleMeal = true,
  }) async {
    if (userId == null) return;

    if (notif.relatedPantryId != null) {
      await _reminderService.recordDismissedPantryNotification(
        userId,
        notif.relatedPantryId!,
      );
      try {
        await NotificationService.instance.cancelPantryNotifications(
          notif.relatedPantryId!,
        );
      } catch (_) {}
    } else if (notif.type == 'meal_reminder') {
      final lowerTitle = notif.title.toLowerCase();
      final lowerMsg = notif.message.toLowerCase();
      for (final meal in ReminderService.mealConfigs) {
        final mealTypeLower = meal['type']!.toLowerCase();
        final mealTitleLower = meal['title']!.toLowerCase();
        if (lowerTitle.contains(mealTypeLower) ||
            lowerTitle.contains(mealTitleLower) ||
            lowerMsg.contains(mealTypeLower)) {
          await _reminderService.recordDismissedMealNotification(
            userId,
            meal['type']!,
          );
          final systemId = meal['type'] == 'Sarapan'
              ? 10001
              : meal['type'] == 'Makan Siang'
              ? 10002
              : 10003;
          try {
            await NotificationService.instance.cancelNotification(systemId);
          } catch (_) {}
          if (rescheduleMeal) {
            await _reminderService.rescheduleMealAlarmForTomorrow(meal['type']!);
          }
        }
      }
    } else if (notif.type == 'nutrition_excess') {
      final lowerTitle = notif.title.toLowerCase();
      final lowerMsg = notif.message.toLowerCase();
      for (final kw in [
        'lemak',
        'kalori',
        'kolesterol',
        'karbohidrat',
        'protein',
      ]) {
        if (lowerTitle.contains(kw) || lowerMsg.contains(kw)) {
          final capitalKw = kw[0].toUpperCase() + kw.substring(1);
          await NutritionService.recordDismissedNutritionNotification(
            userId,
            capitalKw,
          );
          try {
            await NotificationService.instance.cancelNotification(
              NutritionService.getSystemNotifId(capitalKw),
            );
          } catch (_) {}
        }
      }
      try {
        await NotificationService.instance.cancelNotification(40000);
      } catch (_) {}
    }
  }
}


