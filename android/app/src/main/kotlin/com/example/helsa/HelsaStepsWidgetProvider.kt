package com.example.helsa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** Single-metric steps widget — hardened against "Can't load widget". */
class HelsaStepsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) {
            updateOne(context, appWidgetManager, id, widgetData)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        updateOne(context, appWidgetManager, appWidgetId, prefs)
    }

    private fun updateOne(
        context: Context,
        appWidgetManager: AppWidgetManager,
        id: Int,
        widgetData: SharedPreferences
    ) {
        try {
            val views = RemoteViews(context.packageName, R.layout.helsa_widget_steps)

            val steps = widgetData.getInt("steps", 0)
            val stepsGoal = widgetData.getInt("steps_goal", 8000).coerceAtLeast(1)
            val pct = ((steps * 100) / stepsGoal).coerceIn(0, 999)
            val stepsColor = widgetData.getInt("steps_color", Color.parseColor("#10B981"))
            val bgColor = HelsaWidgetProvider.forceOpaque(
                widgetData.getInt("widget_bg", Color.parseColor("#F0FFFFFF"))
            )
            val muted = widgetData.getInt("muted_color", Color.parseColor("#99000000"))
            val unit = widgetData.getString("steps_label", "steps") ?: "steps"

            try {
                val density = context.resources.displayMetrics.density
                val options = appWidgetManager.getAppWidgetOptions(id)
                val minW = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110) ?: 110
                val minH = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110) ?: 110
                val wPx = (minW.coerceAtLeast(100) * density).toInt().coerceIn(120, 500)
                val hPx = (minH.coerceAtLeast(80) * density).toInt().coerceIn(80, 400)
                views.setImageViewBitmap(
                    R.id.widget_bg_image,
                    HelsaWidgetProvider.roundedRectBitmap(wPx, hPx, 18f * density, bgColor)
                )
            } catch (e: Exception) {
                Log.w(TAG, "bg skipped", e)
            }

            HelsaWidgetProvider.safeText(views, R.id.tv_steps_big, steps.toString())
            HelsaWidgetProvider.safeText(views, R.id.tv_steps_unit, unit)
            HelsaWidgetProvider.safeText(views, R.id.tv_steps_pct_capsule, "$pct%")
            HelsaWidgetProvider.safeColor(views, R.id.tv_steps_big, stepsColor)
            HelsaWidgetProvider.safeColor(views, R.id.tv_steps_unit, muted)
            HelsaWidgetProvider.safeColor(views, R.id.tv_steps_pct_capsule, stepsColor)

            HelsaWidgetProvider.tint(views, R.id.iv_steps_big, stepsColor)
            HelsaWidgetProvider.tint(
                views,
                R.id.iv_steps_disk,
                HelsaWidgetProvider.withAlpha(stepsColor, 0x33),
            )

            try {
                views.setProgressBar(R.id.bar_steps_capsule, 100, pct.coerceAtMost(100), false)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    views.setColorStateList(
                        R.id.bar_steps_capsule,
                        "setProgressTintList",
                        ColorStateList.valueOf(stepsColor)
                    )
                    views.setColorStateList(
                        R.id.bar_steps_capsule,
                        "setProgressBackgroundTintList",
                        ColorStateList.valueOf(HelsaWidgetProvider.withAlpha(stepsColor, 0x33))
                    )
                }
            } catch (_: Exception) {
            }

            appWidgetManager.updateAppWidget(id, views)
        } catch (e: Exception) {
            Log.e(TAG, "steps widget update failed", e)
            try {
                val views = RemoteViews(context.packageName, R.layout.helsa_widget_steps)
                HelsaWidgetProvider.safeText(views, R.id.tv_steps_big, "—")
                appWidgetManager.updateAppWidget(id, views)
            } catch (e2: Exception) {
                Log.e(TAG, "steps fallback failed", e2)
            }
        }
    }

    companion object {
        private const val TAG = "HelsaStepsWidget"
    }
}
