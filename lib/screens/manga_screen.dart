
import 'package:flutter/material.dart';
import 'package:myapp/screens/manga_source_detail_screen.dart';

class MangaScreen extends StatefulWidget {
  const MangaScreen({super.key});

  @override
  MangaScreenState createState() => MangaScreenState();
}

class MangaScreenState extends State<MangaScreen> {
  final List<String> _allMangaSources = [
    'OTruyen',
    'NetTruyen',
    'MangaDex',
    'Tachiyomi',
    'Comi-K',
    'SayHentai',
    'HentaiVN',
  ];

  List<String> _filteredMangaSources = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredMangaSources = _allMangaSources;
    _searchController.addListener(() {
      filterSources();
    });
  }

  void filterSources() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMangaSources = _allMangaSources
          .where((source) => source.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Manga Sources',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double screenWidth = constraints.maxWidth;
              final int crossAxisCount = (screenWidth / 180).floor().clamp(2, 5);

              return GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 3 / 2,
                ),
                itemCount: _filteredMangaSources.length,
                itemBuilder: (context, index) {
                  final source = _filteredMangaSources[index];
                  return Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MangaSourceDetailScreen(sourceName: source),
                          ),
                        );
                      },
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            source,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
