
class ClothingItem {
  final int id;
  final int? userId;
  final String imageUrl;
  final String categoryGroup;
  final String? category;
  final String? description;
  final Map<String, dynamic> extras;

  ClothingItem({
    required this.id,
    this.userId,
    required this.imageUrl,
    required this.categoryGroup,
    this.category,
    this.description,
    this.extras = const {},
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    final extras = Map<String, dynamic>.from(json);
    extras.remove('id');
    extras.remove('user_id');
    extras.remove('image_url');
    extras.remove('category_group');
    extras.remove('category');
    extras.remove('description');

    return ClothingItem(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] as int : (int.tryParse('${json['user_id']}') ?? null),
      imageUrl: (json['image_url'] ?? '') as String,
      categoryGroup: (json['category_group'] ?? '').toString(),
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      extras: extras,
    );
  }
}