import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/traccar_api_service.dart';
import '../../data/services/session_service.dart';
import '../../routes/app_pages.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  TraccarApiService get _traccarApi => Get.find<TraccarApiService>();

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> login() async {
    // Clear previous error
    errorMessage.value = '';

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      errorMessage.value = 'Email dan password harus diisi';
      return;
    }

    isLoading.value = true;

    try {
      final result = await _traccarApi.login(email, password);

      if (result.success) {
        // Initialize SessionService untuk auto logout
        if (!Get.isRegistered<SessionService>()) {
          Get.put(SessionService(), permanent: true);
        } else {
          Get.find<SessionService>().resetTimer();
        }

        Get.snackbar(
          'Berhasil',
          'Selamat datang, ${result.data?.name ?? 'User'}!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Clear and navigate
        isLoading.value = false;
        Get.offAllNamed(Routes.home);
      } else {
        isLoading.value = false;
        errorMessage.value = result.error ?? 'Login gagal';
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Terjadi kesalahan: $e';
    }
  }

  void forgotPassword() {
    Get.snackbar(
      'Info',
      'Hubungi administrator untuk reset password',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1A1A1A),
      colorText: Colors.white,
    );
  }
}
