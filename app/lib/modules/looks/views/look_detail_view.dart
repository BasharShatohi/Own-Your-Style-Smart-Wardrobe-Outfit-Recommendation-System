// lib/modules/looks/views/look_detail_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/outfit_board.dart';
import '../../../core/models/outfit_models.dart';
import '../controllers/looks_controller.dart'; // <- correct relative import: controllers folder is one level up

class LookDetailView extends StatefulWidget {
  final Outfit outfit;
  final Map<int, Map<String, double>>? initialTransforms;

  const LookDetailView({
    Key? key,
    required this.outfit,
    this.initialTransforms,
  }) : super(key: key);

  @override
  State<LookDetailView> createState() => _LookDetailViewState();
}

class _LookDetailViewState extends State<LookDetailView> {
  late final LooksController _ctrl;
  double _boardWidth = 300;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<LooksController>();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    _boardWidth = (screenW - 24).clamp(240.0, 800.0);

    // Outfit.layers already contains ItemLayer objects built from backend items.
    final mapped = widget.outfit.layers;

    return Scaffold(
      appBar: AppBar(title: const Text('Look Detail')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              OutfitBoard(
                layers: mapped,
                width: _boardWidth,
                showThumbnails: true,
                // measurementVersion used to force re-measure when transforms are updated externally
                measurementVersion: DateTime.now().millisecondsSinceEpoch,
                // pass headers so OutfitBoard._fetchImageBytes sets them on HTTP requests
                imageHeaders: _ctrl.imageHeaders,
                initialLayerTransforms: widget.initialTransforms,
                onLayerTransform: (index, dxFrac, dyFrac, scale, rotationDeg) {
                  // keep controller stored transforms in sync
                  _ctrl.updateLayerTransform(widget.outfit.id, index, dxFrac, dyFrac, scale, rotationDeg);
                },
              ),
              const SizedBox(height: 12),
              Text('Occasion: ${widget.outfit.occasion}'),
              Text('Gender: ${widget.outfit.gender}'),
            ],
          ),
        ),
      ),
    );
  }
}
