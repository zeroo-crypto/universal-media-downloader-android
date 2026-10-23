import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/platforms.dart';
import '../../extractors/base_extractor.dart';
import '../../extractors/extractor_registry.dart';
import '../../services/download_service.dart';
import '../widgets/media_preview_card.dart';

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
  MediaMetadata? _resolvedMetadata;

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
      _urlController.text = data.text!.trim();
      _analyzeUrl(_urlController.text);
    }
  }

  Future<void> _analyzeUrl(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resolvedMetadata = null;
    });

    try {
      final metadata = await ExtractorRegistry.extractMedia(cleanUrl);
      setState(() {
        _resolvedMetadata = metadata;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadService = context.watch<DownloadService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal Downloader', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.paste),
            tooltip: 'Tempel dari Clipboard',
            onPressed: _pasteFromClipboard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: 'Tempel URL YouTube, Pixiv, Twitter, Pinterest...',
                        prefixIcon: const Icon(Icons.link),
                        suffixIcon: _urlController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _urlController.clear();
                                  setState(() {
                                    _resolvedMetadata = null;
                                    _errorMessage = null;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      onSubmitted: _analyzeUrl,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.content_paste),
                            label: const Text('Tempel Link'),
                            onPressed: _pasteFromClipboard,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.search),
                            label: const Text('Periksa URL'),
                            onPressed: _isLoading ? null : () => _analyzeUrl(_urlController.text),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Supported Platforms Horizontal Chips
            Text(
              'Platform Didukung:',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _platformChip('YouTube', Icons.play_arrow, Colors.red),
                _platformChip('Pixiv', Icons.palette, Colors.blue),
                _platformChip('Pinterest', Icons.push_pin, Colors.redAccent),
                _platformChip('Twitter/X', Icons.alternate_email, Colors.black87),
                _platformChip('TikTok', Icons.music_note, Colors.pink),
                _platformChip('Instagram', Icons.camera_alt, Colors.purple),
              ],
            ),
            const SizedBox(height: 20),

            // Loading Indicator
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Menganalisis konten media...'),
                    ],
                  ),
                ),
              ),

            // Error Message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Resolved Media Preview Card
            if (_resolvedMetadata != null) ...[
              MediaPreviewCard(
                metadata: _resolvedMetadata!,
                onDownloadSelected: (stream) {
                  downloadService.enqueueDownload(_resolvedMetadata!, stream);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Unduhan dimulai: ${_resolvedMetadata!.title}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  setState(() {
                    _resolvedMetadata = null;
                    _urlController.clear();
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _platformChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
