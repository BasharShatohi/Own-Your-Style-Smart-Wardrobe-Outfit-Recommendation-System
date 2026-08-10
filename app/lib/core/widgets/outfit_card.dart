// lib/core/widgets/outfit_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/outfit_models.dart';
import '../constants/outfit_layout.dart';
import 'dart:math' as math;

typedef LayerTapCallback = void Function(int index);

class OutfitCard extends StatelessWidget {
  final List<ItemLayer> layers; 
  final String mannequinAsset;
  final double width;
  final double height;
  final bool showThumbnails;
  final LayerTapCallback? onTapLayer;
  final int highlightedIndex; 

  
  final double contentScale; 
  final double thumbnailPaneWidth; 

  
  final Map<String, String>? imageHeaders;

  const OutfitCard({
    Key? key,
    required this.layers,
    required this.mannequinAsset,
    this.width = 240,
    this.height = 700,
    this.showThumbnails = true,
    this.onTapLayer,
    this.highlightedIndex = -1,
    this.contentScale = 0.72,
    this.thumbnailPaneWidth = 60,
    this.imageHeaders,
  }) : super(key: key);

  Widget _imageFromAssetOrUrl(
    String src, {
    BoxFit fit = BoxFit.contain,
    double? w,
    double? h,
  }) {
    if (src.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: src,
        width: w,
        height: h,
        fit: fit,
        memCacheWidth: w?.toInt(),
        memCacheHeight: h?.toInt(),
        httpHeaders: imageHeaders,
        placeholder: (_, __) => SizedBox(width: w, height: h),
        errorWidget: (_, __, ___) => SizedBox(width: w, height: h),
      );
    }
    return Image.asset(
      src,
      width: w,
      height: h,
      fit: fit,
      cacheWidth: w?.toInt(),
      cacheHeight: h?.toInt(),
      filterQuality: FilterQuality.low,
      errorBuilder: (_, __, ___) => SizedBox(width: w, height: h),
    );
  }

  Offset _presetOffsetToPixels(OutfitPreset preset, double contentW, double contentH) {
    
   
    double dx = preset.dx;
    double dy = preset.dy;
    double px = (dx.abs() <= 2.0) ? dx * contentW : dx;
    double py = (dy.abs() <= 2.0) ? dy * contentH : dy;
    return Offset(px, py);
  }

  Widget _buildLayerWidget(ItemLayer layer) {
   
    final preset = OutfitLayoutPresets.resolve(layer.group);

    
    final safeScale = preset.scale.clamp(0.5, 1.6);
    final content = FractionallySizedBox(
      widthFactor: contentScale,
      heightFactor: contentScale,
      child: _imageFromAssetOrUrl(
        layer.asset,
        w: width * contentScale,
        h: height * contentScale,
        fit: BoxFit.contain,
      ),
    );

    
    final contentW = width * contentScale;
    final contentH = height * contentScale;
    final offset = _presetOffsetToPixels(preset, contentW, contentH);

   
    Widget transformed = Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: preset.rotationDeg * math.pi / 180.0,
        child: Transform.scale(
          scale: safeScale,
          child: content,
        ),
      ),
    );

    
    bool clipLeft = layer.clipLeftHalf;
    bool clipRight = layer.clipRightHalf;
    if (!clipLeft && !clipRight) {
      if (preset.clip == 'left') clipLeft = true;
      if (preset.clip == 'right') clipRight = true;
    }

    if (clipLeft) {
      return ClipRect(
        child: Align(alignment: Alignment.centerLeft, widthFactor: 0.5, child: transformed),
      );
    } else if (clipRight) {
      return ClipRect(
        child: Align(alignment: Alignment.centerRight, widthFactor: 0.5, child: transformed),
      );
    } else {
      return transformed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = width + (showThumbnails ? thumbnailPaneWidth : 0);

    return SizedBox(
      width: totalWidth,
      height: height,
      child: Row(
        children: [
          
          SizedBox(
            width: width,
            height: height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                
                FractionallySizedBox(
                  widthFactor: contentScale,
                  heightFactor: contentScale,
                  child: _imageFromAssetOrUrl(
                    mannequinAsset,
                    w: width * contentScale,
                    h: height * contentScale,
                    fit: BoxFit.contain,
                  ),
                ),

                
                for (int i = 0; i < layers.length; i++)
                  if (layers[i].visible)
                    Opacity(
                      opacity: (highlightedIndex == -1 || highlightedIndex == i) ? 1.0 : 0.6,
                      child: _buildLayerWidget(layers[i]),
                    ),
              ],
            ),
          ),

          
          if (showThumbnails)
            Container(
              width: thumbnailPaneWidth,
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ListView.separated(
                itemCount: layers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, idx) {
                  final l = layers[idx];
                  final border = (highlightedIndex == idx)
                      ? Border.all(color: Colors.blueAccent, width: 2)
                      : Border.all(color: Colors.grey.shade200, width: 1);
                  return GestureDetector(
                    onTap: () => onTapLayer?.call(idx),
                    child: Container(
                      width: thumbnailPaneWidth - 14,
                      height: thumbnailPaneWidth - 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: border,
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: _imageFromAssetOrUrl(
                          l.asset,
                          w: thumbnailPaneWidth - 14,
                          h: thumbnailPaneWidth - 14,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
