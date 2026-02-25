import 'package:flutter/material.dart';
import 'package:myapp/screens/reader_screen.dart';
import 'package:myapp/services/download_service.dart';
import 'package:provider/provider.dart';

class DownloadsTab extends StatelessWidget {
  const DownloadsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadService = Provider.of<DownloadService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: downloadService.getDownloadedChaptersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No downloaded chapters yet.'));
          }
          final downloadedChapters = snapshot.data!;
          return ListView.builder(
            itemCount: downloadedChapters.length,
            itemBuilder: (context, index) {
              final chapterData = downloadedChapters[index];
              final mangaName = chapterData['mangaName'] ?? 'Unknown Manga';
              final chapterName = chapterData['chapter_name'] ?? 'Unknown Chapter';
              final chapterId = chapterData['chapter_id'];

              return ListTile(
                title: Text(mangaName),
                subtitle: Text(chapterName),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    // Show a confirmation dialog before deleting
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Chapter'),
                        content: Text('Are you sure you want to delete "$chapterName"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await downloadService.deleteDownload(chapterId);
                    }
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReaderScreen(
                        downloadedChapterData: chapterData,
                        mangaName: mangaName, // Add this line
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
