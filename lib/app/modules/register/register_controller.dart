import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/traccar_api_service.dart';
import 'package:get/get.dart';
import '../../routes/app_pages.dart';

class RegisterController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isLoading = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Semua field harus diisi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withValues(alpha: 0.8),
        colorText: AppColors.onPrimary,
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        'Error',
        'Password tidak sama',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withValues(alpha: 0.8),
        colorText: AppColors.onPrimary,
      );
      return;
    }

    if (passwordController.text.length < 6) {
      Get.snackbar(
        'Error',
        'Password minimal 6 karakter',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withValues(alpha: 0.9),
        colorText: AppColors.onPrimary,
      );
      return;
    }

    isLoading.value = true;
    final api = Get.find<TraccarApiService>();
    final email = emailController.text.trim();
    final result = await api.registerUser(
      name: nameController.text.trim(),
      email: email,
      password: passwordController.text,
    );
    if (!result.success) {
      isLoading.value = false;
      Get.snackbar(
        'Pendaftaran gagal',
        result.error ?? 'Silakan coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withValues(alpha: 0.9),
        colorText: AppColors.onPrimary,
      );
      return;
    }
    final login = await api.login(email, passwordController.text);
    isLoading.value = false;
    if (login.success) {
      Get.offAllNamed(Routes.home);
    } else {
      Get.offAllNamed(Routes.login);
    }
  }

  void goToLogin() {
    Get.back();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
