class Category {
  final String id;
  final String name;
  final String slug;

  Category({required this.id, required this.name, required this.slug});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      slug: json['slug'] ?? '',
    );
  }
}
