
class ChapterContent {
  final String mangaName;
  final String chapterName;
  final List<String> imageUrls;

  ChapterContent({
    required this.mangaName,
    required this.chapterName,
    required this.imageUrls,
  });

  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    final item = json['data']?['item'] ?? {};
    final domain = json['data']?['domain_cdn'] ?? 'https://sv1.otruyencdn.com';

    final chapterPath = item['chapter_path'] ?? '';
    final List<dynamic> images = item['chapter_image'] ?? [];
    
    // Construct the full image URLs
    final List<String> imageUrls = images.map((image) {
      final filename = image['image_file'] ?? '';
      return '$domain/$chapterPath/$filename';
    }).toList();

    return ChapterContent(
      mangaName: item['comic_name'] ?? 'Unknown Manga',
      chapterName: item['chapter_name'] ?? 'Unknown Chapter',
      imageUrls: imageUrls,
    );
  }
}
