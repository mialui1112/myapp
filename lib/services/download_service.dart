import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:myapp/services/otruyen_api_service.dart';
import 'package:myapp/models/chapter_content.dart';

// A simple data class to hold download task info
class DownloadTask {
  final String mangaEndpoint;
  final String chapterId;
  final String chapterName;
  final String mangaName;
  final String thumbUrl;

  DownloadTask({
    required this.mangaEndpoint,
    required this.chapterId,
    required this.chapterName,
    required this.mangaName,
    required this.thumbUrl,
  });
}

class DownloadService extends ChangeNotifier {
  static const _databaseName = "MangaDownloads.db";
  static const _databaseVersion = 1;

  static const table = 'downloads';

  static const columnId = 'id';
  static const columnMangaEndpoint = 'manga_endpoint';
  static const columnChapterId = 'chapter_id';
  static const columnChapterName = 'chapter_name';
  static const columnMangaName = 'manga_name';
  static const columnThumbUrl = 'thumb_url';
  static const columnImagePaths = 'image_paths';
  static const columnDownloadStatus = 'status';
  static const columnCreatedAt = 'created_at';

  DownloadService(){
    _loadInitialStatuses();
  }

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnMangaEndpoint TEXT NOT NULL,
            $columnChapterId TEXT NOT NULL UNIQUE,
            $columnChapterName TEXT NOT NULL,
            $columnMangaName TEXT NOT NULL,
            $columnThumbUrl TEXT NOT NULL,
            $columnImagePaths TEXT,
            $columnDownloadStatus TEXT NOT NULL,
            $columnCreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
          ''');
  }
  
  // Notifier for download statuses
  final ValueNotifier<Map<String, String>> downloadStatusNotifier = ValueNotifier({});

  void _loadInitialStatuses() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(table, columns: [columnChapterId, columnDownloadStatus]);
      final Map<String, String> statuses = { for (var item in maps) item[columnChapterId] : item[columnDownloadStatus] };
      downloadStatusNotifier.value = statuses;
  }


  // A queue to process downloads one by one
  final List<DownloadTask> _downloadQueue = [];
  bool _isProcessing = false;

  void startDownload(DownloadTask task) async {
    final currentStatuses = downloadStatusNotifier.value;
    if (currentStatuses[task.chapterId] == 'completed' || currentStatuses[task.chapterId] == 'downloading') {
        return;
    }

    _downloadQueue.add(task);
    if (!_isProcessing) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_downloadQueue.isEmpty) {
      _isProcessing = false;
      return;
    }

    _isProcessing = true;
    final task = _downloadQueue.removeAt(0);

    try {
      await _insertInitialRecord(task);

      final OTruyenApiService apiService = OTruyenApiService();
      final ChapterContent chapterContent = await apiService.getChapterContent(task.chapterId);

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String chapterDir = join(appDir.path, 'downloads', task.mangaEndpoint, task.chapterId);
      final Directory dir = Directory(chapterDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      List<String> localImagePaths = [];
      for (int i = 0; i < chapterContent.imageUrls.length; i++) {
        final imageUrl = chapterContent.imageUrls[i];
        final response = await http.get(Uri.parse(imageUrl));
        final String filePath = join(chapterDir, '${i.toString().padLeft(3, '0')}.jpg');
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        localImagePaths.add(filePath);
      }

      await _updateToCompleted(task.chapterId, localImagePaths);

    } catch (e) {
      await _updateToFailed(task.chapterId);
    } finally {
      _processQueue();
    }
  }

  void _updateNotifier(String chapterId, String status) {
    final currentStatuses = Map<String, String>.from(downloadStatusNotifier.value);
    currentStatuses[chapterId] = status;
    downloadStatusNotifier.value = currentStatuses;
    notifyListeners();
  }

  Future<int> _insertInitialRecord(DownloadTask task) async {
      final db = await database;
      final id = await db.insert(table, {
          columnMangaEndpoint: task.mangaEndpoint,
          columnChapterId: task.chapterId,
          columnChapterName: task.chapterName,
          columnMangaName: task.mangaName,
          columnThumbUrl: task.thumbUrl,
          columnDownloadStatus: 'downloading',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      _updateNotifier(task.chapterId, 'downloading');
      return id;
  }

  Future<int> _updateToCompleted(String chapterId, List<String> localImagePaths) async {
      final db = await database;
      final id = await db.update(table, {
          columnImagePaths: jsonEncode(localImagePaths),
          columnDownloadStatus: 'completed',
      }, where: '$columnChapterId = ?', whereArgs: [chapterId]);
       _updateNotifier(chapterId, 'completed');
      return id;
  }

  Future<int> _updateToFailed(String chapterId) async {
      final db = await database;
      final id = await db.update(table, {
          columnDownloadStatus: 'failed',
      }, where: '$columnChapterId = ?', whereArgs: [chapterId]);
      _updateNotifier(chapterId, 'failed');
      return id;
  }

  Future<Map<String, dynamic>?> getDownloadByChapterId(String chapterId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(table,
        where: '$columnChapterId = ?', whereArgs: [chapterId]);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Stream<List<Map<String, dynamic>>> getDownloadedChaptersStream() {
    return Stream.fromFuture(getDownloadedChapters());
  }
  
  Future<List<Map<String, dynamic>>> getDownloadedChapters() async {
    final db = await database;
    return await db.query(table, where: '$columnDownloadStatus = ?', whereArgs: ['completed'], orderBy: '$columnCreatedAt DESC');
  }

  Future<void> deleteDownload(String chapterId) async {
    final db = await database;
    final record = await getDownloadByChapterId(chapterId);
    if (record != null && record[columnImagePaths] != null) {
        final List<dynamic> paths = jsonDecode(record[columnImagePaths]);
        for (String path in paths) {
            final file = File(path);
            if (await file.exists()) {
                await file.delete();
            }
        }
        final Directory dir = File(paths.first).parent;
        if (await dir.exists()) {
          await dir.delete();
        } 
    }
    await db.delete(table, where: '$columnChapterId = ?', whereArgs: [chapterId]);
    final currentStatuses = Map<String, String>.from(downloadStatusNotifier.value);
    currentStatuses.remove(chapterId);
    downloadStatusNotifier.value = currentStatuses;
    notifyListeners();
  }
}
