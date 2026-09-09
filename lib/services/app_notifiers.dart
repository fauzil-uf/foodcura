import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/db_helper.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

// Notifier jumlah notifikasi belum dibaca
class NotificationNotifier extends ValueNotifier<int> {
  static final NotificationNotifier instance = NotificationNotifier._();
  NotificationNotifier._() : super(0);

  Future<void> refresh() async {
    final count = await DBHelper().getUnreadNotificationCount();
    value = count;
  }
}

// Notifier Eco Points pengguna
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

    // Sinkronisasi otomatis ke Firestore
    try {
      final uid = AuthService.instance.currentUser?.uid;
      if (uid != null) {
        FirestoreService.instance.updateEcoPoints(uid: uid, ecoPoints: updated).ignore();
      }
    } catch (_) {}
  }

  Future<void> setPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getKey();
    await prefs.setInt(key, points);
    value = points;
  }

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getKey();
    value = prefs.getInt(key) ?? 0;
  }
}

// Notifier event perubahan data pantry
class PantryUpdateNotifier extends ValueNotifier<int> {
  static final PantryUpdateNotifier instance = PantryUpdateNotifier._();
  PantryUpdateNotifier._() : super(0);

  void notifyPantryChanged() {
    value++;
  }
}

// Notifier event perubahan catatan makan (Food Logs)
class FoodLogUpdateNotifier extends ValueNotifier<int> {
  static final FoodLogUpdateNotifier instance = FoodLogUpdateNotifier._();
  FoodLogUpdateNotifier._() : super(0);

  void notifyFoodLogsChanged() {
    value++;
  }
}

// Notifier event perubahan data profil pengguna
class UserProfileUpdateNotifier extends ValueNotifier<int> {
  static final UserProfileUpdateNotifier instance = UserProfileUpdateNotifier._();
  UserProfileUpdateNotifier._() : super(0);

  void notifyUserChanged() {
    value++;
  }
}
