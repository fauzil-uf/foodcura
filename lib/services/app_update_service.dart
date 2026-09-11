import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_typography.dart';
import '../database/db_helper.dart';
import '../models/notification_model.dart';
import '../services/app_notifiers.dart';

/// Layanan pembaruan versi FoodCura.
///
/// - Saat buka app: cek versi lokal (offline, tanpa internet) dan tampilkan
///   notifikasi lonceng + bottom sheet jika ada perubahan versi.
/// - Saat user klik "Periksa Pembaruan" manual: cek langsung ke Google Play
////   Store via In-App Update API (butuh internet + app terinstal dari Play Store).
class AppUpdateService {
  static const String _keyLastSeenVersion = 'last_seen_app_version';

  // ---------------------------------------------------------------------------
  // OTOMATIS SAAT BUKA APP (offline / local tracker)
  // ---------------------------------------------------------------------------

  /// Dipanggil dari [main.dart] setelah login.
  /// Menampilkan notifikasi lonceng + bottom sheet ringkas jika versi berubah.
  static Future<void> checkAndShowWhatsNew(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeenVersion = prefs.getString(_keyLastSeenVersion);

      if (lastSeenVersion != AppConstants.appVersion) {
        // 1. Simpan ke pusat notifikasi (lonceng)
        await _insertSystemUpdateNotification();

        // 2. Simpan versi baru agar tidak muncul lagi
        await prefs.setString(_keyLastSeenVersion, AppConstants.appVersion);

        // 3. Tampilkan bottom sheet singkat
        if (context.mounted) {
          await _showLocalUpdateSheet(context);
        }
      }
    } catch (_) {}
  }

  /// Masukkan notifikasi singkat ke SQLite agar muncul di lonceng notifikasi.
  static Future<void> _insertSystemUpdateNotification() async {
    try {
      final db = DBHelper();
      final activeUserId = await db.getActiveUserId();
      if (activeUserId == null) return;

      final existingNotifs = await db.getNotifications(userId: activeUserId);
      final alreadyNotified = existingNotifs.any(
        (n) => n.title.contains(AppConstants.appVersionDisplay),
      );

      if (!alreadyNotified) {
        await db.addNotification(
          NotificationModel(
            userId: activeUserId,
            title:
                'Pembaruan ${AppConstants.appName} ${AppConstants.appVersionDisplay}',
            message: 'Pembaruan sistem & perbaikan minor aplikasi.',
            type: 'system',
            iconType: 'system_update',
            createdAt: DateTime.now(),
          ),
        );
        await NotificationNotifier.instance.refresh();
      }
    } catch (_) {}
  }

  /// Bottom sheet sederhana — notifikasi versi baru aktif (offline).
  static Future<void> _showLocalUpdateSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _UpdateNoticeSheet(mode: _UpdateMode.installed),
    );
  }

  // ---------------------------------------------------------------------------
  // MANUAL "PERIKSA PEMBARUAN" — cek ke Google Play Store (butuh internet)
  // ---------------------------------------------------------------------------

  /// Dipanggil dari tombol "Periksa Pembaruan" di halaman Profil.
  ///
  /// Alur:
  /// 1. Tampilkan loading indicator.
  /// 2. Cek ke Google Play Store via In-App Update API.
  ///    - Jika ada update: tawarkan Flexible Update (download di background).
  ///    - Jika sudah terbaru: tampilkan bottom sheet "Aplikasi Terupdate".
  ///    - Jika error (offline / bukan dari Play Store): tampilkan pesan error.
  static Future<void> checkForPlayStoreUpdate(BuildContext context) async {
    // Tampilkan loading di tombol
    if (!context.mounted) return;
    _showLoadingSnackBar(context);

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      switch (updateInfo.updateAvailability) {
        case UpdateAvailability.updateAvailable:
          // Ada versi baru di Play Store → tampilkan sheet tawaran update
          await showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => _UpdateNoticeSheet(
              mode: _UpdateMode.available,
              availableVersionCode: updateInfo.availableVersionCode,
            ),
          );

        case UpdateAvailability.updateNotAvailable:
        case UpdateAvailability.unknown:
        default:
          // Sudah versi terbaru
          await showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => const _UpdateNoticeSheet(mode: _UpdateMode.latest),
          );
      }
    } catch (_) {
      // Error: offline / app tidak terinstal dari Play Store (saat development)
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const _UpdateNoticeSheet(mode: _UpdateMode.error),
      );
    }
  }

  static void _showLoadingSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Memeriksa pembaruan dari Play Store…',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  /// Lama: dipakai oleh AboutFoodCuraDialog sebelum refactor.
  /// Tetap disimpan agar tidak ada breaking change pada widget lain.
  @Deprecated('Gunakan checkForPlayStoreUpdate untuk cek live ke Play Store.')
  static Future<void> showUpdateNoticeModal(
    BuildContext context, {
    bool isManualCheck = false,
  }) async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _UpdateNoticeSheet(mode: _UpdateMode.latest),
    );
  }
}

// ---------------------------------------------------------------------------
// Enum mode tampilan bottom sheet
/// ---------------------------------------------------------------------------
enum _UpdateMode {
  installed, // Baru saja diperbarui (notif otomatis saat buka app)
  latest, // Sudah versi terbaru (hasil cek manual)
  available, // Ada versi baru di Play Store
  error, // Gagal cek (offline / bukan dari Play Store)
}

// ---------------------------------------------------------------------------
// Bottom Sheet universal
/// ---------------------------------------------------------------------------
class _UpdateNoticeSheet extends StatelessWidget {
  final _UpdateMode mode;
  final int? availableVersionCode;

  const _UpdateNoticeSheet({required this.mode, this.availableVersionCode});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Status Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _iconBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _iconColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(_icon, color: _iconColor, size: 28),
            ),
            const SizedBox(height: 16),

            // Title + Version Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _title,
                    style: AppTextStyles.headlineSm.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.deepForest,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppConstants.appVersionDisplay,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitleSmall.copyWith(
                fontSize: 13,
                color: AppColors.textGray,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),

            // Info box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _infoBoxBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  Icon(_infoIcon, size: 16, color: _iconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _infoText,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.deepForest,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ctaColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _onCtaPressed(context),
                child: Text(
                  _ctaLabel,
                  style: AppTextStyles.buttonSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- helpers berdasarkan mode ----------

  String get _title => switch (mode) {
    _UpdateMode.installed => 'Pembaruan Aktif',
    _UpdateMode.latest => 'Aplikasi Terupdate',
    _UpdateMode.available => 'Update Tersedia',
    _UpdateMode.error => 'Tidak Dapat Memeriksa',
  };

  String get _subtitle => switch (mode) {
    _UpdateMode.installed =>
      'FoodCura berhasil diperbarui ke ${AppConstants.appVersionDisplay} dengan perbaikan minor & pembaruan sistem.',
    _UpdateMode.latest =>
      'FoodCura sudah berada di versi terbaru. Semua fitur dan data nutrisi berjalan optimal.',
    _UpdateMode.available =>
      'Versi baru tersedia di Google Play Store. Perbarui sekarang untuk mendapatkan fitur & perbaikan terbaru.',
    _UpdateMode.error =>
      'Gagal menghubungi Google Play Store. Pastikan perangkat terhubung ke internet dan aplikasi terinstal dari Play Store.',
  };

  String get _infoText => switch (mode) {
    _UpdateMode.installed =>
      'Pembaruan sistem & perbaikan minor (${AppConstants.appVersionDisplay})',
    _UpdateMode.latest =>
      'Versi ${AppConstants.appVersionDisplay} — Tidak ada pembaruan yang tersedia',
    _UpdateMode.available =>
      'Update baru di Play Store — ketuk "Perbarui" untuk memulai',
    _UpdateMode.error => 'Coba lagi saat perangkat terhubung ke internet',
  };

  String get _ctaLabel => switch (mode) {
    _UpdateMode.available => 'Perbarui Sekarang',
    _UpdateMode.error => 'Tutup',
    _ => mode == _UpdateMode.installed ? 'Mengerti' : 'Tutup',
  };

  IconData get _icon => switch (mode) {
    _UpdateMode.installed => Icons.system_update_rounded,
    _UpdateMode.latest => Icons.check_circle_rounded,
    _UpdateMode.available => Icons.new_releases_rounded,
    _UpdateMode.error => Icons.cloud_off_rounded,
  };

  IconData get _infoIcon => switch (mode) {
    _UpdateMode.available => Icons.download_rounded,
    _UpdateMode.error => Icons.wifi_off_rounded,
    _ => Icons.build_circle_outlined,
  };

  Color get _iconColor => switch (mode) {
    _UpdateMode.error => const Color(0xFFE65100),
    _UpdateMode.available => const Color(0xFF1565C0),
    _ => AppColors.primary,
  };

  Color get _iconBg => switch (mode) {
    _UpdateMode.error => const Color(0xFFFFF3E0),
    _UpdateMode.available => const Color(0xFFE3F2FD),
    _ => const Color(0xFFE8F5E9),
  };

  Color get _badgeColor => switch (mode) {
    _UpdateMode.error => const Color(0xFFE65100),
    _UpdateMode.available => const Color(0xFF1565C0),
    _ => AppColors.primary,
  };

  Color get _ctaColor => switch (mode) {
    _UpdateMode.available => const Color(0xFF1565C0),
    _ => AppColors.primary,
  };

  Color get _infoBoxBg => switch (mode) {
    _UpdateMode.error => const Color(0xFFFFF8F3),
    _UpdateMode.available => const Color(0xFFF0F7FF),
    _ => const Color(0xFFF7FAF7),
  };

  Future<void> _onCtaPressed(BuildContext context) async {
    if (mode == _UpdateMode.available) {
      Navigator.pop(context);
      try {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      } catch (_) {}
    } else {
      Navigator.pop(context);
    }
  }
}
