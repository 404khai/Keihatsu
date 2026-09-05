package com.example.keihatsu

import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "keihatsu/storage")
            .setMethodCallHandler { call, result ->
                if (call.method != "getStorageStats") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val stat = StatFs(Environment.getExternalStorageDirectory().path)
                result.success(
                    mapOf(
                        "totalBytes" to stat.totalBytes,
                        "freeBytes" to stat.availableBytes,
                    ),
                )
            }
    }
}
