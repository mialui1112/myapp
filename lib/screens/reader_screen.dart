import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:myapp/models/chapter_content.dart';
import 'package:myapp/services/otruyen_api_service.dart';

class ReaderScreen extends StatefulWidget {
  final String? chapterId;
  final String mangaName;
  final Map<String, dynamic>? downloadedChapterData;

  const ReaderScreen({
    super.key,
    this.chapterId,
    required this.mangaName,
    this.downloadedChapterData,
  }) : assert(chapterId != null || downloadedChapterData != null);

  @override
  ReaderScreenState createState() => ReaderScreenState();
}

class ReaderScreenState extends State<ReaderScreen> {
  late Future<ChapterContent> _chapterContentFuture;
  final OTruyenApiService _apiService = OTruyenApiService();

  bool get isOfflineMode => widget.downloadedChapterData != null;

  // State for UI controls
  bool _showUI = true;
  late PageController _pageController;
  late ValueNotifier<int> _currentPageNotifier;

  @override
  void initState() {
    super.initState();
    if (isOfflineMode) {
      _chapterContentFuture = _loadOfflineChapter();
    } else {
      _chapterContentFuture = _apiService.getChapterContent(widget.chapterId!);
    }
    _pageController = PageController();
    _currentPageNotifier = ValueNotifier<int>(1);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<ChapterContent> _loadOfflineChapter() async {
    final data = widget.downloadedChapterData!;
    final List<String> imagePaths = List<String>.from(
      jsonDecode(data['image_paths']),
    );
    return ChapterContent(
      mangaName: data["manga_name"],
      chapterName: data['chapter_name'],
      imageUrls: imagePaths,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
      SystemChrome.setEnabledSystemUIMode(
        _showUI ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<ChapterContent>(
        future: _chapterContentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorView(snapshot.error);
          } else if (!snapshot.hasData || snapshot.data!.imageUrls.isEmpty) {
            return const Center(
              child: Text(
                'No images found.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final chapter = snapshot.data!;
          return GestureDetector(
            onTap: _toggleUI,
            child: Stack(
              children: [
                _buildPhotoViewGallery(chapter.imageUrls),
                _buildTopUI(chapter.chapterName),
                _buildBottomUI(chapter.imageUrls.length),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoViewGallery(List<String> imageUrls) {
    return PhotoViewGallery.builder(
      pageController: _pageController,
      itemCount: imageUrls.length,
      scrollDirection: Axis.horizontal,
      scrollPhysics: const BouncingScrollPhysics(),
      builder: (context, index) {
        final imageProvider = isOfflineMode
            ? FileImage(File(imageUrls[index]))
            : NetworkImage(imageUrls[index]) as ImageProvider;
        return PhotoViewGalleryPageOptions(
          imageProvider: imageProvider,
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2.5,
          heroAttributes: PhotoViewHeroAttributes(tag: imageUrls[index]),
        );
      },
      onPageChanged: (index) => _currentPageNotifier.value = index + 1,
      loadingBuilder: (context, event) =>
          const Center(child: CircularProgressIndicator()),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );
  }

  Widget _buildTopUI(String chapterName) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _showUI
          ? Positioned(
              key: const ValueKey('topUI'),
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                title: Text(
                  widget.mangaName,
                  style: const TextStyle(
                    fontSize: 16,
                    shadows: [Shadow(blurRadius: 4)],
                  ),
                ),
                backgroundColor: Colors.black.withAlpha(153),
                elevation: 0,
              ),
            )
          : const SizedBox.shrink(key: ValueKey('emptyTop')),
    );
  }

  Widget _buildBottomUI(int totalPages) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
      child: _showUI
          ? Positioned(
              key: const ValueKey('bottomUI'),
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withAlpha(153),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 10,
                  top: 10,
                  left: 16,
                  right: 16,
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentPageNotifier,
                  builder: (context, currentPage, child) {
                    return Row(
                      children: [
                        Text(
                          '$currentPage / $totalPages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: currentPage.clamp(1, totalPages).toDouble(),
                            min: 1,
                            max: totalPages.toDouble(),
                            activeColor: Colors.deepPurpleAccent,
                            inactiveColor: Colors.white30,
                            onChanged: (value) =>
                                _pageController.jumpToPage(value.toInt() - 1),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('emptyBottom')),
    );
  }

  Widget _buildErrorView(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              isOfflineMode
                  ? 'Failed to load downloaded chapter. The files may be corrupted or deleted.'
                  : 'Failed to load chapter. Please check your connection and try again.',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          if (!isOfflineMode)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReaderScreen(
                        chapterId: widget.chapterId,
                        mangaName: widget.mangaName,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
