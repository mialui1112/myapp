import 'package:flutter/material.dart';
import 'package:myapp/models/manga.dart';
import 'package:myapp/screens/manga_detail_screen.dart';
import 'package:myapp/services/otruyen_api_service.dart';
import 'package:provider/provider.dart';

class MangaListScreen extends StatefulWidget {
  const MangaListScreen({super.key});

  @override
  State<MangaListScreen> createState() => _MangaListScreenState();
}

class _MangaListScreenState extends State<MangaListScreen> {
  late Future<List<Manga>> _mangaListFuture;
  final _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _mangaListFuture = _fetchManga();
  }

  Future<List<Manga>> _fetchManga() {
    final apiService = Provider.of<OTruyenApiService>(context, listen: false);
    if (_searchTerm.isEmpty) {
      return apiService.getLatestManga();
    } else {
      return apiService.searchManga(_searchTerm);
    }
  }

  void _onSearchChanged(String term) {
    setState(() {
      _searchTerm = term;
      _mangaListFuture = _fetchManga();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Otruyen'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search manga...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Manga>>(
              future: _mangaListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No manga found.'));
                }
                final mangaList = snapshot.data!;
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  padding: const EdgeInsets.all(10),
                  itemCount: mangaList.length,
                  itemBuilder: (context, index) {
                    final manga = mangaList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MangaDetailScreen(mangaEndpoint: manga.endpoint),
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
                                width: double.infinity,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                manga.name,
                                style: Theme.of(context).textTheme.bodyMedium,
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
