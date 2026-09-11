import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

//// Layanan terpusat untuk memantau status jaringan (Online/Offline) secara real-time.
class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Notifier status koneksi (true = online, false = offline)
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  /// Status apakah perangkat saat ini terhubung ke jaringan internet
  bool get isOnline => isOnlineNotifier.value;

  /// Inisialisasi pendengar perubahan status koneksi real-time
  Future<void> init() async {
    try {
      final initialResults = await _connectivity.checkConnectivity();
      _updateStatus(initialResults);
    } catch (e) {
      debugPrint('ConnectivityService init error (fallback to online): $e');
      isOnlineNotifier.value = true;
    }

    try {
      _subscription?.cancel();
      _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    } catch (e) {
      debugPrint('ConnectivityService stream error: $e');
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final bool connected = results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn ||
          r == ConnectivityResult.other,
    );

    if (isOnlineNotifier.value != connected) {
      isOnlineNotifier.value = connected;
      debugPrint(
        'Connectivity changed: ${connected ? "ONLINE" : "OFFLINE"} ($results)',
      );
    }
  }

  /// Khusus untuk unit & widget testing
  @visibleForTesting
  void setMockOnline(bool online) {
    isOnlineNotifier.value = online;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
