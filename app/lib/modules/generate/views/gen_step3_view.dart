// lib/modules/generate/views/gen_step3_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/gen_step3_controller.dart';
import '../../../core/widgets/outfit_board.dart';

class GenStep3View extends GetView<GenStep3Controller> {
  const GenStep3View({Key? key}) : super(key: key);

  Widget _buildInfoChips(String title, List<String> items, Color accent) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    title.toLowerCase().contains('gap') ? Icons.report_gmailerrorred : Icons.lightbulb,
                    color: accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: items.map((s) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Chip(
                      backgroundColor: accent.withOpacity(0.12),
                      label: Text(
                        s,
                        style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GenStep3Controller>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Outfits'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Obx(() {
          // If there are no outfits at all, still show suggestions/gaps if present
          if (ctrl.outfits.isEmpty) {
            // show suggestions/gaps + empty text (friendly)
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (ctrl.suggestions.isNotEmpty) _buildInfoChips('Suggestions', ctrl.suggestions.toList(), Colors.teal),
                  if (ctrl.gaps.isNotEmpty) _buildInfoChips('Gaps', ctrl.gaps.toList(), Colors.orange),
                  const SizedBox(height: 22),
                  const Center(child: Text('No outfits yet', style: TextStyle(fontSize: 16))),
                ],
              ),
            );
          }

          // Otherwise show info panel above the boards
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    if (ctrl.suggestions.isNotEmpty) _buildInfoChips('Suggestions', ctrl.suggestions.toList(), Colors.teal),
                    if (ctrl.gaps.isNotEmpty) _buildInfoChips('Gaps', ctrl.gaps.toList(), Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

                    if (!isTablet) {
                      final boardWidth = (constraints.maxWidth - 40).clamp(240.0, 340.0);
                      final outfit = ctrl.outfits[0];
                      return Center(
                        child: OutfitBoard(
                          layers: outfit.layers,
                          width: boardWidth,
                          boardAspect: 1.40,
                          contentScale: 0.88,
                          highlightedIndex: ctrl.highlightedLayer.value,
                          measurementVersion: ctrl.measurementVersion.value,
                          imageHeaders: ctrl.imageHeaders,
                          initialLayerTransforms: ctrl.layerTransforms[outfit.id] ?? {},
                          onLayerTransform: (layerIndex, dx, dy, scale, rotationDeg) {
                            ctrl.setLayerTransform(0, layerIndex, dx, dy, scale, rotationDeg);
                          },
                          onTapLayer: (i) => ctrl.highlightLayer(i),
                        ),
                      );
                    }

                    const gap = 16.0;
                    const outerPad = 24.0;
                    final boardWidth = ((constraints.maxWidth - gap - outerPad * 2) / 2).clamp(240.0, 380.0);

                    final leftOutfit = ctrl.outfits[0];
                    final rightOutfit = ctrl.outfits.length > 1 ? ctrl.outfits[1] : leftOutfit;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: outerPad, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Center(
                              child: OutfitBoard(
                                layers: leftOutfit.layers,
                                width: boardWidth,
                                boardAspect: 1.85,
                                contentScale: 0.64,
                                highlightedIndex: ctrl.highlightedLayer.value,
                                measurementVersion: ctrl.measurementVersion.value,
                                imageHeaders: ctrl.imageHeaders,
                                initialLayerTransforms: ctrl.layerTransforms[leftOutfit.id] ?? {},
                                onLayerTransform: (layerIndex, dx, dy, scale, rotationDeg) {
                                  ctrl.setLayerTransform(0, layerIndex, dx, dy, scale, rotationDeg);
                                },
                                onTapLayer: (i) => ctrl.highlightLayer(i),
                              ),
                            ),
                          ),
                          const SizedBox(width: gap),
                          Expanded(
                            child: Center(
                              child: OutfitBoard(
                                layers: rightOutfit.layers,
                                width: boardWidth,
                                boardAspect: 1.85,
                                contentScale: 0.64,
                                highlightedIndex: ctrl.highlightedLayer.value,
                                measurementVersion: ctrl.measurementVersion.value,
                                imageHeaders: ctrl.imageHeaders,
                                initialLayerTransforms: ctrl.layerTransforms[rightOutfit.id] ?? {},
                                onLayerTransform: (layerIndex, dx, dy, scale, rotationDeg) {
                                  ctrl.setLayerTransform(1, layerIndex, dx, dy, scale, rotationDeg);
                                },
                                onTapLayer: (i) => ctrl.highlightLayer(i),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Obx(() {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                // Regenerate button (replaces Like/Dislike)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 6,
                      backgroundColor: Colors.grey.shade800,
                    ),
                    onPressed: ctrl.regenerating.value
                        ? null
                        : () {
                            ctrl.regenerate();
                          },
                    icon: ctrl.regenerating.value
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh),
                    label: Text(ctrl.regenerating.value ? 'Regenerating...' : 'Regenerate'),
                  ),
                ),
                const SizedBox(width: 12),
                // Save Outfit button (keeps the save functionality)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 6,
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () {
                      ctrl.save();
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Outfit'),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
