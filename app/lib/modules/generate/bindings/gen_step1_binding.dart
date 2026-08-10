
import 'package:get/get.dart';
import '../controllers/gen_step1_controller.dart';

class GenStep1Binding extends Bindings {
  @override
  void dependencies() {
    
    Get.lazyPut<GenStep1Controller>(() => GenStep1Controller());
  }
}
