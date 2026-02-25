
class Manga {
  final String name;
  final String thumbUrl;
  final String slug;

  Manga({
    required this.name,
    required this.thumbUrl,
    required this.slug,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    // The API returns a partial URL for the thumbnail.
    // We need to prepend the base URL to display the image.
    final String partialThumbUrl = json['thumb_url'] ?? '';
    final String fullThumbUrl = 'https://img.otruyen.com/uploads/comics/$partialThumbUrl';

    return Manga(
      name: json['name'] ?? 'No Name',
      thumbUrl: fullThumbUrl,
      slug: json['slug'] ?? '',
    );
  }
}
