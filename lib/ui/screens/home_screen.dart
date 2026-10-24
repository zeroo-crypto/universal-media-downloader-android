import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../core/constants/platforms.dart';
import '../../extractors/base_extractor.dart';
import '../../extractors/extractor_registry.dart';
import '../../services/download_service.dart';
import '../theme/zall_theme.dart';
import '../widgets/zall_illustrations.dart';
import '../widgets/media_preview_sheet.dart';
import 'gallery_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? initialUrl;

  const HomeScreen({super.key, this.initialUrl});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _urlController.text = widget.initialUrl!;
      _analyzeUrl(widget.initialUrl!);
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUrl != null &&
        widget.initialUrl!.isNotEmpty &&
        widget.initialUrl != oldWidget.initialUrl) {
      _urlController.text = widget.initialUrl!;
      _analyzeUrl(widget.initialUrl!);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      final text = data.text!.trim();
      _urlController.text = text;
      _showToast('Link berhasil ditempel dari clipboard');
      _analyzeUrl(text);
    } else {
      _showToast('Clipboard kosong');
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF232634),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _analyzeUrl(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      _showToast('Silakan masukkan link terlebih dahulu');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final metadata = await ExtractorRegistry.extractMedia(cleanUrl);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show Media Preview Bottom Sheet
      final downloadService = context.read<DownloadService>();
      MediaPreviewSheet.show(
        context: context,
        metadata: metadata,
        onDownloadSingle: (stream) {
          downloadService.enqueueDownload(metadata, stream);
          _showToast('Memulai unduhan: ${metadata.title}');
          _urlController.clear();
        },
        onDownloadAll: (streams) {
          downloadService.enqueueBatchDownload(metadata, streams);
          _showToast('Memulai unduh semua (${streams.length} media)');
          _urlController.clear();
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      _showToast('Gagal menganalisis link: $_errorMessage');
    }
  }

  void _onPlatformBadgeTap(String platformName, String sampleUrl) {
    _urlController.text = sampleUrl;
    _showToast('Contoh link $platformName dipilih');
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = context.watch<DownloadService>();
    final activeTask = downloadService.activeTask;
    final tasks = downloadService.tasks;

    return Scaffold(
      backgroundColor: ZallTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar: "ZALL" + Gallery & Settings Icons
              _buildTopAppBar(),
              const SizedBox(height: 18),

              // Hero Section: "Semua Bisa, Satu Aplikasi!" + 3D Blue Folder Illustration
              _buildHeroSection(),
              const SizedBox(height: 22),

              // Link Input Card
              _buildLinkInputCard(activeTask),
              const SizedBox(height: 24),

              // Error Display Banner (if any)
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade400.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 12.5),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.white70),
                        onPressed: () => setState(() => _errorMessage = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Baru Diunduh Section
              _buildRecentDownloadsSection(tasks, downloadService),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.between,
      children: [
        // "ZA" ExtraBold, "LL" Light
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'ZA',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              TextSpan(
                text: 'LL',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        // Action Icons: Grid 2x2 (Galeri) & Gear (Pengaturan)
        Row(
          children: [
            // Galeri Icon Button
            IconButton(
              icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 24),
              tooltip: 'Buka Galeri',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GalleryScreen()),
                );
              },
            ),
            const SizedBox(width: 4),
            // Pengaturan Icon Button
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
              tooltip: 'Buka Pengaturan',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(text: 'Semua Bisa,\nSatu '),
                    TextSpan(
                      text: 'Aplikasi!',
                      style: TextStyle(color: ZallTheme.primaryBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tak perlu repot ganti-ganti aplikasi. Cukup satu ketukan untuk mengunduh.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: ZallTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Right 3D Blue Folder Illustration
        const HeroFolderIllustration(size: 135),
      ],
    );
  }

  Widget _buildLinkInputCard(DownloadTask? activeTask) {
    return Container(
      decoration: BoxDecoration(
        color: ZallTheme.cardSurface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper Input Row
          Row(
            children: [
              // Circle Link Button (Paste)
              InkWell(
                onTap: _pasteFromClipboard,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: ZallTheme.circleSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.link, color: ZallTheme.primaryBlue, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Text Field with Clear (X)
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(fontSize: 13.5, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tempel link di sini...',
                    hintStyle: const TextStyle(color: Color(0xFF7D7E8A), fontSize: 13.5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: _urlController.text.isNotEmpty
                        ? InkWell(
                            onTap: () {
                              _urlController.clear();
                              setState(() => _errorMessage = null);
                            },
                            child: const Icon(Icons.close, size: 18, color: Colors.white54),
                          )
                        : null,
                  ),
                  onSubmitted: _analyzeUrl,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),

              // Download Action Circle Button
              InkWell(
                onTap: _isLoading ? null : () => _analyzeUrl(_urlController.text),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ZallTheme.actionBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ZallTheme.actionBlue.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),

          // Active Download Progress (if any task is currently downloading)
          if (activeTask != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ZallTheme.circleSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ZallTheme.primaryBlue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activeTask.metadata.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: ZallTheme.highlightBlue,
                          ),
                        ),
                      ),
                      Text(
                        '${(activeTask.progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: activeTask.status == DownloadStatus.processing
                          ? null
                          : activeTask.progress,
                      backgroundColor: const Color(0xFF262834),
                      valueColor: const AlwaysStoppedAnimation<Color>(ZallTheme.primaryBlue),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          // Divider Line
          Divider(color: ZallTheme.dividerColor.withOpacity(0.7), height: 1),
          const SizedBox(height: 12),

          // Supported Platforms Row (6 exact platforms)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Platform yang Didukung',
                style: TextStyle(
                  fontSize: 11.5,
                  color: ZallTheme.textSecondary,
                ),
              ),
              Row(
                children: [
                  // 1. YouTube
                  _buildPlatformBadge(
                    color: ZallTheme.youtubeRed,
                    child: const Icon(Icons.play_arrow, size: 13, color: Colors.white),
                    onTap: () => _onPlatformBadgeTap('YouTube', 'https://youtu.be/dQw4w9WgXcQ'),
                  ),
                  const SizedBox(width: 6),
                  // 2. Pixiv
                  _buildPlatformBadge(
                    color: ZallTheme.pixivBlue,
                    child: const Text(
                      'P',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () => _onPlatformBadgeTap('Pixiv', 'https://www.pixiv.net/en/artworks/118940215'),
                  ),
                  const SizedBox(width: 6),
                  // 3. Instagram
                  _buildPlatformBadge(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFDBA74), Color(0xFFE1306C), Color(0xFF833AB4)],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    child: const Icon(Icons.camera_alt_outlined, size: 12, color: Colors.white),
                    onTap: () => _onPlatformBadgeTap('Instagram', 'https://www.instagram.com/reel/C9xYz789/'),
                  ),
                  const SizedBox(width: 6),
                  // 4. Pinterest
                  _buildPlatformBadge(
                    color: ZallTheme.pinterestRed,
                    child: const Text(
                      'P',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () => _onPlatformBadgeTap('Pinterest', 'https://pin.it/7kLmN9pQr'),
                  ),
                  const SizedBox(width: 6),
                  // 5. TikTok
                  _buildPlatformBadge(
                    color: ZallTheme.tiktokBlack,
                    child: const Icon(Icons.music_note, size: 13, color: Colors.white),
                    onTap: () => _onPlatformBadgeTap('TikTok', 'https://vt.tiktok.com/ZSY9aBcDe/'),
                  ),
                  const SizedBox(width: 6),
                  // 6. X / Twitter
                  _buildPlatformBadge(
                    color: ZallTheme.twitterBlack,
                    child: const Text(
                      '𝕏',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () => _onPlatformBadgeTap('Twitter/X', 'https://x.com/techdaily/status/184920194821'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformBadge({
    Color? color,
    Gradient? gradient,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildRecentDownloadsSection(
      List<DownloadTask> tasks, DownloadService downloadService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Baru Diunduh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (tasks.isNotEmpty)
              Row(
                children: [
                  TextButton(
                    onPressed: () => downloadService.clearAllCompleted(),
                    child: const Text(
                      'Hapus Semua',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GalleryScreen()),
                      );
                    },
                    child: const Text(
                      'Lihat Galeri >',
                      style: TextStyle(
                        color: ZallTheme.primaryBlue,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Empty State vs Populated Tasks
        if (tasks.isEmpty)
          Row(
            children: [
              // 3D Blue Inbox Tray
              const EmptyInboxIllustration(size: 110),
              const SizedBox(width: 14),
              // Empty State Text
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Belum Ada Unduhan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tidak ada file yang ditemukan. Coba unduh dulu, ya!',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: ZallTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length > 5 ? 5 : tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildDownloadItemCard(task, downloadService);
            },
          ),
      ],
    );
  }

  Widget _buildDownloadItemCard(
      DownloadTask task, DownloadService downloadService) {
    final isDone = task.status == DownloadStatus.completed;
    final isDownloading = task.status == DownloadStatus.downloading;
    final isProcessing = task.status == DownloadStatus.processing;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ZallTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          // Thumbnail / Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 50,
              height: 50,
              color: const Color(0xFF14151B),
              child: task.metadata.thumbnailUrl != null
                  ? Image.network(
                      task.metadata.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.movie_outlined,
                        color: ZallTheme.highlightBlue,
                      ),
                    )
                  : const Icon(
                      Icons.movie_outlined,
                      color: ZallTheme.highlightBlue,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.metadata.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${task.metadata.platform.displayName} • ${task.selectedStream.qualityLabel}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ZallTheme.textSecondary,
                  ),
                ),
                if (isDownloading || isProcessing) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: isProcessing ? null : task.progress,
                      backgroundColor: const Color(0xFF262834),
                      valueColor: const AlwaysStoppedAnimation<Color>(ZallTheme.primaryBlue),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Actions
          if (isDone && task.savedFilePath != null) ...[
            IconButton(
              icon: const Icon(Icons.play_circle_fill, color: ZallTheme.primaryBlue, size: 28),
              tooltip: 'Buka File',
              onPressed: () => OpenFilex.open(task.savedFilePath!),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
              tooltip: 'Hapus',
              onPressed: () => downloadService.deleteDownloadedFile(task.id),
            ),
          ] else if (isDownloading || isProcessing) ...[
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
              tooltip: 'Batalkan',
              onPressed: () => downloadService.cancelTask(task.id),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
              tooltip: 'Hapus dari daftar',
              onPressed: () => downloadService.removeTask(task.id),
            ),
          ],
        ],
      ),
    );
  }
}
