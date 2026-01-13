import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/session_service.dart';

/// Widget yang mendeteksi aktivitas user (tap, scroll, dll)
/// dan mereset session timer
class ActivityDetector extends StatelessWidget {
  final Widget child;

  const ActivityDetector({super.key, required this.child});

  void _onUserActivity() {
    // Reset timer setiap ada aktivitas
    if (Get.isRegistered<SessionService>()) {
      Get.find<SessionService>().resetTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserActivity(),
      onPointerMove: (_) => _onUserActivity(),
      onPointerUp: (_) => _onUserActivity(),
      child: child,
    );
  }
}
