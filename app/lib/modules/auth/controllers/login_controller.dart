import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/routes/app_pages.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/snackbar_util.dart';
import '../../wardrobe/controllers/wardrobe_controller.dart';

class LoginController extends GetxController {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final isLoading = false.obs;

  var isPasswordHidden = true.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> login() async {
    if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
      SnackbarUtil.showError('All fields are required.');
      return;
    }

    isLoading.value = true;
    try {
      final response = await ApiService.dio.post(
        'login',
        data: {'email': emailCtrl.text.trim(), 'password': passwordCtrl.text},
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map) {
        SnackbarUtil.showSuccess('Login successful!');

        final box = GetStorage();

        // GetStorage is not encrypted, so it holds the session token only —
        // never the password. Credentials are exchanged for a token and then
        // discarded.
        final token = (data['accessToken'] ?? data['access_token'] ?? '')
            .toString();
        box.write('first_name', data['first_name'] ?? '');
        box.write('last_name', data['last_name'] ?? '');
        box.write('email', data['email'] ?? '');
        box.write('accessToken', token);

        final gender = (data['gender'] ?? '').toString().toLowerCase();
        if (gender.isNotEmpty) {
          box.write('gender', gender);
          if (Get.isRegistered<WardrobeController>()) {
            try {
              Get.find<WardrobeController>().setUserGender(gender);
            } catch (_) {}
          }
        }

        Get.offAllNamed(Routes.MAIN);
      } else {
        SnackbarUtil.showError(_messageFor(response.statusCode, response.data));
      }
    } on DioException catch (e) {
      if (e.response != null) {
        SnackbarUtil.showError(
          _messageFor(e.response!.statusCode, e.response!.data),
        );
      } else {
        SnackbarUtil.showError(
          'Could not reach the server. Check your connection and try again.',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Turns a failed login response into something worth showing the user.
  /// The backend reports auth failures as `{"error": "Invalid credentials"}`
  /// and validation failures as `{"errors": {"email": ["..."]}}`.
  String _messageFor(int? statusCode, dynamic body) {
    if (statusCode == 401) {
      return 'Invalid email or password.';
    }

    if (body is Map) {
      final direct = body['error'] ?? body['message'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString();
      }

      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first != null) return first.toString();
      }
    }

    if (statusCode != null && statusCode >= 500) {
      return 'The server ran into a problem. Please try again later.';
    }

    return 'Login failed. Please try again.';
  }

  void goToSignUp() {
    Get.toNamed(Routes.SIGNUP_STEP1);
  }

  //  @override
  //  void onClose() {
  //    emailCtrl.dispose();
  //    passwordCtrl.dispose();
  //    super.onClose();
  //  }
}
