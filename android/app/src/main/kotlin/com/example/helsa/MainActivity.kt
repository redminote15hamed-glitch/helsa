package com.example.helsa

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "helsa/widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "pinWidget") {
                    val stepsOnly = call.argument<Boolean>("stepsOnly") ?: false
                    result.success(requestPinHelsaWidget(stepsOnly))
                } else {
                    result.notImplemented()
                }
            }
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
        return try {
            mgr.requestPinAppWidget(provider, null, null)
            true
        } catch (_: Exception) {
            false
        }
    }
}
