import 'package:get/get.dart';

import '../controllers/edit_info_controller.dart';


class EditInfoBinding extends Bindings {
@override
void dependencies() {
Get.lazyPut(() => EditInfoController());
}
}