
import 'package:flutter/material.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  MoviesScreenState createState() => MoviesScreenState();
}

class MoviesScreenState extends State<MoviesScreen> {
  String _selectedFilter = 'Newest';

  @override
  Widget build(BuildContext context) {
    final List<String> movies = [
      'Movie 1',
      'Movie 2',
      'Movie 3',
      'Movie 4',
      'Movie 5',
      'Movie 6',
      'Movie 7',
      'Movie 8',
    ];

    return Column(
        children: [
          Wrap(
            spacing: 8.0,
            children: <Widget>[
              FilterChip(
                label: const Text('Newest'),
                selected: _selectedFilter == 'Newest',
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedFilter = 'Newest';
                    }
                  });
                },
              ),
              FilterChip(
                label: const Text('Most Liked'),
                selected: _selectedFilter == 'Most Liked',
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedFilter = 'Most Liked';
                    }
                  });
                },
              ),
              FilterChip(
                label: const Text('Popular'),
                selected: _selectedFilter == 'Popular',
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedFilter = 'Popular';
                    }
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
              ),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {
                      // Navigate to movie detail screen
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.network(
                            'https://picsum.photos/200/300?random=$index',
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(movies[index]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
  }
}
