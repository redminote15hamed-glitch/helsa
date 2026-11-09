package com.example.helsa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 3-metric home widget — HyperOS-safe: simple layout, no bitmaps required.
 */
class HelsaWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) {
            bind(context, appWidgetManager, id, widgetData)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        bind(context, appWidgetManager, appWidgetId, prefs)
    }

    private fun bind(
        context: Context,
        appWidgetManager: AppWidgetManager,
        id: Int,
        data: SharedPreferences
    ) {
        try {
            val views = RemoteViews(context.packageName, R.layout.helsa_widget)

            val steps = data.getInt("steps", 0)
            val cal = data.getInt("cal", 0)
            val mins = data.getInt("mins", 0)
            val stepsColor = data.getInt("steps_color", Color.parseColor("#10B981"))
            val calColor = data.getInt("cal_color", Color.parseColor("#F97316"))
            val timeColor = data.getInt("time_color", Color.parseColor("#3B82F6"))
            val muted = data.getInt("muted_color", Color.parseColor("#99000000"))
            val stepsLabel = data.getString("steps_label", "steps") ?: "steps"
            val calLabel = data.getString("cal_label", "kcal") ?: "kcal"
            val timeLabel = data.getString("time_label", "min") ?: "min"

            views.setTextViewText(R.id.tv_steps, steps.toString())
            views.setTextViewText(R.id.tv_cal, cal.toString())
            views.setTextViewText(R.id.tv_time, mins.toString())
            views.setTextViewText(R.id.tv_steps_label, stepsLabel)
            views.setTextViewText(R.id.tv_cal_label, calLabel)
            views.setTextViewText(R.id.tv_time_label, timeLabel)

            views.setTextColor(R.id.tv_steps, stepsColor)
            views.setTextColor(R.id.tv_cal, calColor)
            views.setTextColor(R.id.tv_time, timeColor)
            views.setTextColor(R.id.tv_steps_label, muted)
            views.setTextColor(R.id.tv_cal_label, muted)
            views.setTextColor(R.id.tv_time_label, muted)

            try {
                views.setInt(R.id.iv_steps, "setColorFilter", stepsColor)
                views.setInt(R.id.iv_cal, "setColorFilter", calColor)
                views.setInt(R.id.iv_time, "setColorFilter", timeColor)
            } catch (_: Exception) {
            }

            appWidgetManager.updateAppWidget(id, views)
            Log.d(TAG, "widget $id updated steps=$steps")
        } catch (e: Exception) {
            Log.e(TAG, "bind failed", e)
            try {
                val views = RemoteViews(context.packageName, R.layout.helsa_widget)
                views.setTextViewText(R.id.tv_steps, "—")
                views.setTextViewText(R.id.tv_cal, "—")
                views.setTextViewText(R.id.tv_time, "—")
                appWidgetManager.updateAppWidget(id, views)
            } catch (e2: Exception) {
                Log.e(TAG, "fallback failed", e2)
            }
        }
    }

    companion object {
        private const val TAG = "HelsaWidget"
        private const val PREFS = "HomeWidgetPreferences"
    }
}
