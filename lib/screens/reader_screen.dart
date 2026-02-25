import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myapp/models/chapter_content.dart';
import 'package:myapp/services/otruyen_api_service.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Enums for settings
enum ReadingMode { vertical, pagedLtr, pagedRtl }
enum BackgroundColor { white, grey, black }

class ReaderScreen extends StatefulWidget {
  final String? chapterId;
  final String mangaName;
  final List<Map<String, String>>? chapterList; // Pass the full chapter list for navigation
  final Map<String, dynamic>? downloadedChapterData;

  const ReaderScreen({
    super.key,
    this.chapterId,
    required this.mangaName,
    this.chapterList,
    this.downloadedChapterData,
  }) : assert(chapterId != null || downloadedChapterData != null);

  @override
  ReaderScreenState createState() => ReaderScreenState();
}

class ReaderScreenState extends State<ReaderScreen> {
  late Future<ChapterContent> _chapterContentFuture;
  final OTruyenApiService _apiService = OTruyenApiService();

  bool get isOfflineMode => widget.downloadedChapterData != null;

  // UI state
  bool _showUI = false;
  int _currentPage = 1;
  int _totalPages = 0;

  // Settings state
  ReadingMode _readingMode = ReadingMode.vertical;
  BackgroundColor _backgroundColor = BackgroundColor.white;
  bool _isFullScreen = true;
  bool _keepScreenOn = true;

  // Controllers
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    if (isOfflineMode) {
      _chapterContentFuture = _loadOfflineChapter();
    } else {
      _chapterContentFuture = _apiService.getChapterContent(widget.chapterId!);
    }
    
    _pageController = PageController(initialPage: 0);
    _itemPositionsListener.itemPositions.addListener(_updateCurrentPageForVertical);
    _applyInitialSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readingMode = ReadingMode.values[prefs.getInt('readingMode') ?? 0];
      _backgroundColor = BackgroundColor.values[prefs.getInt('backgroundColor') ?? 0];
      _keepScreenOn = prefs.getBool('keepScreenOn') ?? true;
      _isFullScreen = prefs.getBool('isFullScreen') ?? true;
    });
    _applyInitialSettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('readingMode', _readingMode.index);
    await prefs.setInt('backgroundColor', _backgroundColor.index);
    await prefs.setBool('keepScreenOn', _keepScreenOn);
    await prefs.setBool('isFullScreen', _isFullScreen);
  }


  void _applyInitialSettings() {
    if(_isFullScreen) SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (_keepScreenOn) WakelockPlus.enable();
  }

  void _updateCurrentPageForVertical() {
     if (_readingMode == ReadingMode.vertical) {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final firstVisible = positions.reduce((a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b);
        if (mounted && _currentPage != firstVisible.index + 1) {
          setState(() => _currentPage = firstVisible.index + 1);
        }
      }
    }
  }
  
  void _onPageChangedForPaged(int index) {
    if (mounted && _currentPage != index + 1) {
       setState(() => _currentPage = index + 1);
    }
  }

  Future<ChapterContent> _loadOfflineChapter() async {
    final data = widget.downloadedChapterData!;
    final List<String> imagePaths = List<String>.from(jsonDecode(data['image_paths']));
    return ChapterContent(
      mangaName: data["manga_name"],
      chapterName: data['chapter_name'],
      imageUrls: imagePaths,
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
      if (!_showUI && _isFullScreen) {
         SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    });
  }
  
  Color _getBackgroundColor() {
    switch (_backgroundColor) {
      case BackgroundColor.white: return Colors.white;
      case BackgroundColor.grey: return Colors.grey.shade300;
      case BackgroundColor.black: return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: FutureBuilder<ChapterContent>(
        future: _chapterContentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorView(snapshot.error);
          } else if (!snapshot.hasData || snapshot.data!.imageUrls.isEmpty) {
            return Center(child: Text('No images found.', style: TextStyle(color: _backgroundColor == BackgroundColor.black ? Colors.white : Colors.black)));
          }

          final chapter = snapshot.data!;
          if(_totalPages == 0) _totalPages = chapter.imageUrls.length;
          
          return GestureDetector(
            onTap: _toggleUI,
            child: Stack(
              children: [
                _buildReaderView(chapter.imageUrls),
                if (_showUI) _buildTopUI(chapter.chapterName, chapter.mangaName),
                if (_showUI) _buildBottomUI(chapter.imageUrls.length),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildReaderView(List<String> imageUrls) {
    switch (_readingMode) {
      case ReadingMode.vertical:
        return ScrollablePositionedList.builder(
          itemCount: imageUrls.length,
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          itemBuilder: (context, index) => _buildImage(imageUrls[index]),
        );
      case ReadingMode.pagedLtr:
      case ReadingMode.pagedRtl:
        return PhotoViewGallery.builder(
          pageController: _pageController,
          itemCount: imageUrls.length,
          reverse: _readingMode == ReadingMode.pagedRtl,
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: _getImageProvider(imageUrls[index]),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
            );
          },
          onPageChanged: _onPageChangedForPaged,
          loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
          backgroundDecoration: BoxDecoration(color: _getBackgroundColor()),
        );
    }
  }

  ImageProvider _getImageProvider(String imageUrl) {
      return isOfflineMode ? FileImage(File(imageUrl)) as ImageProvider : CachedNetworkImageProvider(imageUrl);
  }

  Widget _buildImage(String imageUrl) {
    if (isOfflineMode) {
      return Image.file(
        File(imageUrl),
        errorBuilder: (context, error, stackTrace) =>
            Container(height: 400, color: Colors.grey[200], child: const Icon(Icons.error, color: Colors.red)),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) => Image(image: imageProvider),
      placeholder: (context, url) => Container(height: 400, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
      errorWidget: (context, url, error) => Container(height: 400, color: Colors.grey[200], child: const Icon(Icons.error, color: Colors.red)),
      memCacheHeight: 1200,
    );
  }
  
  void _navigateToChapter(bool isNext) {
    if (widget.chapterList == null || widget.chapterId == null) return;

    final currentIndex = widget.chapterList!.indexWhere((c) => c['id'] == widget.chapterId);
    if (currentIndex == -1) return;

    final targetIndex = isNext ? currentIndex - 1 : currentIndex + 1; // List is often newest first

    if (targetIndex >= 0 && targetIndex < widget.chapterList!.length) {
      final targetChapterId = widget.chapterList![targetIndex]['id']!;
       Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReaderScreen(
              chapterId: targetChapterId,
              mangaName: widget.mangaName,
              chapterList: widget.chapterList,
            ),
          ),
        );
    }
  }

  Widget _buildTopUI(String chapterName, String mangaName) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Material(
        color: Colors.black.withAlpha(179),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mangaName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text(chapterName, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.bookmark_border, color: Colors.white), onPressed: () {}),
                IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () => _showSettingsModal(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomUI(int totalPages) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Material(
        color: Colors.black.withAlpha(179),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: () => _navigateToChapter(false)),
                    Expanded(
                      child: Column(
                        children: [
                          Slider(
                            value: _currentPage.toDouble().clamp(1, totalPages.toDouble()),
                            min: 1,
                            max: totalPages.toDouble(),
                            activeColor: Colors.deepPurpleAccent,
                            inactiveColor: Colors.white30,
                            onChanged: (value) {
                              if (_readingMode == ReadingMode.vertical) {
                                _itemScrollController.jumpTo(index: value.toInt() - 1);
                              } else {
                                _pageController.jumpToPage(value.toInt() - 1);
                              }
                            },
                          ),
                          Text('$_currentPage / $totalPages', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ),
                    IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: () => _navigateToChapter(true)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () => _showSettingsModal(context)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        const TabBar(labelColor: Colors.black, tabs: [Tab(text: 'Kiểu đọc'), Tab(text: 'Chung'), Tab(text: 'Bộ lọc')]),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildReadingStyleSettings(setModalState, scrollController),
                              _buildGeneralSettings(setModalState, scrollController),
                              _buildFilterSettings(setModalState, scrollController),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(_saveSettings);
  }

  Widget _buildReadingStyleSettings(StateSetter setModalState, ScrollController controller) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text("Kiểu đọc"),
        _buildChoiceChip<ReadingMode>("Cuộn dọc", ReadingMode.vertical, _readingMode, setModalState, Icons.swap_vert),
        _buildChoiceChip<ReadingMode>("Trang (P -> T)", ReadingMode.pagedRtl, _readingMode, setModalState, Icons.book_outlined),
        _buildChoiceChip<ReadingMode>("Trang (T -> P)", ReadingMode.pagedLtr, _readingMode, setModalState, Icons.book),
      ],
    );
  }
  
  Widget _buildGeneralSettings(StateSetter setModalState, ScrollController controller) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text("Màu nền"),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: BackgroundColor.values.map((color) => _buildColorChoice(color, setModalState)).toList(),
        ),
        const Divider(height: 32),
        _buildSwitch(setModalState, "Toàn màn hình", _isFullScreen, (val) => _isFullScreen = val, Icons.fullscreen),
        _buildSwitch(setModalState, "Giữ màn hình bật", _keepScreenOn, (val) => _keepScreenOn = val, Icons.lightbulb_outline),
      ],
    );
  }

  Widget _buildFilterSettings(StateSetter setModalState, ScrollController controller) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(16.0),
      children: [
         _buildSwitch(setModalState, "Độ sáng tùy chỉnh", false, (val){}, Icons.brightness_6),
         _buildSwitch(setModalState, "Đảo màu", false, (val){}, Icons.invert_colors),
      ],
    );
  }

  Widget _buildChoiceChip<T>(String label, T value, T groupValue, StateSetter setModalState, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ChoiceChip(
        avatar: Icon(icon, color: groupValue == value ? Colors.white : Colors.black),
        label: Text(label), 
        selected: groupValue == value,
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(color: groupValue == value ? Colors.white : Colors.black),
        onSelected: (selected) {
          if (selected) {
            setModalState(() {
              if (T == ReadingMode) _readingMode = value as ReadingMode;
            });
            setState(() {}); 
          }
        },
      ),
    );
  }

   Widget _buildColorChoice(BackgroundColor color, StateSetter setModalState) {
    return InkWell(
      onTap: () {
        setModalState(() => _backgroundColor = color);
        setState(() {});
      },
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: color == BackgroundColor.white ? Colors.white : (color == BackgroundColor.grey ? Colors.grey.shade300 : Colors.black),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: _backgroundColor == color ? [BoxShadow(color: Theme.of(context).primaryColor, blurRadius: 3, spreadRadius: 2)] : [],
        ),
        child: _backgroundColor == color ? const Icon(Icons.check, color: Colors.green) : null,
      ),
    );
   }

  Widget _buildSwitch(StateSetter setModalState, String title, bool value, Function(bool) onChanged, IconData icon) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      value: value,
      onChanged: (newValue) {
        setModalState(() => onChanged(newValue));
        setState(() {});
        // Special handling for some settings
        if (title == "Giữ màn hình bật") {
          newValue ? WakelockPlus.enable() : WakelockPlus.disable();
        }
        if (title == "Toàn màn hình") {
          newValue ? SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky) : SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
      },
    );
  }

  Widget _buildErrorView(Object? error) {
    Color textColor = _backgroundColor == BackgroundColor.black ? Colors.white70 : Colors.black87;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          Padding(padding: const EdgeInsets.all(16.0), child: Text(isOfflineMode ? 'Failed to load downloaded chapter.' : 'Failed to load chapter.', style: TextStyle(color: textColor), textAlign: TextAlign.center)),
          if (!isOfflineMode)
            ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Retry'), onPressed: () => setState(() => _chapterContentFuture = _apiService.getChapterContent(widget.chapterId!))),
        ],
      ),
    );
  }
}
