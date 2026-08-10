import 'package:get/get.dart';
import '../controllers/signup_step2_controller.dart';

class SignUpStep2Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SignUpStep2Controller());
  }
}
