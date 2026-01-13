import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/traccar_api_service.dart';
import '../../routes/app_pages.dart';

/// Service untuk mengelola session timeout
/// Auto logout setelah 1 menit tidak ada aktivitas
class SessionService extends GetxService {
  static const int timeoutDuration = 60; // 1 menit dalam detik
  
  Timer? _inactivityTimer;
  final _remainingSeconds = timeoutDuration.obs;
  final _isWarningShown = false.obs;
  
  int get remainingSeconds => _remainingSeconds.value;
  bool get isWarningShown => _isWarningShown.value;

  @override
  void onInit() {
    super.onInit();
    resetTimer();
  }

  /// Reset timer setiap ada aktivitas user
  void resetTimer() {
    _inactivityTimer?.cancel();
    _remainingSeconds.value = timeoutDuration;
    _isWarningShown.value = false;
    
    _inactivityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds.value--;
      
      // Tampilkan warning 10 detik sebelum logout
      if (_remainingSeconds.value == 10 && !_isWarningShown.value) {
        _showTimeoutWarning();
      }
      
      // Auto logout ketika waktu habis
      if (_remainingSeconds.value <= 0) {
        _performAutoLogout();
      }
    });
  }

  /// Tampilkan warning sebelum logout
  void _showTimeoutWarning() {
    _isWarningShown.value = true;
    
    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.timer_off, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Sesi Akan Berakhir', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Anda akan logout otomatis karena tidak ada aktivitas.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Text(
                '${_remainingSeconds.value} detik',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                resetTimer();
              },
              child: const Text(
                'Tetap Login',
                style: TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Lakukan auto logout
  void _performAutoLogout() {
    _inactivityTimer?.cancel();
    
    // Tutup dialog jika masih terbuka
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
    
    // Logout dari Traccar
    final traccarApi = Get.find<TraccarApiService>();
    traccarApi.logout();
    
    // Navigate ke login
    Get.offAllNamed(Routes.login);
    
    // Tampilkan pesan
    Get.snackbar(
      'Sesi Berakhir',
      'Anda telah logout otomatis karena tidak ada aktivitas',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Stop timer (dipanggil saat logout manual)
  void stopTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  @override
  void onClose() {
    stopTimer();
    super.onClose();
  }
}
