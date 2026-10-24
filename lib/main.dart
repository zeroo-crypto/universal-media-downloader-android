import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'services/download_service.dart';
import 'services/language_service.dart';
import 'services/share_intent_service.dart';
import 'ui/theme/zall_theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/gallery_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Foreground Task for Background Downloads
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'zall_media_downloader_channel',
      channelName: 'ZALL Downloader Service',
      channelDescription: 'Menampilkan proses unduhan media di latar belakang',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DownloadService()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const ZallApp(),
    ),
  );
}

class ZallApp extends StatefulWidget {
  const ZallApp({super.key});

  @override
  State<ZallApp> createState() => _ZallAppState();
}

class _ZallAppState extends State<ZallApp> {
  String? _incomingUrl;

  @override
  void initState() {
    super.initState();
    _requestAppPermissions();
    _initShareIntent();
  }

  Future<void> _requestAppPermissions() async {
    try {
      await [
        Permission.storage,
        Permission.notification,
        Permission.manageExternalStorage,
      ].request();
    } catch (_) {}
  }

  void _initShareIntent() {
    ShareIntentService.init(
      onUrlReceived: (url) {
        setState(() {
          _incomingUrl = url;
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
    final languageProvider = context.watch<LanguageProvider>();

    return MaterialApp(
      title: 'ZALL',
      debugShowCheckedModeBanner: false,
      locale: languageProvider.currentLocale,
      theme: ZallTheme.darkTheme,
      darkTheme: ZallTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routes: {
        '/': (_) => HomeScreen(initialUrl: _incomingUrl),
        '/gallery': (_) => const GalleryScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
      initialRoute: '/',
    );
  }
}
