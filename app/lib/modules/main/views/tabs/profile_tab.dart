
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_style.dart';
import '../../../../core/routes/app_pages.dart';
import '../../../profile/controllers/profile_controller.dart';

class ProfileTab extends GetView<ProfileController> {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppStyles.screenPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Obx(
                    () => Text(
                      controller.fullName,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentMint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'signed in as:',
                    style: TextStyle(fontSize: 14, color: AppColors.textDark),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Text(
                    controller.email.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),

                // Edit basic information
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.textDark),
                  title: const Text('Edit basic information'),
                  onTap: () => Get.toNamed(Routes.EDIT_INFO),
                ),
                const Divider(),

                
                ListTile(
                  leading: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.textDark,
                  ),
                  title: const Text('Support and feedback'),
                  onTap: () => Get.toNamed(Routes.SUPPORT),
                ),
                const Divider(),

                
                ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                    color: AppColors.textDark,
                  ),
                  title: const Text('About'),
                  onTap: () => Get.toNamed(Routes.ABOUT),
                ),
                const Divider(),

                
                Obx(() {
                  final loggingOut = controller.isLoggingOut.value;
                  return ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: AppColors.textDark,
                    ),
                    title: Text(loggingOut ? 'Logging out...' : 'Log out'),
                    trailing: loggingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: loggingOut ? null : controller.logout,
                  );
                }),

                SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textGrey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppStyles.borderRadius,
                      ),
                    ),
                    child: const Text(
                      'Body Styler 1.0',
                      style: TextStyle(
                        color: AppColors.accentMint,
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
