
class Chapter {
  final String name;
  final String slug;
  final String chapterId;

  Chapter({
    required this.name,
    required this.slug,
    required this.chapterId,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      name: json['chapter_name'] ?? 'No Name',
      slug: json['chapter_slug'] ?? '',
      chapterId: json['chapter_api_data'].split('/').last ?? '',
    );
  }
}
