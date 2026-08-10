// lib/modules/add_item/controllers/add_item2_controller.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/clothing_service.dart';
import '../../../core/services/clothing_repository.dart';
import '../../../core/routes/app_pages.dart';

class AddItem2Controller extends GetxController {
  // runtime state
  final imagePath = ''.obs;
  final isAnalyzing = true.obs;
  final isSaving = false.obs;
  final isNotFashionImage = false.obs;

  final aiImage = Rxn<Uint8List>();
  final RxMap<String, dynamic> features = <String, dynamic>{}.obs; // exposed to view

  final ClothingRepository _repo = Get.find<ClothingRepository>();

  // --- COLOR GROUPS (per your request: only these groups allowed) ---
  final List<String> COLOR_GROUPS = ['neutrals', 'pastels', 'brights', 'darks', 'metallics'];

  // --- CATEGORY LIST BY GROUP (copied from your data) ---
  final Map<String, List<String>> CATEGORY_LIST_BY_GROUP = {
    "Tops": [
      "T-shirt", "Polo shirt", "Jersey", "Button-down shirt", "Henley shirt",
      "Tank top", "Knit sweater", "Blouse", "Tunic", "Crop top",
      "Sleeveless top", "Pullover hoodie", "Turtleneck",
      "Dashiki tunic", "Ao dai tunic", "Huipil blouse", "Kente cloth top"
    ],
    "Outerwear": [
      "Denim jacket", "Leather jacket", "Puffer jacket", "Trench coat",
      "Peacoat", "Blazer", "Windbreaker jacket", "Cardigan sweater",
      "Vest", "Raincoat", "Parka", "Zippered hoodie", "Tracksuit jacket",
      "Coat", "Jacket", "Leather bomber jacket", "Leather coat", "Faux Fur Coat",
      "Kimono robe", "Sherwani coat"
    ],
    "Bottoms": [
      "Straight-leg jeans", "Skinny jeans", "Bootcut jeans", "Cargo pants",
      "Chino pants", "Dress pants", "Shorts", "Capri pants", "Leggings",
      "Joggers", "Denim shorts", "Sweatpants", "Trousers",
      "Lederhosen pants"
    ],
    "Skirts": [
      "A-line skirt", "Pencil skirt", "Maxi skirt", "Mini skirt",
      "Pleated skirt", "Wrap skirt", "Denim skirt",
      "Kilt skirt", "Sarong wrap"
    ],
    "Dresses & Rompers": [
      "Strap dress", "Wrap dress", "T-shirt dress", "Maxi dress",
      "Midi dress", "Mini dress", "Cocktail dress", "Evening gown",
      "Sundress", "Shirt dress", "Sweater dress", "Overalls",
      "Jumpsuit", "Romper", "Denim dress",
      "Sari garment", "Hanbok dress", "Dirndl dress", "Cheongsam dress",
      "Boubou robe", "Caftan robe", "Abaya robe"
    ],
    "Footwear": [
      "Sneakers", "Oxford dress shoes", "Ankle boots", "Knee-high boots",
      "Heel pumps", "Sandals", "Rain boots", "Loafers", "Ballet flats",
      "Wedges", "Espadrilles", "Slippers", "Suede dress shoes", "Dress shoe", "Flip-flops"
    ],
    "Headwear": [
      "Baseball cap", "Beanie hat", "Bucket hat", "Sun hat", "Headband",
      "Headscarf", "Hijab head covering", "Beret", "Fedora", "Fez hat",
      "Turban", "Sombrero"
    ],
    "Bags": [
      "Handbag", "Backpack", "Tote bag", "Clutch bag", "Shoulder bag",
      "Crossbody bag", "Wallet"
    ],
    "Neckwear": [
      "Neck tie", "Bow tie", "Scarf", "Shawl", "Bandana", "Necklace"
    ],
    "Earwear": [
      "Earrings", "Over-ear headphones", "Earbuds"
    ],
    "Wristwear": [
      "Wrist watch", "Bracelet"
    ],
    "Handwear": [
      "Gloves", "Mittens"
    ],
    "Eyewear": [
      "Sunglasses", "Eyeglasses"
    ],
    "Socks & Hosiery": [
      "Knee-high socks", "Ankle socks", "Crew socks", "No-show socks",
      "Dress socks", "Stockings", "Tights"
    ],
    "Other Accessories": [
      "Belt", "Ring", "Brooch", "Pocket square", "Umbrella"
    ],
    "Underwear & Swimwear": [
      "Bra", "Panty", "One-piece swimsuit", "Boxers"
    ]
  };

  // --- PATTERN & MATERIAL descriptors (copied) ---
  final Map<String, String> PATTERN_DESCRIPTIONS = {
    "solid": "A single, uniform color with no pattern or print.",
    "striped": "A pattern of parallel lines or bands of different colors.",
    "checked": "A pattern of intersecting horizontal and vertical lines forming squares, like a checkerboard. Also known as checker.",
    "plaid": "A pattern of intersecting horizontal and vertical bands in multiple colors. Tartan is a specific type of plaid.",
    "floral": "A pattern of floral print featuring flowers, leaves, and other botanical elements.",
    "polka dots": "A pattern consisting of filled circles of the same size.",
    "geometric": "A pattern made of geometric shapes like triangles, circles, squares, or lines.",
    "paisley": "A distinctive intricate pattern of curved, feather-shaped figures based on a pine-cone design from India.",
    "animal print": "A pattern that imitates the skin or fur of an animal, such as leopard, zebra, or snake.",
    "tie-dye": "A pattern created by tying sections of fabric before dyeing to create irregular, colorful designs.",
    "camouflage": "A pattern of mottled colors, typically greens and browns, used to blend in with the surroundings.",
    "ombre": "A pattern with a gradual blending of one color hue to another, usually moving tints and shades.",
    "color-block": "A pattern using two or more large, solid blocks of color on a single garment.",
    "jacquard": "An intricate, textured pattern that is woven directly into the fabric, rather than printed on top.",
    "houndstooth": "A two-tone pattern of broken checks or abstract four-pointed shapes.",
    "batik": "A pattern created using a wax-resist dyeing technique, resulting in intricate, fluid designs.",
    "graphic": "A printed or embroidered design featuring logo, brand names, slogans, text in various fonts (cursive, block, capital letters), words or phrases, numbers, icons, illustrations, or artwork, covering part or the entire garment.",
    "textured": "A surface with raised, three-dimensional details such as ruffles, embellishments, or fabric manipulation, creating a tactile feel rather than a printed or woven pattern.",
  };

  final Map<String, String> CLIP_PATTERN_DESCRIPTIONS = {
    "solid": "A single, unbroken color with no design, no print, or no visible pattern. The fabric appears uniform throughout.",
    "striped": "Repeating straight lines running across the fabric.",
    "checked": "Squares made by crossing lines, like a checkerboard.",
    "plaid": "Overlapping lines of different colors forming a grid.",
    "floral": "Repeating images of flowers, leaves, or a plant-based design.",
    "geometric": "A design made of abstract or regular shapes like triangles, circles, or polygons.",
    "lace": "A patterned fabric made with a series of connected threads, often with floral or intricate designs.",
    "textured": "A raised or 3D surface you can feel, created by knitting, weaving, or quilting.",
    "polka dots": "Evenly spaced, same-size circles on the fabric.",
    "paisley": "Curved, teardrop-shaped figures, often detailed.",
    "animal print": "Spots or stripes that look like animal skin or fur.",
    "tie-dye": "Swirled or blotchy areas of different colors.",
    "camouflage": "camouflage, irregular shapes in earth tones, for blending in.",
    "ombre": "Color that fades smoothly from light to dark or between colors.",
    "color-block": "Large, solid blocks of different colors.",
    "jacquard": "Raised, woven-in patterns with texture, not printed.",
    "houndstooth": "Jagged, duotone textile,  abstract shapes that look like dog’s teeth.",
    "batik": "Blurry, flowing designs with a hand-dyed look.",
    "graphic": "graphic artwork , logos, or text on the fabric.",
    "cable knit": "Textured knit fabric with raised, twisted cable ."
  };

  // A helpful list of common materials (used by ATTRIBUTES)
  final Map<String, String> CLIP_MATERIAL_DESCRIPTIONS = {
    "cotton": "Cotton - breathable natural fiber",
    "polyester": "Polyester - synthetic fiber, durable",
    "silk": "Silk - smooth, luxurious",
    "wool": "Wool - warm natural fiber",
    "denim": "Denim - sturdy cotton twill",
    "leather": "Leather - natural leather material",
    "suede": "Suede - soft leather finish",
    "canvas": "Canvas - heavy-duty woven fabric",
    "nylon": "Nylon - synthetic, water resistant",
    "satin": "Satin - glossy surface fabric",
    "lace": "Lace - decorative openwork fabric",
  };

  // --- ATTRIBUTES per category (converted to Dart; uses the pattern/material keys above) ---
  late final Map<String, Map<String, List<String>>> ATTRIBUTES;

  AddItem2Controller() {
    // Build attribute lists referencing pattern/material keys
    final patternKeys = CLIP_PATTERN_DESCRIPTIONS.keys.toList();
    final materialKeys = CLIP_MATERIAL_DESCRIPTIONS.keys.toList();

    ATTRIBUTES = {
      "Tops": {
        "sleeve": [
          "sleeveless",
          "short",
          "long",
        ],
        "neckline": [
          "crew",
          "v-neck",
          "scoop",
          "boat",
          "collared",
          "turtleneck",
        ],
        "fit": ["slim", "regular", "relaxed", "oversized"],
        "length": ["crop", "standard", "tunic"],
        "closure": ["pullover", "zipper", "button", "tie"],
        "pattern": patternKeys,
        "material": materialKeys,
      },
      "Outerwear": {
        "sleeve": ["sleeveless", "short", "long"],
        "style": ["blazer", "bomber", "parka", "trench", "puffer", "windbreaker"],
        "closure": ["button", "zipper", "belt", "snap", "toggle"],
        "length": ["hip", "thigh", "knee", "calf"],
        "insulation": ["unlined", "light", "medium", "heavy"],
        "pattern": patternKeys,
        "material": materialKeys,
      },
      "Bottoms": {
        "fit": ["skinny", "slim", "regular", "relaxed", "baggy"],
        "style": ["jeans", "chinos", "slacks", "cargos", "leggings"],
        "closure": ["button", "zipper", "drawstring", "elastic"],
        "length": ["short", "capri", "ankle", "full"],
        "pattern": patternKeys,
        "material": materialKeys,
      },
      "Skirts": {
        "fit": ["fitted", "regular", "flowy"],
        "length": ["mini", "knee", "midi", "maxi"],
        "closure": ["pullover", "zipper", "button", "tie"],
        "pattern": patternKeys,
        "material": materialKeys,
      },
      "Dresses & Rompers": {
        "sleeve": ["sleeveless", "short", "long"],
        "type": ["shift", "bodycon", "a-line", "wrap", "shirt"],
        "length": ["mini", "knee-length", "midi", "maxi"],
        "closure": ["pullover", "zipper", "button", "tie"],
        "pattern": patternKeys,
        "material": materialKeys,
      },
      "Footwear": {
        "style": ["sneakers", "boots", "sandals", "loafers", "pumps", "flats"],
        "closure": ["lace-up", "slip-on", "buckle", "zipper", "hook-loop"],
        "height": ["low-top", "mid-top", "high-top"],
        "toe": ["round toe", "pointed toe", "square toe", "open toe"],
        "pattern": patternKeys,
        "material": ["leather", "suede", "canvas", "knit", "polyester", "plastic", "blend", "faux leather"],
      },
      "Headwear": {
        "pattern": patternKeys,
        "material": ["cotton", "wool", "knit", "denim", "leather", "polyester", "blend", "silk", "plastic"],
      },
      "Bags": {
        "closure": ["zipper", "snap", "magnetic", "drawstring", "buckle"],
        "pattern": patternKeys,
        "material": ["leather", "canvas", "denim", "polyester", "faux leather", "silk", "plastic"],
      },
      "Neckwear": {
        "closure": ["none", "tie", "clasp"],
        "pattern": patternKeys,
        "material": ["silk", "wool", "knit", "cotton", "linen", "blend", "gold", "silver", "plastic"],
      },
      "Earwear": {
        "closure": ["none", "piercing"],
        "pattern": patternKeys,
        "material": ["gold", "silver", "plastic", "blend"],
      },
      "Wristwear": {
        "closure": ["clasp", "buckle", "none"],
        "pattern": patternKeys,
        "material": ["gold", "silver", "leather", "plastic", "knit", "blend"],
      },
      "Handwear": {
        "closure": ["none", "strap", "button", "zipper"],
        "pattern": patternKeys,
        "material": ["wool", "knit", "leather", "faux leather", "polyester", "spandex", "blend"],
      },
      "Eyewear": {
        "closure": ["none"],
        "pattern": patternKeys,
        "material": ["plastic", "gold", "silver"],
      },
      "Socks & Hosiery": {
        "closure": ["none"],
        "pattern": patternKeys,
        "material": ["cotton", "polyester", "spandex", "knit", "blend", "wool"],
      },
      "Other Accessories": {
        "closure": ["buckle", "clasp", "none"],
        "pattern": patternKeys,
        "material": ["leather", "denim", "gold", "silver", "plastic", "silk", "wool", "cotton", "blend"],
      },
      "Underwear & Swimwear": {
        "type": ["top", "bottom", "fullwear"],
        "fit": ["supportive", "padded", "unlined", "brief", "thong"],
        "coverage": ["full coverage", "medium coverage", "minimal coverage"],
        "closure": ["hook-and-eye", "clasp", "tie", "pull-on"],
        "pattern": patternKeys,
        "material": ["lace", "satin", "cotton", "nylon", "spandex", "mesh", "blend"],
        "color_group": COLOR_GROUPS,
      },
    };
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['path'] is String) {
      imagePath.value = args['path'] as String;
    }
    _analyze();
  }

  Future<void> _analyze() async {
    isAnalyzing.value = true;
    isNotFashionImage.value = false;
    features.clear();
    aiImage.value = null;
    try {
      if (imagePath.value.isEmpty) {
        throw Exception('No image path provided');
      }

      final json = await ClothingService.analyzeImage(File(imagePath.value));

      final dynamic data = json['data'];

      // server special-case: data returns ["this is not fashion"]
      if (data is List && data.isNotEmpty && data[0] == 'this is not fashion') {
        isNotFashionImage.value = true;
        return;
      }

      // read base64 -> bytes
      String base64String = (json['imageData'] ?? '') as String;
      if (base64String.startsWith('data:')) {
        final comma = base64String.indexOf(',');
        if (comma != -1) base64String = base64String.substring(comma + 1);
      }
      final bytes = base64Decode(base64String);
      aiImage.value = bytes;

      // map features into our editable structure
      if (data is Map) {
        data.forEach((k, v) {
          if (v is List) {
            features[k] = v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
          } else {
            features[k] = v?.toString() ?? '';
          }
        });

        // try normalize category_group to our keys
        final cg = (features['category_group'] ?? '').toString();
        if (cg.isNotEmpty) {
          final canonical = _normalizeCategoryGroupName(cg);
          if (canonical != null) features['category_group'] = canonical;
        }

        // ensure category exists for the group
        final group = (features['category_group'] ?? '').toString();
        if (group.isNotEmpty) {
          final list = CATEGORY_LIST_BY_GROUP[group];
          final cat = (features['category'] ?? '').toString();
          if ((cat.isEmpty || (list != null && !list.contains(cat))) && list != null && list.isNotEmpty) {
            features['category'] = list.first;
          }
        }
      } else {
        // fallback: if analyzer returns non-map data, put it into 'description'
        features['description'] = data?.toString() ?? '';
      }
    } catch (e, st) {
      debugPrint('Analyze error: $e\n$st');
      Get.snackbar('Error', 'Analysis failed. Try again.');
      features.clear();
      aiImage.value = null;
    } finally {
      isAnalyzing.value = false;
    }
  }

  String? _normalizeCategoryGroupName(String raw) {
    if (raw.isEmpty) return null;
    final norm = raw.trim().toLowerCase();
    for (final k in ATTRIBUTES.keys) {
      if (k.toLowerCase() == norm) return k;
      if (k.toLowerCase().contains(norm) || norm.contains(k.toLowerCase())) return k;
    }
    return null;
  }

  /// When user selects a new category group, update features and prefill valid category
  void changeCategoryGroup(String newGroup) {
    final canonical = _normalizeCategoryGroupName(newGroup) ?? newGroup;
    features['category_group'] = canonical;

    final options = CATEGORY_LIST_BY_GROUP[canonical];
    if (options != null && options.isNotEmpty) {
      final cur = (features['category'] ?? '').toString();
      if (cur.isEmpty || !options.contains(cur)) {
        features['category'] = options.first;
      }
    }
    features.refresh();
  }

  /// Generic setter
  void setString(String key, String value) {
    features[key] = value;
    features.refresh();
  }

  /// Save to backend using repository (same as earlier)
  Future<void> saveImage() async {
    if (aiImage.value == null) {
      Get.snackbar('Error', 'No image to save');
      return;
    }

    final cg = (features['category_group'] ?? '').toString().trim();
    final cat = (features['category'] ?? '').toString().trim();
    final color = (features['color_group'] ?? '').toString().trim();

    if (cg.isEmpty || cat.isEmpty || color.isEmpty) {
      Get.snackbar('Error', 'Please set Category group, Category and Color group.');
      return;
    }

    isSaving.value = true;
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final Map<String, dynamic> payload = {};
      features.forEach((k, v) {
        // convert lists to comma-joined strings for server (or keep as lists if you prefer)
        if (v is List) {
          payload[k] = v.map((e) => e.toString()).toList();
        } else {
          payload[k] = v;
        }
      });

      final filename = 'ai_${DateTime.now().millisecondsSinceEpoch}.png';
      final resp = await _repo.uploadFromBytes(
        imageBytes: aiImage.value!,
        features: payload,
        filename: filename,
      );

      Get.back(); // close dialog
      Get.snackbar('Saved', resp['message']?.toString() ?? 'Saved', snackPosition: SnackPosition.BOTTOM);
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(Routes.MAIN);
    } catch (e, st) {
      debugPrint('Save error: $e\n$st');
      Get.back();
      Get.snackbar('Error', 'Save failed. Try again.');
    } finally {
      isSaving.value = false;
    }
  }

  void retryUpload() {
    isNotFashionImage.value = false;
    features.clear();
    aiImage.value = null;
    _analyze();
  }
}
