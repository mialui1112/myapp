
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/download_service.dart';
import 'package:myapp/screens/reader_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    final downloadService = Provider.of<DownloadService>(context);

    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: downloadService.getDownloadedChaptersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Your downloaded manga will appear here.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final downloadedChapters = snapshot.data!;
          // Group chapters by manga
          final Map<String, List<Map<String, dynamic>>> groupedByManga = {};
          for (var chapter in downloadedChapters) {
            final mangaEndpoint = chapter[DownloadService.columnMangaEndpoint];
            if (groupedByManga.containsKey(mangaEndpoint)) {
              groupedByManga[mangaEndpoint]!.add(chapter);
            } else {
              groupedByManga[mangaEndpoint] = [chapter];
            }
          }

          return ListView( // Use a ListView for the manga groups
            padding: const EdgeInsets.all(8.0),
            children: groupedByManga.entries.map((entry) {
              final mangaData = entry.value.first; // Use first chapter's data for manga info
              final chapters = entry.value;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      mangaData[DownloadService.columnThumbUrl],
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                    ),
                  ),
                  title: Text(
                    mangaData[DownloadService.columnMangaName],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${chapters.length} downloaded chapter(s)'),
                  children: chapters.map((chapter) {
                    return ListTile(
                      title: Text(chapter[DownloadService.columnChapterName]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () {
                          _showDeleteConfirmation(context, downloadService, chapter);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReaderScreen(downloadedChapterData: chapter),
                          ),
                        );
                      },
                    ).animate().fadeIn(delay: 100.ms).slideX();
                  }).toList(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, DownloadService service, Map<String, dynamic> chapter) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete "${chapter[DownloadService.columnChapterName]}"? This will remove all downloaded images for this chapter.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(), // Close the dialog
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                service.deleteDownload(chapter[DownloadService.columnChapterId]);
                Navigator.of(dialogContext).pop(); // Close the dialog
                // The stream will automatically rebuild the UI
                setState(() {}); // Force rebuild to reflect the change immediately
              },
            ),
          ],
        );
      },
    );
  }
}
