// lib/core/routes/app_pages.dart
import 'package:get/get.dart';
import '../../modules/auth/bindings/home_binding.dart';
import '../../modules/auth/bindings/login_binding.dart';
import '../../modules/auth/bindings/signup_step1_binding.dart';
import '../../modules/auth/bindings/signup_step2_binding.dart';
import '../../modules/auth/views/home_view.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/auth/views/signup_step1_view.dart';
import '../../modules/auth/views/signup_step2_view.dart';
import '../../modules/generate/bindings/gen_step1_binding.dart';
import '../../modules/generate/bindings/gen_step2_binding.dart';
import '../../modules/generate/bindings/gen_step3_binding.dart';
import '../../modules/generate/views/gen_step1_view.dart';
import '../../modules/generate/views/gen_step2_view.dart';
import '../../modules/generate/views/gen_step3_view.dart';
import '../../modules/main/bindings/main_binding.dart';
import '../../modules/main/views/main_view.dart';
import '../../modules/profile/bindings/about_binding.dart';
import '../../modules/profile/bindings/edit_info_binding.dart';
import '../../modules/profile/bindings/support_binding.dart';
import '../../modules/profile/views/about_view.dart';
import '../../modules/profile/views/edit_info_view.dart';
import '../../modules/profile/views/support_view.dart';
import '../../modules/splash/bindings/splash_binding.dart';
import '../../modules/splash/views/splash_view.dart';
import '../../modules/wardrobe/bindings/add_item2_binding.dart';
import '../../modules/wardrobe/bindings/add_item_binding.dart';
import '../../modules/wardrobe/bindings/wardrobe_binding.dart';
import '../../modules/wardrobe/views/add_item2_view.dart';
import '../../modules/wardrobe/views/add_item_view.dart';
import '../../modules/wardrobe/views/wardrobe_view.dart';
import '../../modules/looks/bindings/looks_binding.dart';
import '../../modules/looks/views/looks_view.dart';




part 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.SIGNUP_STEP1,
      page: () => const SignUpStep1View(),
      binding: SignUpStep1Binding(),
    ),
    GetPage(
      name: Routes.SIGNUP_STEP2,
      page: () => SignUpStep2View(),
      binding: SignUpStep2Binding(),
    ),
    GetPage(
      name: Routes.MAIN,
      page: () => const MainView(),
      binding: MainBinding(),
    ),
    GetPage(
      name: Routes.EDIT_INFO,
      page: () => const EditInfoView(),
      binding: EditInfoBinding(),
    ),
    GetPage(
      name: Routes.SUPPORT,
      page: () => const SupportView(),
      binding: SupportBinding(),
    ),
    GetPage(
      name: Routes.ABOUT,
      page: () => const AboutView(),
      binding: AboutBinding(),
    ),
    GetPage(
      name: Routes.WARDROBE,
      page: () => const WardrobeView(),
      binding: WardrobeBinding(),
    ),
    GetPage(
      name: Routes.ADD_ITEM,
      page: () => const AddItemView(),
      binding: AddItemBinding(),
    ),
     GetPage(
      name: Routes.ADD_ITEM2,
      page: () => const AddItem2View(),
      binding: AddItem2Binding(),
    ),
    GetPage(
      name: Routes.GEN_STEP1,
      page: () => const GenStep1View(),
      binding: GenStep1Binding(),
    ),
    GetPage(
      name: Routes.GEN_STEP2,
      page: () => const GenStep2View(),
      binding: GenStep2Binding(),
    ),
    GetPage(
      name: Routes.GEN_STEP3,
      page: () => const GenStep3View(),
      binding: GenStep3Binding(),
    ),
   GetPage(
  name: Routes.LOOKS,
  page: () => const LooksView(),
  binding: LooksBinding(),
),

    
  ];
}
