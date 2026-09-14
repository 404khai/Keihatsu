package com.example.keihatsu

import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Environment
import android.os.StatFs
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val seasonalBrandingPreferences by lazy {
        getSharedPreferences("seasonal_branding", MODE_PRIVATE)
    }

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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "keihatsu/seasonal_branding",
        ).setMethodCallHandler { call, result ->
            if (call.method != "setSeason") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val season = call.argument<String>("season")
            if (season !in seasonalLaunchers.keys) {
                result.error("invalid_season", "Unknown Keihatsu season.", null)
                return@setMethodCallHandler
            }

            queueSeasonalLauncher(season!!)
            result.success(null)
        }
    }

    override fun onStop() {
        super.onStop()
        applyPendingSeasonalLauncher()
    }

    private val seasonalLaunchers: Map<String, String>
        get() = mapOf(
            "spring" to "SpringLauncher",
            "summer" to "SummerLauncher",
            "autumn" to "AutumnLauncher",
            "winter" to "WinterLauncher",
        )

    private fun queueSeasonalLauncher(season: String) {
        val desired = seasonalLaunchers.getValue(season)
        val desiredComponent = ComponentName(this, "$packageName.$desired")
        val desiredState = packageManager.getComponentEnabledSetting(desiredComponent)
        if (
            seasonalBrandingPreferences.getString("active_season", null) == season &&
            desiredState == PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        ) {
            seasonalBrandingPreferences.edit().remove("pending_season").apply()
            return
        }

        // Changing the launcher component while Flutter is foregrounded can cause
        // some launchers to recreate the task and detach a wireless debug session.
        // Resolve the season on startup/resume, then safely apply it once the app
        // has moved to the background.
        seasonalBrandingPreferences.edit().putString("pending_season", season).apply()
    }

    private fun applyPendingSeasonalLauncher() {
        val season = seasonalBrandingPreferences.getString("pending_season", null) ?: return
        val desired = seasonalLaunchers[season] ?: return
        val desiredComponent = ComponentName(this, "$packageName.$desired")

        try {
            // Always enable the replacement first so the package never temporarily
            // has no enabled launcher entry point.
            packageManager.setComponentEnabledSetting(
                desiredComponent,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP,
            )

            seasonalLaunchers.values
                .filter { it != desired }
                .forEach { launcher ->
                    val component = ComponentName(this, "$packageName.$launcher")
                    packageManager.setComponentEnabledSetting(
                        component,
                        PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                        PackageManager.DONT_KILL_APP,
                    )
                }

            seasonalBrandingPreferences.edit()
                .putString("active_season", season)
                .remove("pending_season")
                .apply()
        } catch (error: RuntimeException) {
            Log.w(
                "SeasonalBranding",
                "Unable to apply the $season launcher icon; it will retry later.",
                error,
            )
        }
    }
}
