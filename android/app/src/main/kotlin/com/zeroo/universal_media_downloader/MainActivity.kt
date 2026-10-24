package com.zeroo.universal_media_downloader

import android.media.MediaScannerConnection
import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.zeroo.universal_media_downloader/media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        MediaScannerConnection.scanFile(
                            applicationContext,
                            arrayOf(path),
                            null
                        ) { _, _ -> }
                        result.success(true)
                    } else {
                        result.error("INVALID_PATH", "Path cannot be null", null)
                    }
                }
                "getStorageInfo" -> {
                    try {
                        val path = Environment.getDataDirectory()
                        val stat = StatFs(path.path)
                        val blockSize: Long = stat.blockSizeLong
                        val totalBlocks: Long = stat.blockCountLong
                        val availableBlocks: Long = stat.availableBlocksLong

                        val totalBytes: Long = totalBlocks * blockSize
                        val availableBytes: Long = availableBlocks * blockSize
                        val usedBytes: Long = (totalBytes - availableBytes).coerceAtLeast(0L)

                        result.success(mapOf(
                            "totalBytes" to totalBytes,
                            "availableBytes" to availableBytes,
                            "usedBytes" to usedBytes
                        ))
                    } catch (e: Exception) {
                        result.error("STORAGE_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
