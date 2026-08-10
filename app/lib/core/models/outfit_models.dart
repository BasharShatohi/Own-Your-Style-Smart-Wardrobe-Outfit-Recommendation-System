// lib/core/models/outfit_models.dart
import '../services/api_service.dart';

class ItemLayer {
  final String asset; // image URL or asset path
  final String category;
  final String group;
  final String layer; // 'generated', 'outer', etc
  final bool clipLeftHalf;
  final bool clipRightHalf;
  final bool visible;

  final int? itemId;

  // Raw transform values exactly as backend stored them (x,y,scale,rotation)
  final double rawX;
  final double rawY;
  final double rawScale;
  final double rawRotation;

  ItemLayer({
    required this.asset,
    required this.category,
    required this.group,
    this.layer = 'generated',
    this.clipLeftHalf = false,
    this.clipRightHalf = false,
    this.visible = true,
    this.itemId,
    this.rawX = 0.0,
    this.rawY = 0.0,
    this.rawScale = 1.0,
    this.rawRotation = 0.0,
  });

  factory ItemLayer.fromApiMap(Map<String, dynamic> m) {
    final imageUrl = (m['image_url'] ?? m['image'] ?? '').toString();

    double toDouble(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    int? id;
    if (m['id'] is int) id = m['id'] as int;
    else if (m['id'] is String) id = int.tryParse(m['id'].toString());

    final normalized = ApiService.normalizeUrl(imageUrl);

    // If backend provided a relative file path (e.g. "clothing_images/1/xxx.webp")
    // the file path may 404 on remote. Many backends expose images through an
    // API controller route: /api/clothing-images/{id}. If we have the item id,
    // prefer that route so images are fetched reliably.
    String assetUrl;
    if (normalized.isEmpty && id != null) {
      assetUrl = ApiService.imageUrlForItemId(id);
    } else if ((normalized.contains('clothing_images') || normalized.contains('clothing-images')) && id != null) {
      // backend returned a path to a file, but the server may not serve raw files.
      // prefer the image-by-id API endpoint which often returns the image bytes.
      assetUrl = ApiService.imageUrlForItemId(id);
    } else {
      assetUrl = normalized.isNotEmpty ? normalized : 'assets/images/home_looks.png';
    }

    final categoryGroup = (m['category_group'] ?? '').toString();
    final category = (m['category'] ?? '').toString();

    return ItemLayer(
      asset: assetUrl,
      category: category.isNotEmpty ? category : (categoryGroup.isNotEmpty ? categoryGroup : 'Other'),
      group: categoryGroup.isNotEmpty ? categoryGroup.toLowerCase() : (category.isNotEmpty ? category.toLowerCase() : 'other accessories'),
      layer: (m['layer'] ?? 'generated').toString(),
      clipLeftHalf: false,
      clipRightHalf: false,
      visible: true,
      itemId: id,
      rawX: toDouble(m['x'], 0.0),
      rawY: toDouble(m['y'], 0.0),
      rawScale: toDouble(m['scale'], 1.0),
      rawRotation: toDouble(m['rotation'], 0.0),
    );
  }
}

class OutfitItem {
  final int? id;
  final String imageUrl;
  final String categoryGroup;
  final String category;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final String? layer;

  OutfitItem({
    this.id,
    required this.imageUrl,
    required this.categoryGroup,
    required this.category,
    this.x = 0.0,
    this.y = 0.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.layer,
  });

  factory OutfitItem.fromMap(Map<String, dynamic> m) {
    double toDouble(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    int? id;
    if (m['id'] is int) id = m['id'] as int;
    else if (m['id'] is String) id = int.tryParse(m['id'].toString());

    final rawImage = (m['image_url'] ?? m['image'] ?? '').toString();
    final normalized = ApiService.normalizeUrl(rawImage);

    String imageUrlFinal;
    if (normalized.isEmpty && id != null) {
      imageUrlFinal = ApiService.imageUrlForItemId(id);
    } else if ((normalized.contains('clothing_images') || normalized.contains('clothing-images')) && id != null) {
      imageUrlFinal = ApiService.imageUrlForItemId(id);
    } else {
      imageUrlFinal = normalized.isNotEmpty ? normalized : '';
    }

    final categoryGroup = (m['category_group'] ?? '').toString();
    final category = (m['category'] ?? '').toString();

    return OutfitItem(
      id: id,
      imageUrl: imageUrlFinal,
      categoryGroup: categoryGroup,
      category: category,
      x: toDouble(m['x'], 0.0),
      y: toDouble(m['y'], 0.0),
      scale: toDouble(m['scale'], 1.0),
      rotation: toDouble(m['rotation'], 0.0),
      layer: m['layer']?.toString(),
    );
  }
}

class Outfit {
  final String id;
  final List<ItemLayer> layers; // what OutfitBoard consumes
  final List<OutfitItem> items; // raw backend items

  final String weather;
  final double temperature;
  final int? age;
  final String interaction;
  final String occasion;
  final String gender;

  Outfit({
    required this.id,
    required this.layers,
    this.items = const [],
    this.weather = 'clear',
    this.temperature = 15.0,
    this.age,
    this.interaction = 'none',
    this.occasion = '',
    this.gender = 'male',
  });

  factory Outfit.fromApiMap(Map<String, dynamic> m) {
    final rawItems = (m['items'] as List?) ?? [];
    final items = rawItems.whereType<Map>().map((e) => OutfitItem.fromMap(Map<String, dynamic>.from(e))).toList();
    final layers = rawItems.whereType<Map>().map((e) => ItemLayer.fromApiMap(Map<String, dynamic>.from(e))).toList();

    final idValue = m['id']?.toString() ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    final weather = (m['weather'] ?? 'clear').toString();
    final temperature = (m['temperature'] is num) ? (m['temperature'] as num).toDouble() : double.tryParse((m['temperature'] ?? '').toString()) ?? 15.0;
    final age = (m['age'] is int) ? m['age'] as int : (m['age'] is String ? int.tryParse(m['age']) : null);
    final interaction = (m['interaction'] ?? 'none').toString();
    final occasion = (m['occasion'] ?? '').toString();
    final gender = (m['gender'] ?? 'male').toString();

    return Outfit(
      id: idValue,
      layers: layers,
      items: items,
      weather: weather,
      temperature: temperature,
      age: age,
      interaction: interaction,
      occasion: occasion,
      gender: gender,
    );
  }
}
