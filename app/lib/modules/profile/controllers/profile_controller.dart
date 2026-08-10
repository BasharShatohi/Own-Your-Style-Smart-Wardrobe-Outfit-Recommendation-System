
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/routes/app_pages.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/snackbar_util.dart';

class ProfileController extends GetxController {
  final box = GetStorage();
  final isLoggingOut = false.obs;

 
  late final firstName = box.read('first_name')?.toString().obs ?? ''.obs;
  late final lastName = box.read('last_name')?.toString().obs ?? ''.obs;
  late final email = box.read('email')?.toString().obs ?? ''.obs;

 
  String get fullName => '${firstName.value} ${lastName.value}'.trim();

  Future<void> logout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;

    
    const logoutUrl = 'logout';

    try {
      final token = (box.read('accessToken') ?? '').toString();

      if (token.isEmpty) {
        SnackbarUtil.showSuccess('Logged out.');
        _finalizeLogout();
        return;
      }

      final resp = await ApiService.dio.post(
        logoutUrl,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final message = (resp.data is Map)
          ? (resp.data['message']?.toString() ?? 'Successfully logged out.')
          : 'Successfully logged out.';
      SnackbarUtil.showSuccess(message);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response?.data['message']?.toString() ?? 'Logout failed')
          : (e.message ?? 'Logout failed');
      SnackbarUtil.showError(msg);
    } catch (_) {
      SnackbarUtil.showError('Logout failed');
    } finally {
      _finalizeLogout();
    }
  }

  void _finalizeLogout() {
    box.erase();
    isLoggingOut.value = false;
    Get.offAllNamed(Routes.LOGIN);
  }
}
