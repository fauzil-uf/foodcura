import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../constants/app_date_formatter.dart';
import '../database/db_helper.dart';

/// Service untuk kalkulasi streak (hari aktif berturut-turut) berbasis
/// riwayat log makanan dan tanggal pendaftaran pengguna.
class StreakService {
  final DBHelper _db;

  StreakService({DBHelper? db}) : _db = db ?? DBHelper();

  /// Menghitung streak hari berturut-turut secara deterministik dan menyimpannya di SharedPreferences.
  Future<int> computeAndSaveStreak({int? userId}) async {
    final targetUserId = userId ?? await _db.getActiveUserId();
    if (targetUserId == null) return 0;

    final prefs = await SharedPreferences.getInstance();
    final streakKey = 'user_streak_$targetUserId';

    // 1. Ambil tanggal bergabung pengguna untuk batas maksimal streak logis
    final db = await _db.database;
    final userRes = await db.query(
      AppConstants.tableUsers,
      columns: ['created_at'],
      where: 'id = ?',
      whereArgs: [targetUserId],
      limit: 1,
    );

    DateTime? joinDate;
    if (userRes.isNotEmpty) {
      final rawCreatedAt = userRes.first['created_at'] as String?;
      if (rawCreatedAt != null && rawCreatedAt.isNotEmpty) {
        joinDate = DateTime.tryParse(rawCreatedAt) ?? AppDateFormatter.parseDate(rawCreatedAt);
      }
    }

    // 2. Ambil seluruh tanggal unik pencatatan makanan
    final result = await db.rawQuery(
      'SELECT DISTINCT date FROM ${DBHelper.tableFoodLogs} WHERE user_id = ?',
      [targetUserId],
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final dateSet = <DateTime>{};
    for (final r in result) {
      final parsed = AppDateFormatter.parseDate(r['date'] as String?);
      if (parsed != null) {
        dateSet.add(DateTime(parsed.year, parsed.month, parsed.day));
      }
    }

    // 3. Hitung hari berturut-turut ke belakang
    int currentStreak = 0;
    if (dateSet.contains(today)) {
      // Aktif hari ini
      DateTime checkDate = today;
      while (dateSet.contains(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else if (dateSet.contains(yesterday)) {
      // Aktif kemarin tapi belum log hari ini (streak tetap aktif)
      DateTime checkDate = yesterday;
      while (dateSet.contains(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else {
      // Akun baru bergabung hari ini atau kemarin
      if (dateSet.isEmpty && joinDate != null) {
        final joinDay = DateTime(joinDate.year, joinDate.month, joinDate.day);
        if (joinDay == today || joinDay == yesterday) {
          currentStreak = 1;
        } else {
          currentStreak = 0;
        }
      } else {
        currentStreak = 0;
      }
    }

    // 4. Batasi agar tidak pernah melebihi jumlah hari sejak bergabung
    if (joinDate != null) {
      final joinDay = DateTime(joinDate.year, joinDate.month, joinDate.day);
      final daysSinceJoin = today.difference(joinDay).inDays + 1;
      if (daysSinceJoin > 0 && currentStreak > daysSinceJoin) {
        currentStreak = daysSinceJoin;
      }
    }

    if (currentStreak < 0) currentStreak = 0;

    await prefs.setInt(streakKey, currentStreak);
    return currentStreak;
  }

  /// Mengambil nilai streak tersimpan secara cepat dari SharedPreferences.
  Future<int> getSavedStreak({int? userId}) async {
    final targetUserId = userId ?? await _db.getActiveUserId();
    if (targetUserId == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_streak_$targetUserId') ?? 0;
  }
}
