
import 'package:get/get.dart';
import '../controllers/gen_step3_controller.dart';

class GenStep3Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GenStep3Controller>(() => GenStep3Controller());
  }
}
