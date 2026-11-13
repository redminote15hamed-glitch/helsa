package com.example.helsa

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "helsa/widget",
        )
        widgetChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "pinWidget" -> {
                    val stepsOnly = call.argument<Boolean>("stepsOnly") ?: false
                    result.success(requestPinHelsaWidget(stepsOnly))
                }
                "getWidgetCount" -> {
                    result.success(widgetCounts())
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "helsa/launcher_icon",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setIcon" -> {
                    // Dart sends paletteId (mint/ocean/…); accept legacy "name" too.
                    val name = call.argument<String>("paletteId")
                        ?: call.argument<String>("name")
                        ?: "mint"
                    val ok = setLauncherIcon(name)
                    Log.d(TAG, "setIcon request=$name ok=$ok")
                    result.success(ok)
                }
                else -> result.notImplemented()
            }
        }

        handlePinCallback(intent)
    }

    /**
     * Enable one activity-alias matching [assetName] (e.g. helsa_icon_ocean),
     * disable the rest. Full class names required (not ".IconMint" alone).
     */
    private fun setLauncherIcon(assetName: String): Boolean {
        val key = assetName
            .removePrefix("helsa_icon_")
            .removePrefix("ic_launcher_")
            .lowercase()
            .trim()

        val aliases = linkedMapOf(
            "mint" to "com.example.helsa.IconMint",
            "ocean" to "com.example.helsa.IconOcean",
            "forest" to "com.example.helsa.IconForest",
            "sunrise" to "com.example.helsa.IconSunrise",
            "lavender" to "com.example.helsa.IconLavender",
            "slate" to "com.example.helsa.IconSlate",
        )
        val target = aliases[key] ?: aliases["mint"]!!
        val pm = applicationContext.packageManager
        val pkg = applicationContext.packageName

        return try {
            val enableComponent = ComponentName(pkg, target)
            val current = pm.getComponentEnabledSetting(enableComponent)
            val alreadyOn =
                current == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                    (current == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT &&
                        target == aliases["mint"])

            // Already the active launcher icon — do nothing (avoids process kill).
            if (alreadyOn) {
                var othersOff = true
                for ((_, fqName) in aliases) {
                    if (fqName == target) continue
                    val st = pm.getComponentEnabledSetting(ComponentName(pkg, fqName))
                    if (st == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                        othersOff = false
                        break
                    }
                }
                if (othersOff) {
                    Log.d(TAG, "setLauncherIcon skip — already active key=$key")
                    return true
                }
            }

            // CRITICAL: enable target FIRST so at least one LAUNCHER component
            // stays enabled. Disabling all first kills the process on many OEMs
            // (despite DONT_KILL_APP), which aborts theme save and reverts icon.
            pm.setComponentEnabledSetting(
                enableComponent,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP,
            )

            // Then disable the other aliases only.
            for ((_, fqName) in aliases) {
                if (fqName == target) continue
                pm.setComponentEnabledSetting(
                    ComponentName(pkg, fqName),
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP,
                )
            }

            nudgeLauncherRefresh(pkg, enableComponent)

            val state = pm.getComponentEnabledSetting(enableComponent)
            val ok = state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT
            Log.d(TAG, "setLauncherIcon key=$key target=$target state=$state ok=$ok")
            ok
        } catch (e: Exception) {
            Log.e(TAG, "setLauncherIcon failed for $assetName", e)
            false
        }
    }

    /** Best-effort launcher cache bust — no-op if OEM ignores it. */
    private fun nudgeLauncherRefresh(pkg: String, enabled: ComponentName) {
        try {
            val changed = Intent(Intent.ACTION_PACKAGE_CHANGED).apply {
                data = Uri.parse("package:$pkg")
                putExtra(Intent.EXTRA_UID, applicationInfo.uid)
                putExtra(
                    Intent.EXTRA_CHANGED_COMPONENT_NAME_LIST,
                    arrayOf(enabled.className),
                )
            }
            sendBroadcast(changed)
        } catch (e: Exception) {
            Log.w(TAG, "PACKAGE_CHANGED broadcast failed", e)
        }
        // MIUI / HyperOS home (undocumented; safe if missing)
        for (action in listOf(
            "com.miui.home.action.REFRESH",
            "com.miui.launcher.action.REFRESH",
            "com.miui.home.ACTION_LIVE_ICON_UPDATE",
        )) {
            try {
                sendBroadcast(Intent(action))
            } catch (_: Exception) {
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handlePinCallback(intent)
    }

    override fun onResume() {
        super.onResume()
        handlePinCallback(intent)
        widgetChannel?.invokeMethod("appResumed", null)
    }

    private fun widgetCounts(): Map<String, Int> {
        return try {
            val mgr = AppWidgetManager.getInstance(this)
            val main = mgr.getAppWidgetIds(
                ComponentName(this, HelsaWidgetProvider::class.java),
            ).size
            val steps = mgr.getAppWidgetIds(
                ComponentName(this, HelsaStepsWidgetProvider::class.java),
            ).size
            mapOf("main" to main, "steps" to steps)
        } catch (_: Exception) {
            mapOf("main" to 0, "steps" to 0)
        }
    }

    private fun handlePinCallback(intent: Intent?) {
        if (intent?.action != ACTION_WIDGET_PINNED) return
        val stepsOnly = intent.getBooleanExtra(EXTRA_STEPS_ONLY, false)
        widgetChannel?.invokeMethod(
            "widgetPinned",
            mapOf("stepsOnly" to stepsOnly),
        )
        intent.action = null
    }

    private fun requestPinHelsaWidget(stepsOnly: Boolean): Map<String, Any?> {
        return try {
            val mgr = AppWidgetManager.getInstance(this)
            if (!mgr.isRequestPinAppWidgetSupported) {
                return mapOf(
                    "ok" to false,
                    "shown" to false,
                    "reason" to "unsupported",
                )
            }
            val provider = ComponentName(
                this,
                if (stepsOnly) {
                    HelsaStepsWidgetProvider::class.java
                } else {
                    HelsaWidgetProvider::class.java
                },
            )
            val callback = Intent(this, MainActivity::class.java).apply {
                action = ACTION_WIDGET_PINNED
                putExtra(EXTRA_STEPS_ONLY, stepsOnly)
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val success = PendingIntent.getActivity(this, if (stepsOnly) 2 else 1, callback, flags)
            val shown = mgr.requestPinAppWidget(provider, null, success)
            mapOf(
                "ok" to shown,
                "shown" to shown,
                "reason" to if (shown) "shown" else "rejected",
            )
        } catch (e: Exception) {
            mapOf(
                "ok" to false,
                "shown" to false,
                "reason" to (e.message ?: "error"),
            )
        }
    }

    companion object {
        private const val TAG = "HelsaLauncherIcon"
        private const val ACTION_WIDGET_PINNED = "com.example.helsa.WIDGET_PINNED"
        private const val EXTRA_STEPS_ONLY = "stepsOnly"
    }
}
