
import 'package:myapp/models/chapter.dart';
import 'package:myapp/models/category.dart';

class MangaDetail {
  final String name;
  final String thumbUrl;
  final String description;
  final List<String> authors;
  final String status;
  final List<Chapter> chapters;
  final List<Category> categories;

  MangaDetail({
    required this.name,
    required this.thumbUrl,
    required this.description,
    required this.authors,
    required this.status,
    required this.chapters,
    required this.categories,
  });

  factory MangaDetail.fromJson(Map<String, dynamic> json) {
    final item = json['data']?['item'] ?? {};

    // Construct the full thumbnail URL
    final String partialThumbUrl = item['thumb_url'] ?? '';
    final String fullThumbUrl = 'https://img.otruyenapi.com/uploads/comics/$partialThumbUrl';
    
    // Extract authors, which can be a list of strings
    final List<dynamic> authorList = item['author'] ?? [];
    final List<String> authors = authorList.map((author) => author.toString()).toList();

    // The chapters are nested within the first server's data.
    final List<dynamic> serverData = item['chapters']?[0]?['server_data'] ?? [];
    final List<Chapter> chapters = serverData.map((chapterJson) => Chapter.fromJson(chapterJson)).toList();

    final List<dynamic> categoryList = item['category'] ?? [];
    final List<Category> categories = categoryList.map((categoryJson) => Category.fromJson(categoryJson)).toList();

    return MangaDetail(
      name: item['name'] ?? 'No Name',
      thumbUrl: fullThumbUrl,
      // The description can contain HTML tags, we'll handle that on the UI side.
      description: item['content'] ?? 'No description available.',
      authors: authors,
      status: item['status'] ?? 'Unknown',
      chapters: chapters,
      categories: categories,
    );
  }
}
