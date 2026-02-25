
import 'package:myapp/models/chapter.dart';

class MangaDetail {
  final String name;
  final String thumbUrl;
  final String description;
  final List<String> authors;
  final String status;
  final List<Chapter> chapters;

  MangaDetail({
    required this.name,
    required this.thumbUrl,
    required this.description,
    required this.authors,
    required this.status,
    required this.chapters,
  });

  factory MangaDetail.fromJson(Map<String, dynamic> json) {
    final item = json['data']?['item'] ?? {};

    // Construct the full thumbnail URL
    final String partialThumbUrl = item['thumb_url'] ?? '';
    final String fullThumbUrl = 'https://img.otruyen.com/uploads/comics/$partialThumbUrl';
    
    // Extract authors, which can be a list of strings
    final List<dynamic> authorList = item['author'] ?? [];
    final List<String> authors = authorList.map((author) => author.toString()).toList();

    // The chapters are nested within the first server's data.
    final List<dynamic> serverData = item['chapters']?[0]?['server_data'] ?? [];
    final List<Chapter> chapters = serverData.map((chapterJson) => Chapter.fromJson(chapterJson)).toList();

    return MangaDetail(
      name: item['name'] ?? 'No Name',
      thumbUrl: fullThumbUrl,
      // The description can contain HTML tags, we'll handle that on the UI side.
      description: item['content'] ?? 'No description available.',
      authors: authors,
      status: item['status'] ?? 'Unknown',
      chapters: chapters,
    );
  }
}
