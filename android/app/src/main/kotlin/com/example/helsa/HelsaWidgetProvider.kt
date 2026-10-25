package com.example.helsa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Responsive widget: picks compact or tall layout from current height.
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
            // ~70dp+ → tall layout; smaller → compact (fits 1-row MIUI cells)
            val layoutId = if (minH >= 70) {
                R.layout.helsa_widget_tall
            } else {
                R.layout.helsa_widget
            }

            val views = RemoteViews(context.packageName, layoutId)
            val steps = widgetData.getInt("steps", 0)
            val cal = widgetData.getInt("cal", 0)
            val mins = widgetData.getInt("mins", 0)
            val stepsLabel = widgetData.getString("steps_label", "steps") ?: "steps"
            val calLabel = widgetData.getString("cal_label", "kcal") ?: "kcal"
            val timeLabel = widgetData.getString("time_label", "min") ?: "min"

            views.setTextViewText(R.id.tv_steps, steps.toString())
            views.setTextViewText(R.id.tv_cal, cal.toString())
            views.setTextViewText(R.id.tv_time, mins.toString())
            views.setTextViewText(R.id.tv_steps_label, stepsLabel)
            views.setTextViewText(R.id.tv_cal_label, calLabel)
            views.setTextViewText(R.id.tv_time_label, timeLabel)

            // Slight text scale when very wide
            val minW = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0) ?: 0
            if (minW >= 280 && minH >= 70) {
                val sp = TypedValue.applyDimension(
                    TypedValue.COMPLEX_UNIT_SP, 20f, context.resources.displayMetrics
                )
                views.setTextViewTextSize(R.id.tv_steps, TypedValue.COMPLEX_UNIT_PX, sp)
                views.setTextViewTextSize(R.id.tv_cal, TypedValue.COMPLEX_UNIT_PX, sp)
                views.setTextViewTextSize(R.id.tv_time, TypedValue.COMPLEX_UNIT_PX, sp)
            }

            appWidgetManager.updateAppWidget(id, views)
        } catch (_: Exception) {
            try {
                val fallback = RemoteViews(context.packageName, R.layout.helsa_widget)
                appWidgetManager.updateAppWidget(id, fallback)
            } catch (_: Exception) {
            }
        }
    }
}
