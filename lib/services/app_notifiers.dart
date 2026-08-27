import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/db_helper.dart';

/// Notifier global untuk menghitung jumlah notifikasi belum dibaca secara real-time
class NotificationNotifier extends ValueNotifier<int> {
  static final NotificationNotifier instance = NotificationNotifier._();
  NotificationNotifier._() : super(0);

  Future<void> refresh() async {
    final count = await DBHelper().getUnreadNotificationCount();
    value = count;
  }
}

/// Notifier global untuk memantau perubahan Eco Points pengguna
class EcoPointsNotifier extends ValueNotifier<int> {
  static final EcoPointsNotifier instance = EcoPointsNotifier._();
  EcoPointsNotifier._() : super(0);

  static const String _baseKey = 'user_eco_points';

  Future<String> _getKey() async {
    final userId = await DBHelper().getActiveUserId();
    return userId != null ? '${_baseKey}_$userId' : _baseKey;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getKey();
    value = prefs.getInt(key) ?? 0;
  }

  Future<void> addPoints(int points) async {
    if (points <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getKey();
    final current = prefs.getInt(key) ?? 0;
    final updated = current + points;
    await prefs.setInt(key, updated);
    value = updated;
  }

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getKey();
    value = prefs.getInt(key) ?? 0;
  }
}

/// Notifier global untuk sinkronisasi instan state inventaris dapur dan data antar-layar
class PantryUpdateNotifier extends ValueNotifier<int> {
  static final PantryUpdateNotifier instance = PantryUpdateNotifier._();
  PantryUpdateNotifier._() : super(0);

  void notifyPantryChanged() {
    value++;
  }
}
