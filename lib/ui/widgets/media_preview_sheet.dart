import 'package:flutter/material.dart';
import '../../core/constants/platforms.dart';
import '../../extractors/base_extractor.dart';
import '../../services/language_service.dart';
import '../theme/zall_theme.dart';

class MediaPreviewSheet extends StatefulWidget {
  final MediaMetadata metadata;
  final Function(MediaStreamItem selectedStream) onDownloadSingle;
  final Function(List<MediaStreamItem> allStreams)? onDownloadAll;

  const MediaPreviewSheet({
    super.key,
    required this.metadata,
    required this.onDownloadSingle,
    this.onDownloadAll,
  });

  static Future<void> show({
    required BuildContext context,
    required MediaMetadata metadata,
    required Function(MediaStreamItem selectedStream) onDownloadSingle,
    Function(List<MediaStreamItem> allStreams)? onDownloadAll,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MediaPreviewSheet(
        metadata: metadata,
        onDownloadSingle: onDownloadSingle,
        onDownloadAll: onDownloadAll,
      ),
    );
  }

  @override
  State<MediaPreviewSheet> createState() => _MediaPreviewSheetState();
}

class _MediaPreviewSheetState extends State<MediaPreviewSheet> {
  MediaStreamItem? _selectedStream;

  @override
  void initState() {
    super.initState();
    if (widget.metadata.streams.isNotEmpty) {
      _selectedStream = widget.metadata.streams.first;
    }
  }

  Color _getPlatformColor(MediaPlatform platform) {
    switch (platform) {
      case MediaPlatform.youtube:
        return ZallTheme.youtubeRed;
      case MediaPlatform.pixiv:
        return ZallTheme.pixivBlue;
      case MediaPlatform.instagram:
        return ZallTheme.instagramGradientMiddle;
      case MediaPlatform.pinterest:
        return ZallTheme.pinterestRed;
      case MediaPlatform.tiktok:
        return const Color(0xFF25F4EE);
      case MediaPlatform.twitter:
        return Colors.white;
      default:
        return ZallTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final streams = widget.metadata.streams;
    final isMulti = widget.metadata.isMultiPage || streams.length > 1;
    final platformColor = _getPlatformColor(widget.metadata.platform);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1D26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Platform Badge & Work ID
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: platformColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: platformColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: platformColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.metadata.platform.displayName,
                      style: TextStyle(
                        color: platformColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (widget.metadata.workId.isNotEmpty)
                Text(
                  'ID: ${widget.metadata.workId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ZallTheme.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Thumbnail & Details Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 95,
                  height: 95,
                  color: const Color(0xFF262834),
                  child: widget.metadata.thumbnailUrl != null &&
                          widget.metadata.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          widget.metadata.thumbnailUrl!,
                          fit: BoxFit.cover,
                          headers: const {
                            'User-Agent':
                                'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                            'Referer': 'https://www.pixiv.net/',
                          },
                          errorBuilder: (_, __, ___) => _fallbackThumb(),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                        )
                      : _fallbackThumb(),
                ),
              ),
              const SizedBox(width: 14),

              // Title, Creator & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.metadata.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${context.tr('preview_creator')}${widget.metadata.creatorName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: ZallTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isMulti)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ZallTheme.primaryBlue.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${streams.length} ${context.tr('preview_items_count')}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: ZallTheme.highlightBlue,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Format: ${widget.metadata.mediaType.label}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ZallTheme.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Quality / Resolution Dropdown (if more than 1 stream option)
          if (streams.length > 1) ...[
            Text(
              context.tr('preview_choose_format'),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF14151B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MediaStreamItem>(
                  value: _selectedStream,
                  dropdownColor: const Color(0xFF1C1D26),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: ZallTheme.highlightBlue),
                  items: streams.map((stream) {
                    return DropdownMenuItem<MediaStreamItem>(
                      value: stream,
                      child: Text(
                        stream.qualityLabel,
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (newVal) {
                    if (newVal != null) {
                      setState(() => _selectedStream = newVal);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Action Buttons
          if (isMulti && widget.onDownloadAll != null) ...[
            // Batch Download "Unduh Semua"
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.file_download_done, color: Colors.white),
                label: Text(
                  '${context.tr('preview_download_all')} (${streams.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZallTheme.actionBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDownloadAll!(streams);
                },
              ),
            ),
            const SizedBox(height: 10),
            // Single Download "Unduh Item Pilihan Saja"
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ZallTheme.primaryBlue.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _selectedStream == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        widget.onDownloadSingle(_selectedStream!);
                      },
                child: Text(
                  context.tr('preview_download_single'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ZallTheme.highlightBlue,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Single Media Download
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download, color: Colors.white),
                label: Text(
                  context.tr('preview_download_now'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZallTheme.actionBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                onPressed: _selectedStream == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        widget.onDownloadSingle(_selectedStream!);
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fallbackThumb() {
    return Center(
      child: Icon(
        Icons.movie_creation_outlined,
        size: 38,
        color: ZallTheme.highlightBlue.withOpacity(0.6),
      ),
    );
  }
}
