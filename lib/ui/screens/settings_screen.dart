import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/platforms.dart';
import '../../core/storage/hierarchy_manager.dart';
import '../../core/utils/clean_cancel.dart';
import '../../services/cookie_vault_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _storagePath = 'Loading...';
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
              'Enter session token (e.g., PHPSESSID for Pixiv, auth_token for Twitter):',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Cookie token value...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(ctx, ''),
          ),
          FilledButton(
            child: const Text('Save'),
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
          content: Text('Cleanup complete: $count temporary files (.part/.tmp) purged.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section: Storage Location
          Text('File Storage', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.folder, color: Colors.amber),
              title: const Text('Media Directory'),
              subtitle: Text(_storagePath, style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.lock_outline, size: 20),
            ),
          ),
          const SizedBox(height: 20),

          // Section: Cookie Vault
          Text('Cookie Vault (Restricted Accounts & Content)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette, color: Colors.blue),
                  title: const Text('Pixiv (PHPSESSID)'),
                  subtitle: Text(_pixivCookie != null ? 'Saved (Active)' : 'Not configured (Public content only)', style: TextStyle(fontSize: 12, color: _pixivCookie != null ? Colors.green : Colors.grey)),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _editCookieDialog(MediaPlatform.pixiv, _pixivCookie ?? ''),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alternate_email, color: Colors.black87),
                  title: const Text('Twitter/X (auth_token)'),
                  subtitle: Text(_twitterCookie != null ? 'Saved (Active)' : 'Not configured', style: TextStyle(fontSize: 12, color: _twitterCookie != null ? Colors.green : Colors.grey)),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _editCookieDialog(MediaPlatform.twitter, _twitterCookie ?? ''),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.purple),
                  title: const Text('Instagram (sessionid)'),
                  subtitle: Text(_instagramCookie != null ? 'Saved (Active)' : 'Not configured', style: TextStyle(fontSize: 12, color: _instagramCookie != null ? Colors.green : Colors.grey)),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _editCookieDialog(MediaPlatform.instagram, _instagramCookie ?? ''),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: File Cleanliness
          Text('Integrity & Cleanup', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.teal),
              title: const Text('Purge Temporary Files (.part / .tmp)'),
              subtitle: const Text('Purge all interrupted or 0-byte files (Zero Orphaned Files)', style: TextStyle(fontSize: 12)),
              onTap: _purgeOrphanedFiles,
            ),
          ),
        ],
      ),
    );
  }
}
