import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../core/constants/platforms.dart';
import '../../extractors/base_extractor.dart';
import '../../extractors/extractor_registry.dart';
import '../../services/download_service.dart';
import '../../services/language_service.dart';
import '../theme/zall_theme.dart';
import '../widgets/official_brand_icons.dart';
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
      _showToast(context.tr('toast_paste_ok'));
      _analyzeUrl(text);
    } else {
      _showToast(context.tr('toast_clipboard_empty'));
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
      _showToast(context.tr('toast_link_empty'));
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
          _showToast('${context.tr('toast_starting_download')}${metadata.title}');
          _urlController.clear();
        },
        onDownloadAll: (streams) {
          downloadService.enqueueBatchDownload(metadata, streams);
          _showToast('${context.tr('toast_starting_batch')} (${streams.length})');
          _urlController.clear();
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      _showToast('${context.tr('toast_analysis_failed')}$_errorMessage');
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

              // Hero Section
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              tooltip: 'Galeri',
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
              tooltip: 'Pengaturan',
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
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(text: context.tr('hero_title_1')),
                    TextSpan(
                      text: context.tr('hero_title_2'),
                      style: const TextStyle(color: ZallTheme.primaryBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('hero_subtitle'),
                style: const TextStyle(
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
                    hintText: context.tr('input_hint'),
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

          // Supported Platforms Row (6 exact official vector badges)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('supported_platforms'), // Platform yang Didukung
                style: const TextStyle(
                  fontSize: 11.5,
                  color: ZallTheme.textSecondary,
                ),
              ),
              Row(
                children: [
                  // 1. YouTube
                  _buildBrandBadge(
                    platform: 'YouTube',
                    sampleUrl: 'https://youtu.be/dQw4w9WgXcQ',
                  ),
                  const SizedBox(width: 6),
                  // 2. Pixiv
                  _buildBrandBadge(
                    platform: 'Pixiv',
                    sampleUrl: 'https://www.pixiv.net/en/artworks/118940215',
                  ),
                  const SizedBox(width: 6),
                  // 3. Instagram
                  _buildBrandBadge(
                    platform: 'Instagram',
                    sampleUrl: 'https://www.instagram.com/reel/C9xYz789/',
                  ),
                  const SizedBox(width: 6),
                  // 4. Pinterest
                  _buildBrandBadge(
                    platform: 'Pinterest',
                    sampleUrl: 'https://pin.it/7kLmN9pQr',
                  ),
                  const SizedBox(width: 6),
                  // 5. TikTok
                  _buildBrandBadge(
                    platform: 'TikTok',
                    sampleUrl: 'https://vt.tiktok.com/ZSY9aBcDe/',
                  ),
                  const SizedBox(width: 6),
                  // 6. X / Twitter
                  _buildBrandBadge(
                    platform: 'Twitter/X',
                    sampleUrl: 'https://x.com/techdaily/status/184920194821',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandBadge({
    required String platform,
    required String sampleUrl,
  }) {
    return InkWell(
      onTap: () => _onPlatformBadgeTap(platform, sampleUrl),
      borderRadius: BorderRadius.circular(14),
      child: OfficialBrandIcon(platform: platform, size: 28),
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
            Text(
              context.tr('recent_downloads'),
              style: const TextStyle(
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
                    child: Text(
                      context.tr('clear_all'),
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GalleryScreen()),
                      );
                    },
                    child: Text(
                      context.tr('view_gallery'),
                      style: const TextStyle(
                        color: ZallTheme.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (tasks.isEmpty)
          // Empty State
          Row(
            children: [
              const EmptyInboxIllustration(size: 85),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('no_downloads'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('no_downloads_desc'),
                      style: const TextStyle(
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
