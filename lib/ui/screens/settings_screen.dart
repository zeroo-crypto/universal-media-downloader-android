import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/platforms.dart';
import '../../core/storage/hierarchy_manager.dart';
import '../../core/utils/clean_cancel.dart';
import '../../services/cookie_vault_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _storagePath = 'Memuat...';
  String? _pixivCookie;
  String? _twitterCookie;
  String? _instagramCookie;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dir = await HierarchyManager.getBaseMediaDirectory();
    final pixiv = await CookieVaultService.getCookie(MediaPlatform.pixiv);
    final twitter = await CookieVaultService.getCookie(MediaPlatform.twitter);
    final ig = await CookieVaultService.getCookie(MediaPlatform.instagram);

    if (mounted) {
      setState(() {
        _storagePath = dir.path;
        _pixivCookie = pixiv;
        _twitterCookie = twitter;
        _instagramCookie = ig;
      });
    }
  }

  Future<void> _editCookieDialog(MediaPlatform platform, String currentVal) async {
    final controller = TextEditingController(text: currentVal);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cookie Vault: ${platform.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan token sesi (contoh: PHPSESSID untuk Pixiv, auth_token untuk Twitter):',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nilai token cookie...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Hapus'),
            onPressed: () => Navigator.pop(ctx, ''),
          ),
          FilledButton(
            child: const Text('Simpan'),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          ),
        ],
      ),
    );

    if (result != null) {
      if (result.isEmpty) {
        await CookieVaultService.removeCookie(platform);
      } else {
        await CookieVaultService.saveCookie(platform, result);
      }
      _loadSettings();
    }
  }

  Future<void> _purgeOrphanedFiles() async {
    final dir = await HierarchyManager.getBaseMediaDirectory();
    final count = await CleanCancel.cleanupDirectory(dir);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pembersihan selesai: $count berkas sementara (.part/.tmp) dimusnahkan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section: Lokasi Penyimpanan
          Text('Penyimpanan Berkas', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.folder, color: Colors.amber),
              title: const Text('Direktori Media'),
              subtitle: Text(_storagePath, style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.lock_outline, size: 20),
            ),
          ),
          const SizedBox(height: 20),

          // Section: Cookie Vault
          Text('Cookie Vault (Akun & Konten Terbatas)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette, color: Colors.blue),
                  title: const Text('Pixiv (PHPSESSID)'),
                  subtitle: Text(_pixivCookie != null ? 'Tersimpan (Aktif)' : 'Belum dipasang (Hanya konten publik)', style: TextStyle(fontSize: 12, color: _pixivCookie != null ? Colors.green : Colors.grey)),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _editCookieDialog(MediaPlatform.pixiv, _pixivCookie ?? ''),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alternate_email, color: Colors.black87),
                  title: const Text('Twitter/X (auth_token)'),
                  subtitle: Text(_twitterCookie != null ? 'Tersimpan (Aktif)' : 'Belum dipasang', style: TextStyle(fontSize: 12, color: _twitterCookie != null ? Colors.green : Colors.grey)),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _editCookieDialog(MediaPlatform.twitter, _twitterCookie ?? ''),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.purple),
                  title: const Text('Instagram (sessionid)'),
                  subtitle: Text(_instagramCookie != null ? 'Tersimpan (Aktif)' : 'Belum dipasang', style: TextStyle(fontSize: 12, color: _instagramCookie != null ? Colors.green : Colors.grey)),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _editCookieDialog(MediaPlatform.instagram, _instagramCookie ?? ''),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Kebersihan Berkas
          Text('Integritas & Pembersihan', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.teal),
              title: const Text('Bersihkan File Sampah (.part / .tmp)'),
              subtitle: const Text('Memusnahkan semua berkas yang terputus atau 0-byte (Zero Orphaned Files)', style: TextStyle(fontSize: 12)),
              onTap: _purgeOrphanedFiles,
            ),
          ),
        ],
      ),
    );
  }
}
