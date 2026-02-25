import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/models/manga.dart';
import 'package:myapp/models/manga_detail.dart';
import 'package:myapp/models/chapter_content.dart';

class OTruyenApiService {
  static const String _baseUrl = 'https://otruyenapi.com/v1/api';
  static const String _cdnUrl = 'https://sv1.otruyencdn.com/v1/api';

  Future<List<Manga>> getMangaList({String endpoint = 'home'}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$endpoint'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> mangaListJson = data['data']?['items'] ?? [];
        return mangaListJson.map((json) => Manga.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load manga. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load manga: $e');
    }
  }

  Future<List<Manga>> getLatestManga() async {
    return getMangaList();
  }

  Future<MangaDetail> getMangaDetail(String slug) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/truyen-tranh/$slug'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MangaDetail.fromJson(data);
      } else {
        throw Exception('Failed to load manga details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load manga details: $e');
    }
  }

  Future<ChapterContent> getChapterContent(String chapterId) async {
    try {
      final response = await http.get(Uri.parse('$_cdnUrl/chapter/$chapterId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ChapterContent.fromJson(data);
      } else {
        throw Exception('Failed to load chapter content. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load chapter content: $e');
    }
  }

  // Searches for manga based on a keyword.
  Future<List<Manga>> searchManga(String keyword) async {
    if (keyword.isEmpty) {
      return [];
    }
    return getMangaList(endpoint: 'tim-kiem?keyword=$keyword');
  }
}
