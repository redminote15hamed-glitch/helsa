package com.example.helsa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Bundle
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Steps-only widget: big number + unit, step icon, capsule bar with % inside.
 * When bar is mostly filled, percent text switches to white for contrast.
 */
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
        val prefs = context.getSharedPreferences(
            "HomeWidgetPreferences",
            Context.MODE_PRIVATE
        )
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
            val goal = widgetData.getInt("steps_goal", 8000).coerceAtLeast(1)
            val unit = widgetData.getString("steps_label", "steps") ?: "steps"
            val pct = ((steps * 100.0) / goal).toInt().coerceIn(0, 999)
            val bar = pct.coerceAtMost(100)

            views.setTextViewText(R.id.tv_steps_value, steps.toString())
            views.setTextViewText(R.id.tv_steps_unit, unit)
            views.setTextViewText(R.id.tv_steps_pct, "$pct%")
            views.setProgressBar(R.id.pb_steps_capsule, 100, bar, false)

            // Scale number with height when resized
            val options = appWidgetManager.getAppWidgetOptions(id)
            val minH = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0) ?: 0
            val sp = when {
                minH >= 160 -> 40f
                minH >= 120 -> 34f
                else -> 28f
            }
            views.setTextViewTextSize(
                R.id.tv_steps_value,
                TypedValue.COMPLEX_UNIT_SP,
                sp
            )

            // Percent contrast: filled bar → white; empty/mid → dark mint
            if (bar >= 55) {
                views.setTextColor(R.id.tv_steps_pct, Color.WHITE)
            } else {
                views.setTextColor(R.id.tv_steps_pct, Color.parseColor("#047857"))
            }

            appWidgetManager.updateAppWidget(id, views)
        } catch (_: Exception) {
            try {
                val fallback = RemoteViews(context.packageName, R.layout.helsa_widget_steps)
                appWidgetManager.updateAppWidget(id, fallback)
            } catch (_: Exception) {
            }
        }
    }
}
