package com.example.helsa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Size-aware widget:
 *  - compact  (~1 row): numbers + labels
 *  - medium   (~2x4):  + fraction + percent
 *  - large    (~3x4+): vertical bottom→top bars + fraction + percent
 */
class HelsaWidgetProvider : HomeWidgetProvider() {

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
            val options = appWidgetManager.getAppWidgetOptions(id)
            val minH = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0) ?: 0

            // ~70dp ≈ 1 cell, ~140dp ≈ 2 cells, ~210dp ≈ 3 cells
            val layoutId = when {
                minH >= 160 -> R.layout.helsa_widget_large
                minH >= 90 -> R.layout.helsa_widget_medium
                else -> R.layout.helsa_widget
            }

            val views = RemoteViews(context.packageName, layoutId)

            val steps = widgetData.getInt("steps", 0)
            val cal = widgetData.getInt("cal", 0)
            val mins = widgetData.getInt("mins", 0)
            val stepsGoal = widgetData.getInt("steps_goal", 8000).coerceAtLeast(1)
            val calGoal = widgetData.getInt("cal_goal", 300).coerceAtLeast(1)
            val minsGoal = widgetData.getInt("mins_goal", 30).coerceAtLeast(1)

            val stepsLabel = widgetData.getString("steps_label", "steps") ?: "steps"
            val calLabel = widgetData.getString("cal_label", "kcal") ?: "kcal"
            val timeLabel = widgetData.getString("time_label", "min") ?: "min"

            val stepsPct = ((steps * 100.0) / stepsGoal).toInt().coerceIn(0, 999)
            val calPct = ((cal * 100.0) / calGoal).toInt().coerceIn(0, 999)
            val minsPct = ((mins * 100.0) / minsGoal).toInt().coerceIn(0, 999)
            val stepsBar = stepsPct.coerceAtMost(100)
            val calBar = calPct.coerceAtMost(100)
            val minsBar = minsPct.coerceAtMost(100)

            // Common
            views.setTextViewText(R.id.tv_steps, steps.toString())
            views.setTextViewText(R.id.tv_cal, cal.toString())
            views.setTextViewText(R.id.tv_time, mins.toString())
            views.setTextViewText(R.id.tv_steps_label, stepsLabel)
            views.setTextViewText(R.id.tv_cal_label, calLabel)
            views.setTextViewText(R.id.tv_time_label, timeLabel)

            // Medium + large
            if (layoutId == R.layout.helsa_widget_medium ||
                layoutId == R.layout.helsa_widget_large
            ) {
                views.setTextViewText(R.id.tv_steps_frac, "$steps / $stepsGoal")
                views.setTextViewText(R.id.tv_cal_frac, "$cal / $calGoal")
                views.setTextViewText(R.id.tv_time_frac, "$mins / $minsGoal")
                views.setTextViewText(R.id.tv_steps_pct, "$stepsPct%")
                views.setTextViewText(R.id.tv_cal_pct, "$calPct%")
                views.setTextViewText(R.id.tv_time_pct, "$minsPct%")
            }

            // Large only: vertical bars
            if (layoutId == R.layout.helsa_widget_large) {
                views.setProgressBar(R.id.pb_steps, 100, stepsBar, false)
                views.setProgressBar(R.id.pb_cal, 100, calBar, false)
                views.setProgressBar(R.id.pb_time, 100, minsBar, false)
            }

            appWidgetManager.updateAppWidget(id, views)
        } catch (e: Exception) {
            try {
                val fallback = RemoteViews(context.packageName, R.layout.helsa_widget)
                appWidgetManager.updateAppWidget(id, fallback)
            } catch (_: Exception) {
            }
        }
    }
}
