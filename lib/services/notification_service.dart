import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Layanan notifikasi sistem native (Android & iOS) untuk memunculkan
/// banner notifikasi pop-up heads-up (seperti WhatsApp) saat batas nutrisi
/// berlebih atau stok makanan mendekati kedaluwarsa.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String channelId = 'foodcura_nutrition_alerts';
  static const String channelName = 'Peringatan Nutrisi & Stok FoodCura';
  static const String channelDescription =
      'Notifikasi penting peringatan nutrisi berlebih dan stok kedaluwarsa';

  /// Inisialisasi plugin notifikasi lokal sistem
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
      _initialized = true;
      await requestPermissions();
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  /// Meminta izin notifikasi (wajib di Android 13+ / Tiramisu dan iOS)
  Future<void> requestPermissions() async {
    try {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      final iosImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  /// Menampilkan notifikasi banner pop-up heads-up (di atas layar sistem)
  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await init();
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
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

  /// Membatalkan notifikasi berdasarkan ID tertentu
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }
}
