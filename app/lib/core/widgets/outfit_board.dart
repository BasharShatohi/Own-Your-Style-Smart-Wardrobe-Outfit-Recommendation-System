// lib/core/widgets/outfit_board.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/outfit_models.dart';
import '../constants/outfit_layout.dart';
import '../services/api_service.dart';

typedef LayerTapCallback = void Function(int index);
typedef LayerTransformCallback =
    void Function(
      int index,
      double dxFraction,
      double dyFraction,
      double scale,
      double rotationDeg,
    );

class OutfitBoard extends StatefulWidget {
  final List<ItemLayer> layers;
  final double width;
  final double boardAspect;
  final double cornerRadius;
  final double thumbnailPaneWidth;
  final double contentScale; // fraction of board used by content (0..1)
  final int highlightedIndex;
  final LayerTapCallback? onTapLayer;
  final LayerTransformCallback? onLayerTransform;
  final bool showThumbnails;
  final int measurementVersion;

  /// optional headers to use when fetching remote images (e.g. Authorization)
  final Map<String, String>? imageHeaders;

  /// optional initial absolute transforms for each layer (keys = layer index).
  final Map<int, Map<String, double>>? initialLayerTransforms;

  /// Global overall scale multiplier (0.5..1.2). Use to quickly shrink/expand everything.
  final double overallScale;

  const OutfitBoard({
    Key? key,
    required this.layers,
    required this.width,
    this.boardAspect = 1.85,
    this.cornerRadius = 20,
    this.thumbnailPaneWidth = 56,
    this.contentScale = 0.68,
    this.highlightedIndex = -1,
    this.onTapLayer,
    this.onLayerTransform,
    this.showThumbnails = true,
    this.measurementVersion = 0,
    this.imageHeaders,
    this.initialLayerTransforms,
    this.overallScale = 0.45,
  }) : super(key: key);

  @override
  State<OutfitBoard> createState() => _OutfitBoardState();
}

class _OutfitBoardState extends State<OutfitBoard> {
  final Map<String, Size> _intrinsicSizeCache = {};
  final Map<int, double> _computedScale = {};
  bool _measuring = false;
  final Map<int, Offset> _userOffsetPx = {};
  final Map<int, double> _userScale = {};
  final Map<int, double> _userRotationDeg = {};
  int? _gestureActiveIndex;
  Offset _gestureStartPosition = Offset.zero;
  Offset _gestureStartOffset = Offset.zero;
  double _gestureStartScale = 1.0;
  double _gestureStartRotation = 0.0;
  bool _isDisposed = false;
  final List<HttpClient> _activeHttpClients = [];

  double _finite(double value, double fallback) {
    return value.isFinite ? value : fallback;
  }

  double _clampDouble(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  // Tuned target heights
  static const Map<String, double> _targetHeightFractionByGroup = {
    'footwear': 0.10,
    'bottoms': 0.34,               // lowered from 0.40 -> less tall
    'tops': 0.36,
    'outerwear': 0.50,            // lowered from 0.62 -> much less tall
    'dresses & rompers': 0.50,
    'bags': 0.26,
    'headwear': 0.16,
    'neckwear': 0.10,
    'wristwear': 0.08,
    'handwear': 0.10,
    'eyewear': 0.08,
    'socks & hosiery': 0.14,
    'other accessories': 0.18,
    'underwear & swimwear': 0.30,
    'skirts': 0.36,
    'earwear': 0.10,
  };

  // Per-group multipliers to shrink some categories
  static const Map<String, double> groupScaleMultiplier = {
    'dresses & rompers': 0.80,
    'skirts': 0.85,
    'outerwear': 0.82,   // from 0.95 -> 0.82 (makes coats/jackets appear smaller)
    'bottoms': 0.88,     // from 0.95 -> 0.88 (shorts & pants slightly smaller)
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAll());
  }

  @override
  void didUpdateWidget(covariant OutfitBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEqualsAssets(
      oldWidget.layers.map((e) => e.asset).toList(),
      widget.layers.map((e) => e.asset).toList(),
    )) {
      _intrinsicSizeCache.clear();
      _computedScale.clear();
      _measureAll();
      return;
    }

    if (widget.measurementVersion != oldWidget.measurementVersion) {
      _intrinsicSizeCache.clear();
      _computedScale.clear();
      _measureAll();
      return;
    }

    if (widget.initialLayerTransforms != oldWidget.initialLayerTransforms) {
      _applyInitialTransforms();
    }
  }

  bool _listEqualsAssets(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    try {
      setState(fn);
    } catch (_) {}
  }

  Future<void> _measureAll() async {
    if (_measuring || _isDisposed) return;
    _measuring = true;

    final boardW = widget.width;
    final boardH = widget.width * widget.boardAspect;
    final contentW = boardW * widget.contentScale;
    final contentH = boardH * widget.contentScale;

    final uniq = <String>{};
    for (final l in widget.layers) uniq.add(l.asset);

    for (final src in uniq) {
      if (_intrinsicSizeCache.containsKey(src)) continue;
      try {
        final bytes = await _fetchImageBytes(src);
        if (_isDisposed) break;
        if (bytes != null) {
          final sz = await _getImageSizeFromBytes(bytes);
          if (_isDisposed) break;
          if (sz != null) _intrinsicSizeCache[src] = sz;
        }
      } catch (e) {
        debugPrint('OutfitBoard measure error for $src: $e');
      }
    }

    if (_isDisposed) {
      _measuring = false;
      return;
    }

    for (int i = 0; i < widget.layers.length; i++) {
      final layer = widget.layers[i];
      final src = layer.asset;
      final intrinsic = _intrinsicSizeCache[src];
      final resolved = OutfitLayoutPresets.resolve(layer.group);
      final presetScale = resolved.scale;
      if (intrinsic == null) {
        _computedScale[i] = presetScale;
        continue;
      }

      final groupKey = layer.group.toLowerCase();
      var targetFraction = _targetHeightFractionByGroup[groupKey] ?? 0.32;
      final catLower = layer.category.toLowerCase();

      // per-category refinements (keeps behavior consistent)
      if (groupKey == 'bottoms') {
        if (catLower.contains('short')) {
          targetFraction = 0.30;
        } else if (catLower.contains('capri') ||
            catLower.contains('denim shorts')) {
          targetFraction = 0.32;
        } else {
          targetFraction = 0.40;
        }
      } else if (groupKey == 'outerwear') {
        if (catLower.contains('puffer') ||
            catLower.contains('coat') ||
            catLower.contains('parka')) {
          targetFraction = 0.54; // slightly tuned relative to global change
        } else if (catLower.contains('jacket')) {
          targetFraction = 0.48;
        }
      } else if (groupKey == 'dresses & rompers') {
        if (catLower.contains('maxi') || catLower.contains('gown')) {
          targetFraction = 0.62;
        } else if (catLower.contains('mini') ||
            catLower.contains('t-shirt dress')) {
          targetFraction = 0.44;
        } else {
          targetFraction = 0.50;
        }
      } else if (groupKey == 'skirts') {
        if (catLower.contains('maxi')) {
          targetFraction = 0.52;
        } else if (catLower.contains('mini')) {
          targetFraction = 0.34;
        } else {
          targetFraction = 0.36;
        }
      }

      final useWidthForGroup = <String>{
        'bags',
        'headwear',
        'eyewear',
        'neckwear',
        'earwear',
        'wristwear',
        'handwear',
      }.contains(groupKey);

      double sizeBasedScale;
      if (useWidthForGroup && intrinsic.width > 0) {
        final targetWidthFraction = () {
          if (groupKey == 'earwear') return 0.12;
          if (groupKey == 'wristwear') return 0.16;
          if (groupKey == 'handwear') return 0.20;
          if (groupKey == 'eyewear') return 0.18;
          if (groupKey == 'headwear') return 0.32;
          if (groupKey == 'bags') return 0.28;
          if (groupKey == 'neckwear') return 0.22;
          return 0.24;
        }();
        final targetPxW = contentW * targetWidthFraction;
        sizeBasedScale = targetPxW / intrinsic.width;
      } else {
        final targetPxH = contentH * targetFraction;
        sizeBasedScale = intrinsic.height > 0
            ? targetPxH / intrinsic.height
            : 1.0;
      }

      double finalScale = (sizeBasedScale * presetScale);

      // Aspect-ratio compensation: if image is very tall, shrink further
      try {
        final ar =
            intrinsic.height / (intrinsic.width == 0 ? 1.0 : intrinsic.width);
        if (ar > 2.0) {
          // extremely tall (likely extra transparent space): shrink more
          finalScale *= 0.70;
        } else if (ar > 1.6) {
          finalScale *= 0.78;
        } else if (ar < 0.5) {
          // very wide — shrink slightly
          finalScale *= 0.9;
        }
      } catch (_) {}

      // Apply per-group multiplier and global overallScale
      final groupMult = groupScaleMultiplier[groupKey] ?? 1.0;
      finalScale = finalScale * groupMult * widget.overallScale;

      final clampByGroup = <String, List<double>>{
        'footwear': [0.22, 0.62],
        'outerwear': [0.30, 0.65],    // limit max size of coats & jackets
        'dresses & rompers': [0.40, 1.25],
        'skirts': [0.32, 1.15],
        'tops': [0.35, 1.45],
        'bottoms': [0.34, 1.05],      // lower maximum for bottoms (prevents very large shorts)
        'headwear': [0.20, 1.10],
        'eyewear': [0.20, 0.80],
        'neckwear': [0.15, 0.90],
        'earwear': [0.08, 0.40],
        'wristwear': [0.10, 0.60],
        'handwear': [0.12, 0.70],
        'bags': [0.30, 1.10],
        'socks & hosiery': [0.22, 0.90],
        'underwear & swimwear': [0.22, 1.10],
      };
      final clamp = clampByGroup[groupKey] ?? [0.25, 1.6];
      finalScale = finalScale.clamp(clamp[0], clamp[1]);

      if (!finalScale.isFinite || finalScale <= 0)
        finalScale = presetScale.clamp(0.25, 1.6);

      _computedScale[i] = finalScale;

      final groupDef = _groupPresetDefaults(layer.group);
      final basePreset = OutfitPreset(
        dx: resolved.dx != 0.0 ? resolved.dx : groupDef.dx,
        dy: resolved.dy != 0.0 ? resolved.dy : groupDef.dy,
        scale: resolved.scale != 1.0 ? resolved.scale : groupDef.scale,
        rotationDeg: resolved.rotationDeg != 0.0
            ? resolved.rotationDeg
            : groupDef.rotationDeg,
        clip: resolved.clip != 'none' ? resolved.clip : groupDef.clip,
      );
      widget.onLayerTransform?.call(
        i,
        basePreset.dx,
        basePreset.dy,
        _computedScale[i]!,
        basePreset.rotationDeg,
      );
    }

    _safeSetState(() {});
    _measuring = false;
    _applyInitialTransforms();
  }

  void _applyInitialTransforms() {
    final transforms = widget.initialLayerTransforms;
    if (transforms == null || transforms.isEmpty) return;
    final boardW = widget.width;
    final boardH = widget.width * widget.boardAspect;
    final contentW = boardW * widget.contentScale;
    final contentH = boardH * widget.contentScale;
    for (int i = 0; i < widget.layers.length; i++) {
      final t = transforms[i];
      if (t == null) continue;
      final absDx = t['dx'] ?? 0.0;
      final absDy = t['dy'] ?? 0.0;
      final absScale = t['scale'] ?? 1.0;
      final absRot = t['rotation'] ?? 0.0;
      final layer = widget.layers[i];
      final resolved = OutfitLayoutPresets.resolve(layer.group);
      final groupDef = _groupPresetDefaults(layer.group);
      final basePreset = OutfitPreset(
        dx: resolved.dx != 0.0 ? resolved.dx : groupDef.dx,
        dy: resolved.dy != 0.0 ? resolved.dy : groupDef.dy,
        scale: resolved.scale != 1.0 ? resolved.scale : groupDef.scale,
        rotationDeg: resolved.rotationDeg != 0.0
            ? resolved.rotationDeg
            : groupDef.rotationDeg,
        clip: resolved.clip != 'none' ? resolved.clip : groupDef.clip,
      );
      final presetOffsetPx = _fractionToPixels(
        basePreset.dx,
        basePreset.dy,
        contentW,
        contentH,
      );
      final desiredOffsetPx = _fractionToPixels(
        absDx,
        absDy,
        contentW,
        contentH,
      );
      final userOffsetPx = desiredOffsetPx - presetOffsetPx;
      final computedScale = _computedScale[i] ?? basePreset.scale;
      final userScale = (computedScale > 0) ? (absScale / computedScale) : 1.0;
      final userRotation = absRot - basePreset.rotationDeg;
      _safeSetState(() {
        _userOffsetPx[i] = userOffsetPx;
        _userScale[i] = userScale;
        _userRotationDeg[i] = userRotation;
      });
      widget.onLayerTransform?.call(i, absDx, absDy, absScale, absRot);
    }
  }

  Future<Uint8List?> _fetchImageBytes(String src) async {
    final tried = <String>{};

    Future<Uint8List?> tryFetch(String url) async {
      if (tried.contains(url)) return null;
      tried.add(url);
      try {
        final uri = Uri.parse(url);
        final client = HttpClient();
        _activeHttpClients.add(client);
        try {
          final req = await client
              .getUrl(uri)
              .timeout(const Duration(seconds: 10));
          final headers = widget.imageHeaders;
          if (headers != null && headers.isNotEmpty) {
            headers.forEach((k, v) {
              try {
                req.headers.set(k, v);
              } catch (_) {}
            });
          }
          final resp = await req.close().timeout(const Duration(seconds: 30));
          if (_isDisposed) {
            client.close(force: true);
            _activeHttpClients.remove(client);
            return null;
          }
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            final bytes = await consolidateHttpClientResponseBytes(resp);
            client.close(force: true);
            _activeHttpClients.remove(client);
            return bytes;
          } else {
            client.close(force: true);
            _activeHttpClients.remove(client);
            return null;
          }
        } catch (e) {
          client.close(force: true);
          _activeHttpClients.remove(client);
          return null;
        }
      } catch (e) {
        return null;
      }
    }

    try {
      if (src.startsWith('http')) {
        final first = src.replaceAll(RegExp(r'#+$'), '').trim();
        final bytes = await tryFetch(first);
        if (bytes != null) return bytes;

        Uri parsed;
        try {
          parsed = Uri.parse(first);
        } catch (_) {
          parsed = Uri();
        }

        try {
          final host = parsed.host;
          if ((host == 'localhost' || host == '127.0.0.1')) {
            try {
              if (Platform.isAndroid) {
                final mapped = parsed.replace(host: '10.0.2.2');
                final bytes2 = await tryFetch(mapped.toString());
                if (bytes2 != null) return bytes2;
                final mapped2 = parsed.replace(host: '127.0.0.1');
                final bytes2b = await tryFetch(mapped2.toString());
                if (bytes2b != null) return bytes2b;
              }
            } catch (_) {}
          }
        } catch (_) {}

        try {
          final base = Uri.parse(ApiService.baseUrl);
          final origin = Uri(
            scheme: base.scheme,
            host: base.host,
            port: base.hasPort ? base.port : null,
          );
          final remapped = origin.replace(
            path: parsed.path,
            query: parsed.query,
          );
          final bytes3 = await tryFetch(remapped.toString());
          if (bytes3 != null) return bytes3;
        } catch (_) {}

        try {
          final segs = parsed.pathSegments;
          if (segs.isNotEmpty) {
            final last = segs.last;
            final id = int.tryParse(last);
            if (id != null) {
              final byId = ApiService.imageUrlForItemId(id);
              final bytes4 = await tryFetch(byId);
              if (bytes4 != null) return bytes4;
            }
          }
        } catch (_) {}

        return null;
      } else {
        final bd = await rootBundle.load(src);
        return bd.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('Fetch image bytes failed for $src: $e');
      return null;
    }
  }

  Future<Size?> _getImageSizeFromBytes(Uint8List bytes) async {
    final completer = Completer<Size?>();
    try {
      ui.decodeImageFromList(bytes, (ui.Image img) {
        try {
          final s = Size(img.width.toDouble(), img.height.toDouble());
          if (!_isDisposed)
            completer.complete(s);
          else
            completer.complete(null);
        } finally {
          img.dispose();
        }
      });
      return completer.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  Offset _fractionToPixels(
    double dxFraction,
    double dyFraction,
    double contentW,
    double contentH,
  ) {
    final px = dxFraction * contentW;
    final py = dyFraction * contentH;
    return Offset(px, py);
  }

  OutfitPreset _groupPresetDefaults(String group) {
    switch (group.toLowerCase()) {
      case 'footwear':
        return const OutfitPreset(
          dx: 0.0,
          dy: 0.60,
          scale: 0.95,
          rotationDeg: -2.0,
          clip: 'none',
        );
      case 'bottoms':
        return const OutfitPreset(
          dx: 0.0,
          dy: 0.28,         // slight upward shift so bottoms sit a bit higher
          scale: 0.90,      // reduced baseline scale (was 0.98)
          rotationDeg: 0.0,
          clip: 'none',
        );
      case 'tops':
        return const OutfitPreset(
          dx: 0.04,
          dy: -0.06,
          scale: 1.0,
          rotationDeg: 0.0,
          clip: 'none',
        );
      case 'outerwear':
        return const OutfitPreset(
          dx: 0.0,
          dy: -0.06,        // shift slightly up so jackets don't crowd center
          scale: 0.88,      // reduced baseline scale (was 1.02)
          rotationDeg: 0.0,
          clip: 'none',
        );
      case 'dresses & rompers':
        return const OutfitPreset(
          dx: 0.0,
          dy: 0.02,
          scale: 0.78,
          rotationDeg: 0.0,
          clip: 'none',
        );
      case 'bags':
        return const OutfitPreset(
          dx: 0.28,
          dy: -0.02,
          scale: 0.82,
          rotationDeg: -6.0,
          clip: 'none',
        );
      case 'headwear':
        return const OutfitPreset(
          dx: 0.0,
          dy: -0.34,
          scale: 0.55,
          rotationDeg: 0.0,
          clip: 'none',
        );
      case 'neckwear':
        return const OutfitPreset(
          dx: 0.0,
          dy: -0.10,
          scale: 0.70,
          rotationDeg: 0.0,
          clip: 'none',
        );
      case 'wristwear':
        return const OutfitPreset(
          dx: 0.20,
          dy: 0.48,
          scale: 0.55,
          rotationDeg: 0.0,
          clip: 'none',
        );
      case 'eyewear':
        return const OutfitPreset(
          dx: 0.0,
          dy: -0.12,
          scale: 0.45,
          rotationDeg: 0.0,
          clip: 'none',
        );
      case 'skirts':
        return const OutfitPreset(
          dx: 0.0,
          dy: 0.28,
          scale: 0.88,
          rotationDeg: 0.0,
          clip: 'none',
        );
      default:
        return const OutfitPreset(
          dx: 0.0,
          dy: 0.0,
          scale: 1.0,
          rotationDeg: 0.0,
          clip: 'none',
        );
    }
  }

  Widget _img(String src, {BoxFit fit = BoxFit.contain, double? w, double? h}) {
    if (src.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: src,
        fit: fit,
        width: w,
        height: h,
        httpHeaders: widget.imageHeaders,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      );
    } else {
      return Image.asset(
        src,
        fit: fit,
        width: w,
        height: h,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
  }

  Widget _buildLayerWidget({
    required ItemLayer layer,
    required int index,
    required double contentW,
    required double contentH,
  }) {
    final cat = layer.category.trim();
    final catLower = cat.toLowerCase();
    final resolved = OutfitLayoutPresets.resolve(layer.group);
    final groupDef = _groupPresetDefaults(layer.group);

    final basePreset = OutfitPreset(
      dx: resolved.dx != 0.0 ? resolved.dx : groupDef.dx,
      dy: resolved.dy != 0.0 ? resolved.dy : groupDef.dy,
      scale: resolved.scale != 1.0 ? resolved.scale : groupDef.scale,
      rotationDeg: resolved.rotationDeg != 0.0
          ? resolved.rotationDeg
          : groupDef.rotationDeg,
      clip: resolved.clip != 'none' ? resolved.clip : groupDef.clip,
    );

    double presetDx = basePreset.dx;
    double presetDy = basePreset.dy;
    double presetScale = basePreset.scale;
    double presetRot = basePreset.rotationDeg;
    String presetClip = basePreset.clip;
    final groupKey = layer.group.toLowerCase();

    // category-specific tweaks (tuned)
    if (groupKey == 'bottoms') {
      if (catLower.contains('short')) {
        presetDy = basePreset.dy - 0.10;         // move shorts a bit higher
        presetScale = basePreset.scale * 0.80;   // make shorts noticeably smaller
      } else if (catLower.contains('capri')) {
        presetDy = basePreset.dy - 0.02;
        presetScale = basePreset.scale * 0.94;
      } else {
        presetDy = basePreset.dy;
        presetScale = basePreset.scale * 0.94;   // slight global reduction for pants
      }
    }

    if (groupKey == 'outerwear') {
      if (catLower.contains('puffer') ||
          catLower.contains('coat') ||
          catLower.contains('parka')) {
        presetDy = basePreset.dy + 0.02;    // slightly lower the vertical offset
        presetScale = (basePreset.scale * 0.98).clamp(0.30, 0.65); // don't upsize
        presetClip = 'none';
      } else if (catLower.contains('jacket')) {
        presetDy = basePreset.dy - 0.02;
        presetScale = (basePreset.scale * 0.92).clamp(0.30, 0.65);
      }
    }

    if (groupKey == 'footwear') {
      if (catLower.contains('boot')) {
        presetScale = (basePreset.scale * 0.86).clamp(0.22, 0.9);
        presetDy = basePreset.dy + 0.06;
      } else if (catLower.contains('sneaker') ||
          catLower.contains('sneakers')) {
        presetScale = (basePreset.scale * 0.96).clamp(0.22, 0.7);
        presetRot = basePreset.rotationDeg - 4.0;
      }
    }

    if (groupKey == 'tops') {
      if (catLower.contains('hoodie') || catLower.contains('sweater')) {
        presetScale = (basePreset.scale * 1.02).clamp(0.5, 1.45);
        presetDy = basePreset.dy + 0.02;
      } else if (catLower.contains('tank') || catLower.contains('crop')) {
        presetScale = (basePreset.scale * 0.92).clamp(0.4, 1.2);
        presetDy = basePreset.dy - 0.03;
      }
    }

    if (groupKey == 'bags') {
      if (catLower.contains('backpack')) {
        presetDx = 0.18;
        presetScale = basePreset.scale * 1.04;
      } else if (catLower.contains('clutch')) {
        presetDx = 0.36;
        presetScale = basePreset.scale * 0.6;
      }
    }

    if (groupKey == 'skirts') {
      if (catLower.contains('maxi')) {
        presetScale = (basePreset.scale * 1.00).clamp(0.30, 1.15);
        presetDy = basePreset.dy + 0.04;
      } else if (catLower.contains('mini')) {
        presetScale = (basePreset.scale * 0.92).clamp(0.30, 1.05);
        presetDy = basePreset.dy - 0.02;
      } else {
        presetScale = (basePreset.scale * 0.96).clamp(0.30, 1.15);
      }
    }

    if (groupKey == 'dresses & rompers') {
      if (catLower.contains('maxi') || catLower.contains('gown')) {
        presetScale = (basePreset.scale * 0.98).clamp(0.45, 1.25);
        presetDy = basePreset.dy + 0.04;
      } else if (catLower.contains('mini') ||
          catLower.contains('t-shirt dress')) {
        presetScale = (basePreset.scale * 0.88).clamp(0.45, 1.05);
        presetDy = basePreset.dy - 0.02;
      } else {
        presetScale = (basePreset.scale * 0.92).clamp(0.45, 1.15);
        presetDy = basePreset.dy;
      }
    }

    if (groupKey == 'socks & hosiery') {
      if (catLower.contains('knee') || catLower.contains('tights')) {
        presetScale = (basePreset.scale * 1.06).clamp(0.22, 0.9);
        presetDy = basePreset.dy + 0.02;
      } else {
        presetScale = (basePreset.scale * 0.96).clamp(0.22, 0.9);
      }
    }

    if (groupKey == 'underwear & swimwear') {
      if (catLower.contains('one-piece') || catLower.contains('swimsuit')) {
        presetScale = (basePreset.scale * 1.02).clamp(0.22, 1.1);
      } else {
        presetScale = (basePreset.scale * 0.94).clamp(0.22, 1.1);
      }
    }

    if (groupKey == 'headwear') {
      if (catLower.contains('cap') || catLower.contains('beanie')) {
        presetScale = (basePreset.scale * 0.94).clamp(0.2, 1.1);
      } else if (catLower.contains('hat') || catLower.contains('fedora')) {
        presetScale = (basePreset.scale * 1.02).clamp(0.2, 1.1);
      }
    }

    if (groupKey == 'eyewear') {
      presetScale = (basePreset.scale * 1.00).clamp(0.12, 0.8);
    }

    if (groupKey == 'neckwear') {
      if (catLower.contains('scarf') || catLower.contains('shawl')) {
        presetScale = (basePreset.scale * 1.06).clamp(0.15, 0.9);
      } else {
        presetScale = (basePreset.scale * 0.96).clamp(0.15, 0.9);
      }
    }

    if (groupKey == 'earwear') {
      presetScale = (basePreset.scale * 0.90).clamp(0.08, 0.40);
    }

    if (groupKey == 'wristwear') {
      presetScale = (basePreset.scale * 0.96).clamp(0.10, 0.60);
    }

    if (groupKey == 'handwear') {
      if (catLower.contains('glove') || catLower.contains('mitten')) {
        presetScale = (basePreset.scale * 1.02).clamp(0.12, 0.70);
      }
    }

    final preset = OutfitPreset(
      dx: presetDx,
      dy: presetDy,
      scale: presetScale,
      rotationDeg: presetRot,
      clip: presetClip,
    );

    final computedScale = _computedScale[index] ?? preset.scale;
    final content = SizedBox(
      width: contentW,
      height: contentH,
      child: _img(layer.asset, fit: BoxFit.contain, w: contentW, h: contentH),
    );

    final userOffsetPx = _userOffsetPx[index] ?? Offset.zero;
    final userScaleMulti = _userScale[index] ?? 1.0;
    final userRotationDeg = _userRotationDeg[index] ?? 0.0;

    final totalScaleRaw = computedScale * userScaleMulti;
    final double totalScale = _clampDouble(
      _finite(totalScaleRaw, preset.scale),
      0.05,
      6.0,
    );

    final scaled = Transform.scale(scale: totalScale, child: content);

    final safePresetDx = _finite(preset.dx, 0.0);
    final safePresetDy = _finite(preset.dy, 0.0);
    final presetOffsetPx = _fractionToPixels(
      safePresetDx,
      safePresetDy,
      contentW,
      contentH,
    );
    final finalOffsetRaw = presetOffsetPx + userOffsetPx;
    final finalOffset = Offset(
      _finite(finalOffsetRaw.dx, 0.0),
      _finite(finalOffsetRaw.dy, 0.0),
    );

    final rotated = Transform.rotate(
      angle:
          _finite((preset.rotationDeg + userRotationDeg), 0.0) *
          (3.141592653589793 / 180.0),
      child: scaled,
    );
    final translated = Transform.translate(offset: finalOffset, child: rotated);

    bool clipLeft = layer.clipLeftHalf;
    bool clipRight = layer.clipRightHalf;
    if (!clipLeft && !clipRight) {
      if (preset.clip == 'left') clipLeft = true;
      if (preset.clip == 'right') clipRight = true;
    }

    Widget finalWidget = translated;
    if (clipLeft) {
      finalWidget = ClipPath(
        clipper: _HalfBoardClipper(side: _HalfSide.left),
        child: finalWidget,
      );
    } else if (clipRight) {
      finalWidget = ClipPath(
        clipper: _HalfBoardClipper(side: _HalfSide.right),
        child: finalWidget,
      );
    }

    return RawGestureDetector(
      gestures: {
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
              (TapGestureRecognizer instance) {
                instance..onTap = () => widget.onTapLayer?.call(index);
              },
            ),
        PanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
              () => PanGestureRecognizer(),
              (PanGestureRecognizer instance) {
                instance
                  ..onStart = (details) {
                    _gestureActiveIndex = index;
                    _gestureStartOffset = _userOffsetPx[index] ?? Offset.zero;
                    _gestureStartPosition = details.localPosition;
                    _gestureStartScale = _userScale[index] ?? 1.0;
                    _gestureStartRotation = _userRotationDeg[index] ?? 0.0;
                  }
                  ..onUpdate = (details) {
                    if (_gestureActiveIndex != index || _isDisposed || !mounted)
                      return;
                    final newOffset =
                        _gestureStartOffset +
                        (details.localPosition - _gestureStartPosition);
                    _safeSetState(() => _userOffsetPx[index] = newOffset);
                  }
                  ..onEnd = (details) {
                    if (_gestureActiveIndex != index) return;
                    final finalOff = _userOffsetPx[index] ?? Offset.zero;
                    final dxFrac = contentW > 0
                        ? (finalOff.dx / contentW)
                        : 0.0;
                    final dyFrac = contentH > 0
                        ? (finalOff.dy / contentH)
                        : 0.0;
                    final absDx = _finite(preset.dx + dxFrac, 0.0);
                    final absDy = _finite(preset.dy + dyFrac, 0.0);
                    final absScale = _clampDouble(
                      _finite(
                        (_computedScale[index] ?? preset.scale) *
                            (_userScale[index] ?? 1.0),
                        preset.scale,
                      ),
                      0.05,
                      6.0,
                    );
                    final absRot = _finite(
                      preset.rotationDeg + (_userRotationDeg[index] ?? 0.0),
                      0.0,
                    );
                    widget.onLayerTransform?.call(
                      index,
                      absDx,
                      absDy,
                      absScale,
                      absRot,
                    );
                    _gestureActiveIndex = null;
                  };
              },
            ),
        ScaleGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
              () => ScaleGestureRecognizer(),
              (ScaleGestureRecognizer instance) {
                instance
                  ..onStart = (details) {
                    _gestureActiveIndex ??= index;
                    if (_gestureActiveIndex != index) return;
                    _gestureStartOffset = _userOffsetPx[index] ?? Offset.zero;
                    _gestureStartScale = _userScale[index] ?? 1.0;
                    _gestureStartRotation = _userRotationDeg[index] ?? 0.0;
                    _gestureStartPosition = details.localFocalPoint;
                  }
                  ..onUpdate = (details) {
                    if (_gestureActiveIndex != index || _isDisposed || !mounted)
                      return;
                    final newScale = (_gestureStartScale * details.scale).clamp(
                      0.05,
                      6.0,
                    );
                    final newRotationDeg =
                        _gestureStartRotation +
                        (details.rotation * 180.0 / 3.141592653589793);
                    final newOffset =
                        _gestureStartOffset +
                        (details.localFocalPoint - _gestureStartPosition);
                    _safeSetState(() {
                      _userScale[index] = newScale;
                      _userRotationDeg[index] = newRotationDeg;
                      _userOffsetPx[index] = newOffset;
                    });
                  }
                  ..onEnd = (details) {
                    if (_gestureActiveIndex != index) return;
                    final finalOff = _userOffsetPx[index] ?? Offset.zero;
                    final dxFrac = contentW > 0
                        ? (finalOff.dx / contentW)
                        : 0.0;
                    final dyFrac = contentH > 0
                        ? (finalOff.dy / contentH)
                        : 0.0;
                    final absDx = _finite(preset.dx + dxFrac, 0.0);
                    final absDy = _finite(preset.dy + dyFrac, 0.0);
                    final absScale = _clampDouble(
                      _finite(
                        (_computedScale[index] ?? preset.scale) *
                            (_userScale[index] ?? 1.0),
                        preset.scale,
                      ),
                      0.05,
                      6.0,
                    );
                    final absRot = _finite(
                      preset.rotationDeg + (_userRotationDeg[index] ?? 0.0),
                      0.0,
                    );
                    widget.onLayerTransform?.call(
                      index,
                      absDx,
                      absDy,
                      absScale,
                      absRot,
                    );
                    _gestureActiveIndex = null;
                  };
              },
            ),
      },
      child: Container(width: contentW, height: contentH, child: finalWidget),
    );
  }

  void debugGestureState() {
    debugPrint('Gesture State:');
    debugPrint(' Active Index: $_gestureActiveIndex');
    debugPrint(' User Offsets: $_userOffsetPx');
    debugPrint(' User Scales: $_userScale');
    debugPrint(' User Rotations: $_userRotationDeg');
  }

  void setLayerTransform(
    int index,
    Offset offset,
    double scale,
    double rotation,
  ) {
    _safeSetState(() {
      _userOffsetPx[index] = offset;
      _userScale[index] = scale;
      _userRotationDeg[index] = rotation;
    });
  }

  Map<String, dynamic> getLayerTransformState(int index) {
    return {
      'offset': _userOffsetPx[index] ?? Offset.zero,
      'scale': _userScale[index] ?? 1.0,
      'rotation': _userRotationDeg[index] ?? 0.0,
    };
  }

  void clearLayerTransforms(int index) {
    _safeSetState(() {
      _userOffsetPx.remove(index);
      _userScale.remove(index);
      _userRotationDeg.remove(index);
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final c in _activeHttpClients) {
      try {
        c.close(force: true);
      } catch (_) {}
    }
    _activeHttpClients.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardW = widget.width;
    final boardH = widget.width * widget.boardAspect;
    final contentW = boardW * widget.contentScale;
    final contentH = boardH * widget.contentScale;

    final extraThumbWidth = widget.showThumbnails
        ? widget.thumbnailPaneWidth
        : 0.0;
    final totalWidth = boardW + extraThumbWidth;
    final safeWidth = totalWidth.isFinite ? totalWidth : boardW;
    final safeHeight = boardH.isFinite ? boardH : (boardW * 1.6);

    return Container(
      width: safeWidth,
      height: safeHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.layers.where((l) => l.visible).isEmpty)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'No items yet',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                  for (int i = 0; i < widget.layers.length; i++) ...[
                    if (widget.layers[i].visible)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity:
                            (widget.highlightedIndex == -1 ||
                                widget.highlightedIndex == i)
                            ? 1.0
                            : 0.55,
                        child: _buildLayerWidget(
                          layer: widget.layers[i],
                          index: i,
                          contentW: contentW,
                          contentH: contentH,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (widget.showThumbnails)
            SizedBox(
              width: widget.thumbnailPaneWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 6,
                ),
                child: ListView.separated(
                  itemCount: widget.layers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final l = widget.layers[idx];
                    final active = widget.highlightedIndex == idx;
                    return GestureDetector(
                      onTap: () => widget.onTapLayer?.call(idx),
                      child: Container(
                        width: widget.thumbnailPaneWidth - 12,
                        height: widget.thumbnailPaneWidth - 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active
                                ? Colors.blueAccent
                                : Colors.grey.shade200,
                            width: active ? 2 : 1,
                          ),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _img(
                            l.asset,
                            fit: BoxFit.cover,
                            w: widget.thumbnailPaneWidth - 12,
                            h: widget.thumbnailPaneWidth - 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _HalfSide { left, right }

class _HalfBoardClipper extends CustomClipper<Path> {
  final _HalfSide side;
  _HalfBoardClipper({required this.side});
  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    return Path()..addRect(
      side == _HalfSide.left
          ? Rect.fromLTWH(0, 0, w / 2, h)
          : Rect.fromLTWH(w / 2, 0, w / 2, h),
    );
  }

  @override
  bool shouldReclip(covariant _HalfBoardClipper oldClipper) =>
      oldClipper.side != side;
}
