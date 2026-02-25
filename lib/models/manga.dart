class Manga {
  final String name;
  final String thumbUrl;
  final String slug;
  final String endpoint;

  Manga({
    required this.name,
    required this.thumbUrl,
    required this.slug,
    required this.endpoint,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    final String partialThumbUrl = json['thumb_url'] ?? '';
    final String fullThumbUrl = 'https://img.otruyenapi.com/uploads/comics/$partialThumbUrl';

    return Manga(
      name: json['name'] ?? 'No Name',
      thumbUrl: fullThumbUrl,
      slug: json['slug'] ?? '',
      endpoint: json['slug'] ?? '',
    );
  }

  factory Manga.fromFirestore(Map<String, dynamic> data) {
    return Manga(
      name: data['name'] ?? 'No Name',
      thumbUrl: data['thumb_url'] ?? '',
      slug: data['endpoint'] ?? '',
      endpoint: data['endpoint'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'thumb_url': thumbUrl,
      'slug': slug,
      'endpoint': endpoint,
    };
  }
}
