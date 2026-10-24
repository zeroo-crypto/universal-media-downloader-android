import 'dart:io';
import 'package:flutter/services.dart';

class DeviceStorageInfo {
  final int totalBytes;
  final int availableBytes;
  final int usedBytes;
  final String totalFormatted;
  final String availableFormatted;
  final String usedFormatted;
  final double usedPercentage; // 0.0 to 1.0

  DeviceStorageInfo({
    required this.totalBytes,
    required this.availableBytes,
    required this.usedBytes,
    required this.totalFormatted,
    required this.availableFormatted,
    required this.usedFormatted,
    required this.usedPercentage,
  });

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double dBytes = bytes.toDouble();
    while (dBytes >= 1024 && i < suffixes.length - 1) {
      dBytes /= 1024;
      i++;
    }
    return '${dBytes.toStringAsFixed(i >= 3 ? 1 : 0)} ${suffixes[i]}';
  }

  factory DeviceStorageInfo.fallback() {
    return DeviceStorageInfo(
      totalBytes: 257698037760, // 240 GB
      availableBytes: 9663676416, // ~9 GB
      usedBytes: 248034361344,   // ~231 GB
      totalFormatted: '240 GB',
      availableFormatted: '9 GB',
      usedFormatted: '231 GB',
      usedPercentage: 0.96,
    );
  }
}

class StorageService {
  static const MethodChannel _channel =
      MethodChannel('com.zeroo.universal_media_downloader/media_scanner');

  static Future<DeviceStorageInfo> getDeviceStorageInfo() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<Map>('getStorageInfo');
        if (result != null) {
          final total = (result['totalBytes'] as num?)?.toInt() ?? 0;
          final available = (result['availableBytes'] as num?)?.toInt() ?? 0;
          final used = (result['usedBytes'] as num?)?.toInt() ?? (total - available);

          final totalGb = total / (1024 * 1024 * 1024);
          final usedGb = used / (1024 * 1024 * 1024);
          final percentage = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

          return DeviceStorageInfo(
            totalBytes: total,
            availableBytes: available,
            usedBytes: used,
            totalFormatted: '${totalGb.toStringAsFixed(0)}GB',
            availableFormatted: DeviceStorageInfo.formatBytes(available),
            usedFormatted: '${usedGb.toStringAsFixed(0)}GB',
            usedPercentage: percentage,
          );
        }
      }
    } catch (_) {}

    return DeviceStorageInfo.fallback();
  }
}
