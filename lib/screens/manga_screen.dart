
import 'package:flutter/material.dart';

class MangaScreen extends StatefulWidget {
  const MangaScreen({super.key});

  @override
  _MangaScreenState createState() => _MangaScreenState();
}

class _MangaScreenState extends State<MangaScreen> {
    final List<String> _allMangaSources = [
    'Manga Source 1',
    'Manga Source 2',
    'Manga Source 3',
    'Manga Source 4',
    'Manga Source 5',
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
        SizedBox(
          height: 120, // Give a fixed height to the horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filteredMangaSources.length,
            itemBuilder: (context, index) {
              final source = _filteredMangaSources[index];
              return SizedBox(
                width: 180, // Give a fixed width to each item
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: InkWell(
                     onTap: () {
                      // TODO: Navigate to Manga source detail screen
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
                ),
              );
            },
          ),
        ),
        const Divider(height: 20, thickness: 2), 
        const Expanded(
          child: Center(
            child: Text('Latest Manga Updates (Coming Soon)'),
          )
        )
      ],
    );
  }
}
