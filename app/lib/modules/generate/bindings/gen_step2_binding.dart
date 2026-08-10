
import 'package:get/get.dart';
import '../controllers/gen_step2_controller.dart';

class GenStep2Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GenStep2Controller());
  }
}
