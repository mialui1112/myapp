import 'package:flutter/material.dart';
import 'package:myapp/models/manga.dart';
import 'package:myapp/screens/manga_detail_screen.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:provider/provider.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: StreamBuilder<List<Manga>>(
        stream: firestoreService.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No favorites yet.'));
          }
          final favorites = snapshot.data!;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            padding: const EdgeInsets.all(10),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final manga = favorites[index];
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
    );
  }
}
