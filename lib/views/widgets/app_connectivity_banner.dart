import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../services/connectivity_service.dart';

/// Floating Connectivity Banner ala Google Chrome di bagian atas layar.
/// Menampilkan indikator saat perangkat offline dan pita pemulihan saat kembali online.
class AppConnectivityBanner extends StatefulWidget {
  final Widget child;

  const AppConnectivityBanner({super.key, required this.child});

  @override
  State<AppConnectivityBanner> createState() => _AppConnectivityBannerState();
}

class _AppConnectivityBannerState extends State<AppConnectivityBanner> {
  final ConnectivityService _service = ConnectivityService.instance;
  bool _wasOffline = false;
  bool _showBackOnline = false;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _service.isOnlineNotifier.addListener(_onConnectivityChanged);
    // Simpan state awal (jika app mulai dalam kondisi offline)
    if (!_service.isOnline) {
      _wasOffline = true;
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _service.isOnlineNotifier.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    final bool isOnline = _service.isOnline;

    if (!isOnline) {
      _dismissTimer?.cancel();
      setState(() {
        _wasOffline = true;
        _showBackOnline = false;
      });
    } else if (_wasOffline) {
      // Hanya tampilkan "Kembali Online" jika sebelumnya memang sempat offline
      _dismissTimer?.cancel();
      setState(() {
        _showBackOnline = true;
      });

      _dismissTimer = Timer(const Duration(milliseconds: 2800), () {
        if (mounted) {
          setState(() {
            _showBackOnline = false;
            _wasOffline = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _service.isOnlineNotifier,
      builder: (context, isOnline, _) {
        final bool isOffline = !isOnline;
        final bool showBanner = isOffline || _showBackOnline;

        return Stack(
          children: [
            widget.child,

            // Floating banner di atas konten
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: AnimatedSlide(
                    offset: showBanner ? Offset.zero : const Offset(0, -1.5),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: showBanner ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: IgnorePointer(
                        ignoring: !showBanner,
                        child: _buildBannerCard(isOffline),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBannerCard(bool isOffline) {
    final Color bgColor =
        isOffline ? const Color(0xFF2C2416) : const Color(0xFF133821);
    final Color borderColor =
        isOffline ? const Color(0xFFE68A2E) : AppColors.mintAccent;
    final IconData icon =
        isOffline ? Icons.wifi_off_rounded : Icons.check_circle_rounded;
    final String message =
        isOffline
            ? 'Anda sedang offline • Berjalan dalam mode lokal'
            : 'Koneksi pulih • Sinkronisasi & AI aktif';

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: borderColor, size: 16)
                  .animate(target: isOffline ? 0 : 1)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.1, 1.1),
                    duration: 200.ms,
                  ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
