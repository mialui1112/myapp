
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/screens/manga_detail_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getFavoritesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Your favorite manga will appear here.', 
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final favoriteDocs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 items per row
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.6, // Adjust for better item proportions
            ),
            itemCount: favoriteDocs.length,
            itemBuilder: (context, index) {
              final manga = favoriteDocs[index].data() as Map<String, dynamic>;
              final String name = manga['name'] ?? 'No Title';
              final String thumbUrl = manga['thumb_url'] ?? '';
              final String endpoint = manga['endpoint'] ?? '';

              return GestureDetector(
                onTap: () {
                   if (endpoint.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MangaDetailScreen(
                          endpoint: endpoint,
                           // Pass the full manga object to avoid re-fetching basic data
                          manga: {
                            'endpoint': endpoint,
                            'name': name,
                            'thumb_url': thumbUrl,
                          }
                        ),
                      ),
                    );
                  }
                },
                child: Card(
                  elevation: 4.0,
                  clipBehavior: Clip.antiAlias, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: thumbUrl.isNotEmpty
                            ? Image.network(
                                thumbUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error, color: Colors.red);
                                },
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported, size: 50),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: (100 * (index % 10)).ms).slideY(begin: 0.2, end: 0.0);
            },
          );
        },
      ),
    );
  }
}
