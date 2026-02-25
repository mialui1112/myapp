
import 'package:flutter/material.dart';
import 'package:myapp/models/manga.dart';
import 'package:myapp/services/otruyen_api_service.dart';
import 'package:myapp/screens/manga_detail_screen.dart';

class MangaSourceDetailScreen extends StatefulWidget {
  final String sourceName;

  const MangaSourceDetailScreen({super.key, required this.sourceName});

  @override
  MangaSourceDetailScreenState createState() =>
      MangaSourceDetailScreenState();
}

class MangaSourceDetailScreenState extends State<MangaSourceDetailScreen> {
  late Future<List<Manga>> _mangaListFuture;
  final OTruyenApiService _apiService = OTruyenApiService();

  @override
  void initState() {
    super.initState();
    _mangaListFuture = _apiService.getLatestManga();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sourceName),
      ),
      body: FutureBuilder<List<Manga>>(
        future: _mangaListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No manga found.'),
            );
          } else {
            final mangas = snapshot.data!;
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
              ),
              itemCount: mangas.length,
              itemBuilder: (context, index) {
                final manga = mangas[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MangaDetailScreen(
                          endpoint: manga.endpoint,
                          manga: manga.toJson(),
                        ),
                      ),
                    );
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.network(
                            manga.thumbUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            manga.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
