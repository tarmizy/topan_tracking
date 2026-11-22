import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../core/utils/support.dart';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../../data/services/traccar_api_service.dart';
import '../../routes/app_pages.dart';

class LoginController extends GetxController {
  static const _savedLoginKey = 'remembered_login';
  static const _secureStorage = FlutterSecureStorage();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final rememberCredentials = false.obs;
  final isPasswordVisible = false.obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  TraccarApiService get _traccarApi => Get.find<TraccarApiService>();

  @override
  void onInit() {
    super.onInit();
    _restoreCredentials();
  }

  Future<void> _restoreCredentials() async {
    try {
      final savedLogin = await _secureStorage.read(key: _savedLoginKey);
      if (isClosed || savedLogin == null) return;

      final credentials = jsonDecode(savedLogin);
      if (credentials case {
        'email': final String email,
        'password': final String password,
      }) {
        if (emailController.text.isEmpty && passwordController.text.isEmpty) {
          emailController.text = email;
          passwordController.text = password;
        }
        rememberCredentials.value = true;
      }
    } on Exception {
      if (!isClosed) {
        errorMessage.value =
            'Email dan kata sandi tersimpan tidak dapat dibaca.';
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> setRememberCredentials(bool checked) async {
    if (isLoading.value) return;
    if (checked) {
      rememberCredentials.value = true;
      return;
    }

    isLoading.value = true;
    try {
      await _secureStorage.delete(key: _savedLoginKey);
      if (!isClosed) rememberCredentials.value = false;
    } on Exception {
      if (!isClosed) {
        errorMessage.value =
            'Email dan kata sandi tersimpan tidak dapat dihapus.';
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> login() async {
    if (isLoading.value) return;
    errorMessage.value = '';

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      errorMessage.value = 'Email dan kata sandi harus diisi';
      return;
    }

    isLoading.value = true;
    try {
      final result = await _traccarApi.login(email, password);
      if (isClosed) return;
      if (!result.success) {
        errorMessage.value = result.error ?? 'Login gagal';
        return;
      }

      String? saveError;
      if (rememberCredentials.value) {
        try {
          await _secureStorage.write(
            key: _savedLoginKey,
            value: jsonEncode({'email': email, 'password': password}),
          );
        } on Exception {
          saveError = 'Email dan kata sandi tidak dapat disimpan.';
        }
      }
      if (isClosed) return;

      Get.snackbar(
        saveError == null ? 'Berhasil' : 'Berhasil masuk',
        saveError ?? "Selamat datang, ${result.data?.name ?? 'User'}!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.8),
        colorText: AppColors.onPrimary,
        duration: const Duration(seconds: 2),
      );
      Get.offAllNamed(Routes.home);
    } on Exception {
      if (!isClosed) errorMessage.value = 'Terjadi kesalahan saat masuk.';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void forgotPassword() {
    final email = emailController.text.trim();
    TopanSupport.openWhatsApp(
      'Halo Topan, saya lupa kata sandi akun saya'
      '${email.isNotEmpty ? ' ($email)' : ''}. Mohon bantu reset.',
    );
  }

  void contactSupport() {
    TopanSupport.openWhatsApp(
      'Halo Topan, saya butuh bantuan untuk akun aplikasi Topan.',
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
