import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Service notifikasi lokal sistem (flutter_local_notifications)
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const MethodChannel _settingsChannel =
      MethodChannel('com.fauzil.foodcura/settings');

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool? _exactAlarmsPermitted;

  static const String channelId = 'foodcura_nutrition_alerts';
  static const String channelName = 'Peringatan Nutrisi & Stok FoodCura';
  static const String channelDescription =
      'Notifikasi penting peringatan nutrisi berlebih dan stok kedaluwarsa';

  static const String mealChannelId = 'foodcura_meal_reminders';
  static const String mealChannelName = 'Pengingat Makan Harian';
  static const String mealChannelDescription =
      'Notifikasi jadwal makan sarapan, makan siang, dan makan malam';

  static const String urgentExpiryChannelId = 'foodcura_expiry_urgent';
  static const String urgentExpiryChannelName = 'Peringatan Bahan Kedaluwarsa';
  static const String urgentExpiryChannelDesc =
      'Peringatan penting untuk bahan yang sudah kedaluwarsa atau tersisa <=1 hari';

  static const String warningExpiryChannelId = 'foodcura_expiry_warning';
  static const String warningExpiryChannelName = 'Pengingat Mendekati Kedaluwarsa';
  static const String warningExpiryChannelDesc =
      'Pengingat untuk bahan yang akan kedaluwarsa dalam 2-5 hari ke depan';

  // Inisialisasi local notification & konfigurasi timezone
  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      _configureLocalTimeZone();
    } catch (e) {
      debugPrint('Error configuring timezone: $e');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // Registrasikan Notification Channels Android secara eksplisit dengan tingkat kepentingan tertinggi (Max)
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        const nutritionChannel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        const mealChannel = AndroidNotificationChannel(
          mealChannelId,
          mealChannelName,
          description: mealChannelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await androidImplementation.createNotificationChannel(nutritionChannel);
        await androidImplementation.createNotificationChannel(mealChannel);

        const urgentExpiryChannel = AndroidNotificationChannel(
          urgentExpiryChannelId,
          urgentExpiryChannelName,
          description: urgentExpiryChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        const warningExpiryChannel = AndroidNotificationChannel(
          warningExpiryChannelId,
          warningExpiryChannelName,
          description: warningExpiryChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        await androidImplementation.createNotificationChannel(urgentExpiryChannel);
        await androidImplementation.createNotificationChannel(warningExpiryChannel);
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  // Konfigurasi zona waktu lokal perangkat
  void _configureLocalTimeZone() {
    try {
      final offsetHours = DateTime.now().timeZoneOffset.inHours;
      String locationName = 'Asia/Jakarta';
      if (offsetHours == 8) {
        locationName = 'Asia/Makassar';
      } else if (offsetHours == 9) {
        locationName = 'Asia/Jayapura';
      } else {
        for (final loc in tz.timeZoneDatabase.locations.values) {
          if (loc.currentTimeZone.offset ==
              DateTime.now().timeZoneOffset.inMilliseconds) {
            locationName = loc.name;
            break;
          }
        }
      }
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (e) {
      debugPrint('Error setting local location: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {}
    }
  }

  // Minta izin notifikasi (Android 13+ / iOS)
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return false;
  }

  // Cek apakah izin notifikasi aktif di sistem
  Future<bool> areNotificationsEnabled() async {
    try {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        return await androidImplementation.areNotificationsEnabled() ?? false;
      }
    } catch (e) {
      debugPrint('Error checking notification status: $e');
    }
    return true;
  }

  // Buka pengaturan notifikasi aplikasi di level OS Android
  Future<void> openNotificationSettings() async {
    try {
      await _settingsChannel.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('Error opening notification settings: $e');
    }
  }

  // Buka pengaturan izin exact alarm (Android 12+)
  Future<void> openExactAlarmSettings() async {
    try {
      await _settingsChannel.invokeMethod('openExactAlarmSettings');
    } catch (e) {
      debugPrint('Error opening exact alarm settings: $e');
    }
  }

  // Cek apakah sistem mengizinkan exact alarm (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    try {
      final res =
          await _settingsChannel.invokeMethod<bool>('canScheduleExactAlarms');
      return res ?? true;
    } catch (e) {
      debugPrint('Error checking exact alarm status: $e');
      return true;
    }
  }

  // Cek apakah app dikecualikan dari battery optimization
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final res = await _settingsChannel
          .invokeMethod<bool>('isBatteryOptimizationIgnored');
      return res ?? true;
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
      return true;
    }
  }

  // Buka halaman daftar battery optimization di OS (user pilih FoodCura → Unrestricted)
  Future<void> openBatteryOptimizationSettings() async {
    try {
      await _settingsChannel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      debugPrint('Error opening battery optimization settings: $e');
    }
  }

  // Tampilkan notifikasi push sistem instan
  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? channelIdOverride,
    String? payload,
  }) async {
    if (!_initialized) {
      await init();
    }
    if (!_initialized) return;

    final targetChannelId = channelIdOverride ?? channelId;
    final targetChannelName = (targetChannelId == mealChannelId)
        ? mealChannelName
        : (targetChannelId == urgentExpiryChannelId)
            ? urgentExpiryChannelName
            : (targetChannelId == warningExpiryChannelId)
                ? warningExpiryChannelName
                : channelName;
    final targetChannelDesc = (targetChannelId == mealChannelId)
        ? mealChannelDescription
        : (targetChannelId == urgentExpiryChannelId)
            ? urgentExpiryChannelDesc
            : (targetChannelId == warningExpiryChannelId)
                ? warningExpiryChannelDesc
                : channelDescription;

    final androidDetails = AndroidNotificationDetails(
      targetChannelId,
      targetChannelName,
      channelDescription: targetChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      visibility: NotificationVisibility.public,
      category: (targetChannelId == mealChannelId)
          ? AndroidNotificationCategory.reminder
          : (targetChannelId == urgentExpiryChannelId || targetChannelId == warningExpiryChannelId)
              ? AndroidNotificationCategory.alarm
              : AndroidNotificationCategory.recommendation,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/launcher_icon',
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing system notification: $e');
    }
  }

  // Jadwalkan notifikasi berulang harian yang berjalan walau aplikasi ditutup
  Future<void> scheduleDailyMealNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    bool startFromTomorrow = false,
  }) async {
    if (!_initialized) {
      await init();
    }
    if (!_initialized) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Batalkan notifikasi lama dengan ID ini sebelum mendaftarkan jadwal baru
    try {
      await _localNotifications.cancel(id);
    } catch (_) {}

    // Jika jam hari ini sudah terlewati ATAU startFromTomorrow diminta, jadwalkan mulai besok pada jam yang sama
    if (startFromTomorrow || !scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      mealChannelId,
      mealChannelName,
      channelDescription: mealChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/launcher_icon',
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Jika sebelumnya sistem menolak exact alarm, langsung gunakan inexact agar efisien
    if (_exactAlarmsPermitted == false) {
      try {
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (innerErr) {
        debugPrint('Error scheduling daily meal notification: $innerErr');
      }
      return;
    }

    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      _exactAlarmsPermitted = true;
    } catch (e) {
      _exactAlarmsPermitted = false;
      try {
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (innerErr) {
        debugPrint('Error scheduling daily meal notification: $innerErr');
      }
    }
  }

  // Minta izin exact alarm secara eksplisit (jika diperlukan pada Android 13/14+)
  Future<bool?> requestExactAlarmsPermission() async {
    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        return await androidPlugin.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('Error requesting exact alarm permission: $e');
    }
    return null;
  }

  // Jadwalkan notifikasi di masa depan (AlarmManager sistem Android)
  Future<void> scheduleFutureNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? channelIdOverride,
    String? payload,
  }) async {
    if (!_initialized) {
      await init();
    }
    if (!_initialized) return;

    final targetTZ = tz.TZDateTime.from(scheduledDateTime, tz.local);
    final nowTZ = tz.TZDateTime.now(tz.local);
    if (!targetTZ.isAfter(nowTZ)) return;

    final targetChannelId = channelIdOverride ?? channelId;
    final targetChannelName = (targetChannelId == mealChannelId)
        ? mealChannelName
        : channelName;
    final targetChannelDesc = (targetChannelId == mealChannelId)
        ? mealChannelDescription
        : channelDescription;

    final androidDetails = AndroidNotificationDetails(
      targetChannelId,
      targetChannelName,
      channelDescription: targetChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/launcher_icon',
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.cancel(id);
    } catch (_) {}

    if (_exactAlarmsPermitted == false) {
      try {
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          targetTZ,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (innerErr) {
        debugPrint('Error scheduling future notification: $innerErr');
      }
      return;
    }

    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        targetTZ,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      _exactAlarmsPermitted = true;
      debugPrint(
        'Scheduled future expiry notification #$id at $scheduledDateTime',
      );
    } catch (e) {
      _exactAlarmsPermitted = false;
      try {
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          targetTZ,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (innerErr) {
        debugPrint('Error scheduling future notification: $innerErr');
      }
    }
  }


  // Jadwalkan notifikasi expire harian per-bahan dengan channel sesuai urgensi
  Future<void> scheduleDailyExpiryNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
  }) async {
    if (!_initialized) {
      await init();
    }
    if (!_initialized) return;

    final isUrgent = channelId == urgentExpiryChannelId;
    final targetChannelName = isUrgent ? urgentExpiryChannelName : warningExpiryChannelName;
    final targetChannelDesc = isUrgent ? urgentExpiryChannelDesc : warningExpiryChannelDesc;
    final importance = isUrgent ? Importance.max : Importance.high;
    final priority = isUrgent ? Priority.max : Priority.high;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      targetChannelName,
      channelDescription: targetChannelDesc,
      importance: importance,
      priority: priority,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/launcher_icon',
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.cancel(id);
    } catch (_) {}

    if (_exactAlarmsPermitted == false) {
      try {
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (innerErr) {
        debugPrint('Error scheduling expiry notification: $innerErr');
      }
      return;
    }

    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      _exactAlarmsPermitted = true;
    } catch (e) {
      _exactAlarmsPermitted = false;
      try {
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (innerErr) {
        debugPrint('Error scheduling expiry notification: $innerErr');
      }
    }
  }
  // Batalkan alarm/notifikasi untuk item pantry tertentu
  Future<void> cancelPantryNotifications(int pantryId) async {
    // ID scheme lama (200000+) â€” backward compatibility
    final idLegacy1 = 200000 + (pantryId * 10) + 1;
    final idLegacy2 = 200000 + (pantryId * 10) + 2;
    await cancelNotification(idLegacy1);
    await cancelNotification(idLegacy2);
    // ID scheme baru per-bahan bertingkat (30000+)
    final urgentId = 30000 + (pantryId * 10) + 1;
    final warningId = 30000 + (pantryId * 10) + 2;
    await cancelNotification(urgentId);
    await cancelNotification(warningId);
    await cancelNotification(20000 + pantryId);
  }

  // Batalkan notifikasi atau alarm tertentu
  Future<void> cancelNotification(int id) async {
    if (!_initialized) {
      await init();
    }
    if (!_initialized) return;

    try {
      await _localNotifications.cancel(id);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }
  // Batalkan semua notifikasi dan alarm yang sedang aktif
  Future<void> cancelAllNotifications() async {
    if (!_initialized) {
      await init();
    }
    if (!_initialized) return;

    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }
}