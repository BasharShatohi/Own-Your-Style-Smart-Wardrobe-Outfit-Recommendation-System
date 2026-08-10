

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_style.dart';
import '../../../core/widgets/custom_button.dart';
import '../controllers/gen_step1_controller.dart';

class GenStep1View extends GetView<GenStep1Controller> {
  const GenStep1View({Key? key}) : super(key: key);

  static const occasions = [
    'Casual',
    'Formal',
    'Sport',
    'Party',
    'Wedding',
    
  ];

  IconData _getWeatherIcon(int idx) {
    final now = DateTime.now();
    final isNight = now.hour < 6 || now.hour >= 18;

    switch (idx) {
      case 0:
        return isNight ? Icons.nights_stay : Icons.wb_sunny;
      case 1:
        return Icons.cloud_queue;
      case 2:
        return Icons.umbrella;
      case 3:
        return Icons.ac_unit;
      default:
        return isNight ? Icons.nights_stay : Icons.wb_sunny;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = controller;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: AppStyles.screenPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),

                      // Header row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Generate outfit',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: isWide ? 28 : 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (ctrl.city.value.trim().isNotEmpty) {
                                ctrl.fetchWeatherManually();
                              } else {
                                ctrl.detectWeatherViaGps();
                              }
                            },
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        height: 40,
                        child: Obx(() => OutlinedButton.icon(
                              onPressed: ctrl.isFetchingWeather.value
                                  ? null
                                  : ctrl.detectWeatherViaGps,
                              icon: const Icon(Icons.gps_fixed, size: 16),
                              label: ctrl.isFetchingWeather.value
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Detect Weather Location'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            )),
                      ),
                      const SizedBox(height: 30),

                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Expanded(
                            child: TextField(
                              controller: ctrl.cityCtrl,
                              decoration: InputDecoration(
                                labelText: 'City (manual)',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),

                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: ctrl.countryCtrl,
                              decoration: InputDecoration(
                                labelText: 'Country',
                                hintText: 'US, GB, EG…',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: ctrl.fetchWeatherManually,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Use'),
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      const Spacer(),

                     
                      Obx(() {
                        final msg = ctrl.weatherError.value;
                        if (msg.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 6.0,
                            ),
                            child: Text(
                              msg,
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      Obx(
                        () => ctrl.isFetchingWeather.value
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: LinearProgressIndicator(),
                              )
                            : const SizedBox(height: 6),
                      ),

                      const SizedBox(height: 6),

                      
                      Obx(() {
                        final w = ctrl.weather.value;
                        if (w == null) return const _EmptyWeatherHint();

                        // WeatherInfo.fromJson already coerces and defaults
                        // every field, so these are plain reads.
                        final city = w.city;
                        final country = w.country;
                        final condition = w.condition;
                        final temp = w.temperatureCelsius;
                        final humidity = w.humidity;
                        final idx = ctrl.weatherIndex.value;

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _WeatherCardLarge(
                            key: ValueKey(
                              '${city}_${country}_${temp}_${condition}',
                            ),
                            city: city,
                            country: country,
                            condition: condition,
                            tempC: temp,
                            humidity: humidity,
                            iconData: _getWeatherIcon(idx),
                          ),
                        );
                      }),

                      const Spacer(),
                      SizedBox(height: 20),

                      
                      const Text(
                        'Please select occasion',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(occasions.length, (i) {
                            final selected = ctrl.occasionIndex.value == i;
                            return ChoiceChip(
                              label: Text(occasions[i]),
                              selected: selected,
                              onSelected: (_) => ctrl.selectOccasion(i),
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textDark,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            );
                          }),
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 18),

                      
                      Obx(() {
                        final enabled = ctrl.canProceed.value;
                        return CustomButton(
                          text: 'Next',
                          onPressed: enabled ? ctrl.next : null,
                          isLoading: false,
                        );
                      }),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyWeatherHint extends StatelessWidget {
  const _EmptyWeatherHint({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('empty-weather'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.textGrey.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No weather yet. Use GPS or enter your city to fetch current weather.',
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherCardLarge extends StatelessWidget {
  final String city;
  final String country;
  final String condition;
  final double tempC;
  final int humidity;
  final IconData iconData;

  const _WeatherCardLarge({
    Key? key,
    required this.city,
    required this.country,
    required this.condition,
    required this.tempC,
    required this.humidity,
    required this.iconData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayLocation = city.isNotEmpty ? '$city, $country' : country;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.accentMint, AppColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.14),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: Icon(iconData, color: Colors.white, size: 46)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayLocation,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  condition,
                  style: const TextStyle(color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${tempC.round()}°',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _SmallInfoChip(label: 'Humidity', value: '$humidity%'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _SmallInfoChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textGrey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
