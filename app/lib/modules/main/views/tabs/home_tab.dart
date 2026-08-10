
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_style.dart';
import '../../../../core/routes/app_pages.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  Widget _actionTile({
    required BuildContext context,
    required VoidCallback onTap,
    required String title,
    String? subtitle,
    String? assetImage,
    Gradient? gradient,
    double height = 160,
  }) {
    final width = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient:
              gradient ??
              const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.textGrey],
              ),
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                  const Spacer(),
                  
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: assetImage != null
                  ? Center(
                      child: Image.asset(
                        assetImage,
                        width: (width * 0.28).clamp(64.0, 140.0),
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    final width = MediaQuery.of(c).size.width;
    final isWide = width > 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppStyles.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              
              InkWell(
                onTap: () => Get.toNamed(Routes.LOOKS),
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                child: Container(
                  height: isWide ? 240 : 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [AppColors.accentMint, AppColors.primary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/home_looks.png',
                          fit: BoxFit.contain,
                          width: width * 0.65,
                          height: 150,
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'My looks',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 80),
                            Text(
                              'View and manage your saved outfits',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              
              Wrap(
                runSpacing: 12,
                spacing: 12,
                children: [
                  SizedBox(
                    width: isWide
                        ? (width -
                                  2 * AppStyles.screenPadding.horizontal -
                                  24) /
                              3
                        : width,
                    child: _actionTile(
                      context: c,
                      onTap: () => Get.toNamed(Routes.GEN_STEP1),
                      title: 'Let AI generate',
                      subtitle: 'Generate outfit based on weather & occasion',
                      assetImage: 'assets/images/generate_ai.png',
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xffA7F3D0), AppColors.primary],
                      ),
                      height: 150,
                    ),
                  ),
                  SizedBox(
                    width: isWide
                        ? (width -
                                  2 * AppStyles.screenPadding.horizontal -
                                  24) /
                              3
                        : width,
                    child: _actionTile(
                      context: c,
                      onTap: () => Get.toNamed(
                        Routes.ADD_ITEM,
                      ), 
                      title: 'Upload item',
                      subtitle:
                          'Add an item from gallery or camera to your wardrobe',
                      assetImage: 'assets/images/generate_manual.png',
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primarySoft],
                      ),
                      height: 150,
                    ),
                  ),
                  SizedBox(
                    width: isWide
                        ? (width -
                                  2 * AppStyles.screenPadding.horizontal -
                                  24) /
                              3
                        : width,
                  ),
                ],
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
