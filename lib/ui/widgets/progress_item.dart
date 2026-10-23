import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/download_service.dart';

class ProgressItemWidget extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onCancel;

  const ProgressItemWidget({
    super.key,
    required this.task,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDownloading = task.status == DownloadStatus.downloading;
    final isProcessing = task.status == DownloadStatus.processing;
    final isCompleted = task.status == DownloadStatus.completed;
    final isFailed = task.status == DownloadStatus.failed;
    final isCancelled = task.status == DownloadStatus.cancelled;

    Color statusColor;
    String statusText;

    if (isCompleted) {
      statusColor = Colors.green;
      statusText = 'Selesai';
    } else if (isProcessing) {
      statusColor = Colors.amber;
      statusText = 'Memproses FFmpeg';
    } else if (isDownloading) {
      statusColor = theme.colorScheme.primary;
      statusText = 'Mengunduh';
    } else if (isCancelled) {
      statusColor = Colors.grey;
      statusText = 'Dibatalkan';
    } else {
      statusColor = Colors.red;
      statusText = 'Gagal';
    }

    final speedMb = (task.speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1);
    final percent = (task.progress * 100).toInt();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title & Status Chip
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.metadata.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Platform and Creator
            Text(
              '${task.metadata.platform.displayName} • ${task.metadata.creatorName}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),

            // Progress Bar (when downloading or processing)
            if (isDownloading || isProcessing) ...[
              LinearProgressIndicator(
                value: isProcessing ? null : task.progress,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$percent%', style: theme.textTheme.labelSmall),
                  if (isDownloading) Text('$speedMb MB/s', style: theme.textTheme.labelSmall),
                ],
              ),
            ],

            // File path and Action Buttons
            if (task.savedFilePath != null) ...[
              const SizedBox(height: 6),
              Text(
                'Tersimpan di: ${task.savedFilePath}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],

            if (isFailed && task.errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                task.errorMessage!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ],

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isDownloading || isProcessing)
                  TextButton.icon(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    label: const Text('Batalkan', style: TextStyle(color: Colors.red)),
                    onPressed: onCancel,
                  ),
                if (isCompleted && task.savedFilePath != null)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('Buka Berkas'),
                    onPressed: () {
                      OpenFilex.open(task.savedFilePath!);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
