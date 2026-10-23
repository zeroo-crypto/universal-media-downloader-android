import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/download_service.dart';
import '../widgets/progress_item.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadService = context.watch<DownloadService>();
    final tasks = downloadService.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Unduhan', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_done_outlined, size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Unduhan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tempel URL di Beranda atau bagikan dari aplikasi lain',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ProgressItemWidget(
                  task: task,
                  onCancel: () => downloadService.cancelTask(task.id),
                );
              },
            ),
    );
  }
}
