import 'package:get/get.dart';
import '../controllers/signup_step1_controller.dart';

class SignUpStep1Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SignUpStep1Controller());
  }
}
