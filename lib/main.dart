import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'services/download_service.dart';
import 'services/share_intent_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/downloads_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Foreground Task for Background Downloads
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'universal_media_downloader_channel',
      channelName: 'Universal Downloader Service',
      channelDescription: 'Menampilkan progres unduhan media di latar belakang',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      iconData: const NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 5000,
      isOnceEvent: false,
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DownloadService()),
      ],
      child: const UniversalDownloaderApp(),
    ),
  );
}

class UniversalDownloaderApp extends StatefulWidget {
  const UniversalDownloaderApp({super.key});

  @override
  State<UniversalDownloaderApp> createState() => _UniversalDownloaderAppState();
}

class _UniversalDownloaderAppState extends State<UniversalDownloaderApp> {
  int _currentIndex = 0;
  String? _incomingUrl;

  @override
  void initState() {
    super.initState();
    _requestAppPermissions();
    _initShareIntent();
  }

  Future<void> _requestAppPermissions() async {
    // Request storage and notification permissions
    await [
      Permission.storage,
      Permission.notification,
      Permission.manageExternalStorage,
    ].request();
  }

  void _initShareIntent() {
    ShareIntentService.init(
      onUrlReceived: (url) {
        setState(() {
          _incomingUrl = url;
          _currentIndex = 0; // Switch to Home tab immediately
        });
      },
    );
  }

  @override
  void dispose() {
    ShareIntentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Downloader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(initialUrl: _incomingUrl),
            const DownloadsScreen(),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.download_outlined),
              selectedIcon: Icon(Icons.download),
              label: 'Unduhan',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}
