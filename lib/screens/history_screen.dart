
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/screens/manga_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getHistoryStream(),
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
                'Your reading history will appear here.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final historyDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: historyDocs.length,
            itemBuilder: (context, index) {
              final doc = historyDocs[index];
              final historyData = doc.data() as Map<String, dynamic>;

              final String name = historyData['name'] ?? 'No Title';
              final String thumbUrl = historyData['thumb_url'] ?? '';
              final String endpoint = historyData['endpoint'] ?? '';
              final String lastChapter = historyData['last_read_chapter_name'] ?? 'N/A';
              final Timestamp? lastReadTimestamp = historyData['last_read_at'];
              final DateTime lastReadTime = lastReadTimestamp?.toDate() ?? DateTime.now();

              return Card(
                 margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                 elevation: 3.0,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                 child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: thumbUrl.isNotEmpty
                        ? Image.network(
                            thumbUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 60, height: 60, color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, size: 30)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Continue reading: $lastChapter', maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Read ${timeago.format(lastReadTime)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  onTap: () {
                    if (endpoint.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MangaDetailScreen(mangaEndpoint: endpoint),
                        ),
                      );
                    }
                  },
                ),
              ).animate().fadeIn(duration: 500.ms, delay: (100 * (index % 10)).ms).slideY(begin: 0.2, end: 0.0);
            },
          );
        },
      ),
    );
  }
}
