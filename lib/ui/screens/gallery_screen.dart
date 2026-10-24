import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../core/constants/platforms.dart';
import '../../services/download_service.dart';
import '../theme/zall_theme.dart';
import '../widgets/zall_illustrations.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  String _selectedFilter = 'all';

  List<DownloadTask> _filterTasks(List<DownloadTask> tasks) {
    if (_selectedFilter == 'all') return tasks;

    return tasks.where((t) {
      switch (_selectedFilter) {
        case 'youtube':
          return t.metadata.platform == MediaPlatform.youtube;
        case 'pixiv':
          return t.metadata.platform == MediaPlatform.pixiv;
        case 'instagram':
          return t.metadata.platform == MediaPlatform.instagram;
        case 'pinterest':
          return t.metadata.platform == MediaPlatform.pinterest;
        case 'tiktok':
          return t.metadata.platform == MediaPlatform.tiktok;
        case 'twitter':
          return t.metadata.platform == MediaPlatform.twitter;
        default:
          return true;
      }
    }).toList();
  }

  void _showDeleteDialog(BuildContext context, DownloadService service, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1D26),
        title: const Text('Hapus Unduhan?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'File ini akan dihapus dari penyimpanan perangkat Anda.',
          style: TextStyle(color: ZallTheme.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Hapus'),
            onPressed: () {
              Navigator.pop(ctx);
              service.deleteDownloadedFile(taskId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = context.watch<DownloadService>();
    final allTasks = downloadService.tasks;
    final filteredTasks = _filterTasks(allTasks);

    return Scaffold(
      backgroundColor: ZallTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Back Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (allTasks.isNotEmpty)
                    TextButton(
                      onPressed: () => downloadService.clearAllCompleted(),
                      child: const Text(
                        'Bersihkan Galeri',
                        style: TextStyle(color: Color(0xFFEF4444), fontSize: 12.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Title: "Galeri"
              const Text(
                'Galeri',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Platform Filter Chips (Visible when tasks exist)
              if (allTasks.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Semua'),
                      _buildFilterChip('youtube', 'YouTube'),
                      _buildFilterChip('pixiv', 'Pixiv'),
                      _buildFilterChip('instagram', 'Instagram'),
                      _buildFilterChip('pinterest', 'Pinterest'),
                      _buildFilterChip('tiktok', 'TikTok'),
                      _buildFilterChip('twitter', 'X / Twitter'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Main Content: Empty State vs Media List
              Expanded(
                child: filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: filteredTasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return _buildGalleryItemCard(task, downloadService);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : ZallTheme.textMuted,
          ),
        ),
        selected: isSelected,
        selectedColor: ZallTheme.actionBlue,
        backgroundColor: ZallTheme.cardSurface,
        side: BorderSide(
          color: isSelected ? ZallTheme.primaryBlue : Colors.white.withOpacity(0.04),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (val) {
          if (val) {
            setState(() => _selectedFilter = key);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EmptyInboxIllustration(size: 155),
          const SizedBox(height: 20),
          const Text(
            'Belum Ada Unduhan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tidak ada file yang ditemukan. Coba unduh dulu, ya!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: ZallTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryItemCard(DownloadTask task, DownloadService service) {
    final isDone = task.status == DownloadStatus.completed;
    final exists = task.savedFilePath != null && File(task.savedFilePath!).existsSync();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZallTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Media Thumbnail / Platform Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 65,
              height: 65,
              color: const Color(0xFF14151B),
              child: task.metadata.thumbnailUrl != null
                  ? Image.network(
                      task.metadata.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.movie_outlined,
                        color: ZallTheme.highlightBlue,
                        size: 30,
                      ),
                    )
                  : const Icon(
                      Icons.movie_outlined,
                      color: ZallTheme.highlightBlue,
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Title, Platform & Size Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.metadata.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ZallTheme.circleSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.metadata.platform.displayName,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: ZallTheme.highlightBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      task.selectedStream.qualityLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: ZallTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Actions: Play/Open & Delete
          if (isDone && exists) ...[
            IconButton(
              icon: const Icon(Icons.play_circle_fill, color: ZallTheme.primaryBlue, size: 30),
              tooltip: 'Buka / Putar',
              onPressed: () => OpenFilex.open(task.savedFilePath!),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 22),
              tooltip: 'Hapus File',
              onPressed: () => _showDeleteDialog(context, service, task.id),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 22),
              tooltip: 'Hapus dari riwayat',
              onPressed: () => service.removeTask(task.id),
            ),
          ],
        ],
      ),
    );
  }
}
