import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/notification_model.dart';

/// Controller untuk mengelola data notifikasi, filter kategori,
/// pengelompokan waktu, dan status baca/unread.
class NotificationController extends ChangeNotifier {
  final DBHelper _db;

  NotificationController({DBHelper? db}) : _db = db ?? DBHelper();

  List<NotificationModel> _notifications = [];
  int _selectedFilterIndex = 0;
  int _unreadCount = 0;
  bool _isLoading = true;

  final List<String> _filterNames = [
    'Semua',
    'Belum Dibaca',
    'Kadaluwarsa',
    'Info & Tips',
  ];

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get selectedFilterIndex => _selectedFilterIndex;
  List<String> get filterNames => _filterNames;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  /// Mengelompokkan notifikasi ke dalam section 'Hari Ini' dan 'Sebelumnya'
  Map<String, List<NotificationModel>> get groupedNotifications {
    final Map<String, List<NotificationModel>> grouped = {
      'Hari Ini': [],
      'Sebelumnya': [],
    };

    for (final notif in _notifications) {
      if (notif.isToday) {
        grouped['Hari Ini']!.add(notif);
      } else {
        grouped['Sebelumnya']!.add(notif);
      }
    }
    return grouped;
  }

  /// Memuat notifikasi berdasarkan filter yang dipilih
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      String? filterArg;
      if (_selectedFilterIndex == 1) {
        filterArg = 'unread';
      } else if (_selectedFilterIndex == 2) {
        filterArg = 'expiry';
      } else if (_selectedFilterIndex == 3) {
        filterArg = 'foodcura';
      }

      final notifs = await _db.getNotifications(filter: filterArg);
      final unread = await _db.getUnreadNotificationCount();

      _notifications = notifs;
      _unreadCount = unread;
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(int index) {
    _selectedFilterIndex = index;
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
}
