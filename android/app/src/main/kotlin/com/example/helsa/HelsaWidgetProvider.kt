package com.example.helsa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HelsaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.helsa_widget)
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

            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
