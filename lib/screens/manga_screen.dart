
import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:myapp/models/manga.dart';
import 'package:myapp/services/otruyen_api_service.dart';
import 'package:myapp/screens/manga_detail_screen.dart';

class MangaScreen extends StatefulWidget {
  const MangaScreen({super.key});

  @override
  _MangaScreenState createState() => _MangaScreenState();
}

class _MangaScreenState extends State<MangaScreen> {
  // Futures for both latest manga and search results
  Future<List<Manga>>? _mangaFuture;
  final OTruyenApiService _apiService = OTruyenApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Initially, load the latest manga
    _mangaFuture = _apiService.getLatestManga();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Debounce search so we don't call the API on every keystroke
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text;
      setState(() {
        if (query.isEmpty) {
          _isSearching = false;
          _mangaFuture = _apiService.getLatestManga(); // Reset to latest manga
        } else {
          _isSearching = true;
          _mangaFuture = _apiService.searchManga(query);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: FutureBuilder<List<Manga>>(
            future: _mangaFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(_isSearching ? 'No results found.' : 'No manga available.'),
                );
              } else {
                return _buildMangaGrid(snapshot.data!);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search Manga',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        ),
      ),
    );
  }

  Widget _buildMangaGrid(List<Manga> mangaList) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final int crossAxisCount = (screenWidth / 180).floor().clamp(2, 5);

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.6,
          ),
          itemCount: mangaList.length,
          itemBuilder: (context, index) {
            final manga = mangaList[index];
            return Card(
              elevation: 4.0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MangaDetailScreen(mangaSlug: manga.slug),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.network(
                        manga.thumbUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          return progress == null
                              ? child
                              : const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.error));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        manga.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        textAlign: TextAlign.center,
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
    );
  }
}
