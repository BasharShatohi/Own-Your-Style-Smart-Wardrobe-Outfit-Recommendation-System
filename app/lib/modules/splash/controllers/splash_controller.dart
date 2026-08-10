import 'dart:async';
import 'package:get/get.dart';
import '../../../core/routes/app_pages.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    Timer(const Duration(seconds: 3), () {
      Get.offNamed(Routes.LOGIN);
    });
  }
}
