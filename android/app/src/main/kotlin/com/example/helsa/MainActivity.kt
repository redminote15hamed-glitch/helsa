package com.example.helsa

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
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
        handlePinCallback(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handlePinCallback(intent)
    }

    override fun onResume() {
        super.onResume()
        handlePinCallback(intent)
        // Tell Flutter we are foreground again (for pin result polling).
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
            mapOf(
                "ok" to true,
                "stepsOnly" to stepsOnly,
            ),
        )
        intent.action = null
    }

    private fun requestPinHelsaWidget(stepsOnly: Boolean): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val mgr = getSystemService(AppWidgetManager::class.java) ?: return false
        if (!mgr.isRequestPinAppWidgetSupported) return false

        val clazz = if (stepsOnly) {
            HelsaStepsWidgetProvider::class.java
        } else {
            HelsaWidgetProvider::class.java
        }
        val provider = ComponentName(this, clazz)

        val callbackIntent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_WIDGET_PINNED
            putExtra(EXTRA_STEPS_ONLY, stepsOnly)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        val successCallback = PendingIntent.getActivity(
            this,
            if (stepsOnly) REQ_PIN_STEPS else REQ_PIN_MAIN,
            callbackIntent,
            flags,
        )

        return try {
            mgr.requestPinAppWidget(provider, null, successCallback)
            true
        } catch (_: Exception) {
            false
        }
    }

    companion object {
        const val ACTION_WIDGET_PINNED = "com.example.helsa.WIDGET_PINNED"
        const val EXTRA_STEPS_ONLY = "stepsOnly"
        private const val REQ_PIN_MAIN = 4101
        private const val REQ_PIN_STEPS = 4102
    }
}
