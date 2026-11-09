package com.example.helsa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** Steps-only widget — HyperOS-safe simple layout. */
class HelsaStepsWidgetProvider : HomeWidgetProvider() {

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
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        bind(context, appWidgetManager, appWidgetId, prefs)
    }

    private fun bind(
        context: Context,
        appWidgetManager: AppWidgetManager,
        id: Int,
        data: SharedPreferences
    ) {
        try {
            val views = RemoteViews(context.packageName, R.layout.helsa_widget_steps)
            val steps = data.getInt("steps", 0)
            val goal = data.getInt("steps_goal", 8000).coerceAtLeast(1)
            val pct = ((steps * 100) / goal).coerceIn(0, 999)
            val stepsColor = data.getInt("steps_color", Color.parseColor("#10B981"))
            val muted = data.getInt("muted_color", Color.parseColor("#99000000"))
            val unit = data.getString("steps_label", "steps") ?: "steps"

            views.setTextViewText(R.id.tv_steps_big, steps.toString())
            views.setTextViewText(R.id.tv_steps_unit, unit)
            views.setTextViewText(R.id.tv_steps_pct_capsule, "$pct%")
            views.setTextColor(R.id.tv_steps_big, stepsColor)
            views.setTextColor(R.id.tv_steps_unit, muted)
            views.setTextColor(R.id.tv_steps_pct_capsule, stepsColor)
            try {
                views.setInt(R.id.iv_steps_big, "setColorFilter", stepsColor)
            } catch (_: Exception) {
            }

            appWidgetManager.updateAppWidget(id, views)
            Log.d(TAG, "steps widget $id updated steps=$steps")
        } catch (e: Exception) {
            Log.e(TAG, "steps bind failed", e)
        }
    }

    companion object {
        private const val TAG = "HelsaStepsWidget"
    }
}
