class OutfitPreset {
  final double dx;
  final double dy;
  final double scale;
  final double rotationDeg;
  final String clip;
  const OutfitPreset({
    this.dx = 0,
    this.dy = 0,
    this.scale = 1.0,
    this.rotationDeg = 0,
    this.clip = 'none',
  });
}

class OutfitLayoutPresets {
  static const Map<String, OutfitPreset> group = {
    'tops': OutfitPreset(dy: -0.15, scale: 0.50),
    'bottoms': OutfitPreset(dx: 0.04, dy: 0.15, scale: 0.50),

    'footwear': OutfitPreset(dx: 0.02, dy: 0.40, scale: 0.20),

    'outerwear': OutfitPreset(dx: 0.20, dy: 0.02, scale: 0.95),
    'dresses & rompers': OutfitPreset(dy: 0.04, scale: 0.95),
    'skirts': OutfitPreset(dy: 0.12, scale: 0.78),
    'bags': OutfitPreset(dy: 0.30, scale: 0.82),
    'headwear': OutfitPreset(dy: -0.40, scale: 0.7),
    'neckwear': OutfitPreset(dy: -0.17, scale: 0.78),
    'wristwear': OutfitPreset(dy: 0.22, scale: 0.72),
    'eyewear': OutfitPreset(dy: -0.35, scale: 0.65),
    'other accessories': OutfitPreset(dy: 0.14, scale: 0.85),
  };

  static OutfitPreset resolve(String groupName) {
    final g = group[groupName.toLowerCase()];
    return g ?? const OutfitPreset();
  }
}
