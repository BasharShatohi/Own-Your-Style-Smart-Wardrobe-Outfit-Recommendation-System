import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_pages.dart';
import '../../../core/widgets/snackbar_util.dart';

class SignUpStep1Controller extends GetxController {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final isPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;
  final isLoading = false.obs;

  void togglePasswordVisibility() =>
      isPasswordHidden.value = !isPasswordHidden.value;

  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;

  void validateAndNext() {
    if (emailCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty ||
        confirmPasswordCtrl.text.isEmpty) {
      SnackbarUtil.showError('All fields are required');
      return;
    }
    if (passwordCtrl.text.length > 8) {
      SnackbarUtil.showError('Password must be 8 characters or fewer.');
      return;
    }
    if (passwordCtrl.text != confirmPasswordCtrl.text) {
      SnackbarUtil.showError('Passwords do not match');
      return;
    }

    Get.toNamed(
      Routes.SIGNUP_STEP2,
      arguments: {'email': emailCtrl.text, 'password': passwordCtrl.text},
    );
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }
}
