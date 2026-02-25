
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/chapter.dart';
import 'package:myapp/models/manga_detail.dart';
import 'package:myapp/services/otruyen_api_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/services/download_service.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:myapp/screens/reader_screen.dart';

class MangaDetailScreen extends StatefulWidget {
  final String endpoint;
  final Map<String, dynamic> manga;

  const MangaDetailScreen({super.key, required this.endpoint, required this.manga});

  @override
  MangaDetailScreenState createState() => MangaDetailScreenState();
}

class MangaDetailScreenState extends State<MangaDetailScreen> {
  late Future<MangaDetail?> _mangaDetailFuture;
  final OTruyenApiService _apiService = OTruyenApiService();

  @override
  void initState() {
    super.initState();
    _mangaDetailFuture = _apiService.getMangaDetail(widget.endpoint);
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final downloadService = Provider.of<DownloadService>(context, listen: false);

    return Scaffold(
      body: FutureBuilder<MangaDetail?>(
        future: _mangaDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(firestoreService, null),
              ],
            );
          } else {
            final mangaDetail = snapshot.data!;
            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(firestoreService, mangaDetail),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDescription(mangaDetail),
                        const SizedBox(height: 24),
                        _buildChapterList(firestoreService, downloadService, mangaDetail),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSliverAppBar(FirestoreService firestoreService, MangaDetail? manga) {
    final displayName = manga?.name ?? widget.manga['name'];
    final displayThumb = manga?.thumbUrl ?? widget.manga['thumb_url'];

    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      actions: [
        StreamBuilder<bool>(
          stream: firestoreService.isFavoriteStream(widget.endpoint),
          builder: (context, snapshot) {
            final isFavorite = snapshot.data ?? false;
            return IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.white,
                shadows: const [Shadow(blurRadius: 2.0)],
              ),
              onPressed: () {
                if (isFavorite) {
                  firestoreService.removeFavorite(widget.endpoint);
                } else {
                  firestoreService.addFavorite({
                    'name': displayName,
                    'thumb_url': displayThumb,
                    'endpoint': widget.endpoint,
                  });
                }
              },
              tooltip: 'Toggle Favorite',
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(displayName, style: const TextStyle(shadows: [Shadow(blurRadius: 10.0)])),
        background: displayThumb.isNotEmpty
            ? Image.network(
                displayThumb,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error)),
              )
            : Container(color: Colors.grey),
      ),
    );
  }

  Widget _buildDescription(MangaDetail manga) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Synopsis', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Html(data: manga.description, style: {"body": Style(fontSize: FontSize.medium)}),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 8.0,
          children: [
            _buildInfoChip('Status', manga.status),
            if (manga.authors.isNotEmpty) _buildInfoChip('Author', manga.authors.join(', ')),
          ],
        )
      ],
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }

  Widget _buildChapterList(FirestoreService firestoreService, DownloadService downloadService, MangaDetail manga) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chapters', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ValueListenableBuilder<Map<String, String>>(
          valueListenable: downloadService.downloadStatusNotifier,
          builder: (context, statuses, child) {
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: manga.chapters.length,
              itemBuilder: (context, index) {
                final chapter = manga.chapters[index];
                final status = statuses[chapter.chapterId] ?? 'none';

                return ListTile(
                  title: Text(chapter.name),
                  trailing: _buildDownloadIcon(downloadService, manga, chapter, status),
                  onTap: () {
                    firestoreService.addToHistory(
                      mangaData: widget.manga,
                      chapterId: chapter.chapterId,
                      chapterName: chapter.name,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReaderScreen(
                          chapterId: chapter.chapterId,
                          mangaName: manga.name,
                        ),
                      ),
                    );
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                );
              },
              separatorBuilder: (context, index) => const Divider(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDownloadIcon(DownloadService downloadService, MangaDetail manga, Chapter chapter, String status) {
    switch (status) {
      case 'downloading':
        return const SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        );
      case 'completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'failed':
        return IconButton(
          icon: const Icon(Icons.error, color: Colors.red),
          onPressed: () => _startDownload(downloadService, manga, chapter),
        );
      default: // 'none'
        return IconButton(
          icon: const Icon(Icons.download_outlined),
          onPressed: () => _startDownload(downloadService, manga, chapter),
        );
    }
  }

  void _startDownload(DownloadService downloadService, MangaDetail manga, Chapter chapter) {
    downloadService.startDownload(DownloadTask(
      mangaEndpoint: widget.endpoint,
      chapterId: chapter.chapterId,
      chapterName: chapter.name,
      mangaName: manga.name,
      thumbUrl: manga.thumbUrl,
    ));
  }
}
