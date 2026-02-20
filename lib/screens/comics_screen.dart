
import 'package:flutter/material.dart';
import 'package:myapp/screens/comics_source_detail_screen.dart';

class ComicsScreen extends StatefulWidget {
  const ComicsScreen({super.key});

  @override
  _ComicsScreenState createState() => _ComicsScreenState();
}

class _ComicsScreenState extends State<ComicsScreen> {
  final List<String> _allComicSources = [
    'Source A',
    'Source B',
    'Source C',
    'Source D',
    'Source E',
    'Source F',
    'Source G',
  ];

  List<String> _filteredComicSources = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredComicSources = _allComicSources;
    _searchController.addListener(() {
      filterSources();
    });
  }

  void filterSources() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredComicSources = _allComicSources
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
              labelText: 'Search Sources',
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
            itemCount: _filteredComicSources.length,
            itemBuilder: (context, index) {
              final source = _filteredComicSources[index];
              return SizedBox(
                width: 180, // Give a fixed width to each item
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: InkWell(
                     onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ComicsSourceDetailScreen(sourceName: source),
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
                ),
              );
            },
          ),
        ),
        const Divider(height: 20, thickness: 2), 
        const Expanded(
          child: Center(
            child: Text('Latest Updates (Coming Soon)'),
          )
        )
      ],
    );
  }
}
