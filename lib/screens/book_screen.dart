
import 'package:flutter/material.dart';
import 'package:myapp/screens/book_source_detail_screen.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  _BookScreenState createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final List<String> _allBookSources = [
    'Wattpad',
    'Goodreads',
    'Royal Road',
    'Scribble Hub',
    'Webnovel',
    'Tale Truyen',
    'TruyenFULL',
  ];

  List<String> _filteredBookSources = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredBookSources = _allBookSources;
    _searchController.addListener(() {
      filterSources();
    });
  }

  void filterSources() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBookSources = _allBookSources
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
              labelText: 'Search Book Sources',
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
                itemCount: _filteredBookSources.length,
                itemBuilder: (context, index) {
                  final source = _filteredBookSources[index];
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
                                BookSourceDetailScreen(sourceName: source),
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
