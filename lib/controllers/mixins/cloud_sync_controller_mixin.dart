import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../services/auth_service.dart';

/// Mixin penyedia kemampuan sinkronisasi stream Cloud Firestore pada controller.
///
/// Mengenkapsulasi listener status autentikasi, stream cloud realtime, dan
/// mekanisme debounce sinkronisasi secara terpusat agar lapisan View tidak
//// berinteraksi langsung dengan backend streams (mematuhi prinsip MVC dan Reusability).
mixin CloudSyncControllerMixin on ChangeNotifier {
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<dynamic>? _cloudSubscription;
  String? _activeSubscribedUid;
  Timer? _syncDebounceTimer;

  /// Memulai pemantauan stream cloud berdasarkan UID pengguna yang sedang aktif.
  void initCloudSyncSubscription<T>({
    required Stream<T> Function(String uid) streamFactory,
    required Future<void> Function() onDataTriggered,
    Duration debounceDuration = const Duration(milliseconds: 300),
  }) {
    _authSubscription?.cancel();
    _authSubscription = AuthService.instance.authStateChanges.listen((user) {
      final uid = user?.uid;
      if (uid != null) {
        _subscribeToStream<T>(
          uid: uid,
          streamFactory: streamFactory,
          onDataTriggered: onDataTriggered,
          debounceDuration: debounceDuration,
        );
      } else {
        cancelCloudSyncSubscription();
      }
    });

    final currentUid = AuthService.instance.currentUser?.uid;
    if (currentUid != null) {
      _subscribeToStream<T>(
        uid: currentUid,
        streamFactory: streamFactory,
        onDataTriggered: onDataTriggered,
        debounceDuration: debounceDuration,
      );
    }
  }

  void _subscribeToStream<T>({
    required String uid,
    required Stream<T> Function(String uid) streamFactory,
    required Future<void> Function() onDataTriggered,
    required Duration debounceDuration,
  }) {
    if (_activeSubscribedUid == uid && _cloudSubscription != null) {
      return;
    }
    _activeSubscribedUid = uid;

    _cloudSubscription?.cancel();
    try {
      _cloudSubscription = streamFactory(uid).listen(
        (_) {
          _syncDebounceTimer?.cancel();
          _syncDebounceTimer = Timer(debounceDuration, () {
            onDataTriggered().ignore();
          });
        },
        onError: (error) {
          debugPrint('[CloudSyncControllerMixin] Stream error: $error');
        },
      );
    } catch (e) {
      debugPrint(
        '[CloudSyncControllerMixin] Gagal menginisialisasi stream: $e',
      );
    }
  }

  /// Membatalkan seluruh subscription cloud sync aktif saat controller di-dispose.
  void cancelCloudSyncSubscription() {
    _authSubscription?.cancel();
    _authSubscription = null;
    _cloudSubscription?.cancel();
    _cloudSubscription = null;
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = null;
    _activeSubscribedUid = null;
  }
}
