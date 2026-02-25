import 'package:flutter/material.dart';
import 'package:myapp/models/manga_detail.dart';
import 'package:myapp/services/otruyen_api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:myapp/screens/reader_screen.dart';

class MangaDetailScreen extends StatefulWidget {
  final String mangaEndpoint;

  const MangaDetailScreen({super.key, required this.mangaEndpoint});

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> {
  late Future<MangaDetail> _mangaDetailFuture;
  final OTruyenApiService _apiService = OTruyenApiService();

  @override
  void initState() {
    super.initState();
    _mangaDetailFuture = _apiService.getMangaDetail(widget.mangaEndpoint);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MangaDetail>(
        future: _mangaDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (snapshot.hasError) {
            return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
          } else if (!snapshot.hasData) {
            return const Scaffold(body: Center(child: Text('No data found')));
          } else {
            final manga = snapshot.data!;
            return Scaffold(
              body: _buildMangaDetailView(manga),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  if (manga.chapters.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReaderScreen(
                          chapterId: manga.chapters.first.chapterId,
                          mangaName: manga.name,
                          chapterList: manga.chapters.map((c) => {'id': c.chapterId, 'name': c.name}).toList(),
                        ),
                      ),
                    );
                  }
                },
                label: const Text('Continue Reading'),
                icon: const Icon(Icons.play_arrow),
              ),
            );
          }
        },
      );
  }

  Widget _buildMangaDetailView(MangaDetail manga) {
    return CustomScrollView(
      slivers: <Widget>[
        _buildSliverAppBar(manga),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(manga),
                const SizedBox(height: 16),
                _buildActionButtons(),
                const SizedBox(height: 24),
                _buildDescription(manga),
                const SizedBox(height: 16),
                _buildCategoryTags(manga),
                const SizedBox(height: 24),
                _buildChapterList(manga),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(MangaDetail manga) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: CachedNetworkImage(
          imageUrl: manga.thumbUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.download_outlined), onPressed: () {}),
        IconButton(icon: const Icon(Icons.sort), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }

  Widget _buildHeader(MangaDetail manga) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CachedNetworkImage(
          imageUrl: manga.thumbUrl,
          width: 100,
          height: 150,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Container(color: Colors.grey[200]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manga.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Authors: ${manga.authors.join(', ')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.circle, color: Colors.green, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    manga.status.replaceFirst(manga.status[0], manga.status[0].toUpperCase()),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(icon: Icons.favorite_border, label: 'In Library'),
        _buildActionButton(icon: Icons.bookmark_border, label: 'Follow'),
        _buildActionButton(icon: Icons.open_in_new, label: 'WebView'),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label}) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildDescription(MangaDetail manga) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Html(data: manga.description, style: {
          "body": Style(maxLines: 4, textOverflow: TextOverflow.ellipsis),
        }),
        InkWell(
          onTap: () {
            // Show full description in a dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Description'),
                content: SingleChildScrollView(child: Html(data: manga.description)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                ],
              ),
            );
          },
          child: const Text(
            'Show more',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTags(MangaDetail manga) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: manga.categories.map((category) {
        return Chip(
          label: Text(category.name),
          backgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey[400]!),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChapterList(MangaDetail manga) {
    final chapters = manga.chapters;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${chapters.length} Chapters',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            final date = DateFormat.yMd().format(DateTime.now().subtract(Duration(days: chapters.length - index)));

            return ListTile(
              title: Text('Chapter ${chapter.name}'),
              subtitle: Text(date),
              trailing: const Icon(Icons.download_outlined),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReaderScreen(
                      chapterId: chapter.chapterId,
                      mangaName: manga.name,
                      chapterList: manga.chapters.map((c) => {'id': c.chapterId, 'name': c.name}).toList(),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
