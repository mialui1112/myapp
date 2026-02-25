import 'package:flutter/material.dart';
import 'package:myapp/screens/manga_list_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manga Sources'),
      ),
      body: GridView.count(
        crossAxisCount: 2, // You can adjust this value
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: <Widget>[
          _buildSourceCard(
            context,
            'Otruyen',
            'https://otruyenapi.com/v1/api/home',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MangaListScreen()),
              );
            },
          ),
          // Add more sources here in the future
        ],
      ),
    );
  }

  Widget _buildSourceCard(BuildContext context, String name, String imageUrl, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.network(
              imageUrl,
              height: 80.0, // Adjust as needed
              errorBuilder: (context, error, stackTrace) {
                // Display a placeholder or icon if the image fails to load
                return const Icon(Icons.book, size: 80.0);
              },
            ),
            const SizedBox(height: 8.0),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
