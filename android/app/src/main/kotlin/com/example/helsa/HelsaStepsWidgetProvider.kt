package com.example.helsa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import android.content.res.ColorStateList
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** Single-metric steps widget — theme colors from Flutter. */
class HelsaStepsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.helsa_widget_steps)
                val steps = widgetData.getInt("steps", 0)
                val goal = widgetData.getInt("steps_goal", 8000).coerceAtLeast(1)
                val pct = ((steps * 100.0) / goal).toInt().coerceIn(0, 999)
                val stepsColor = widgetData.getInt("steps_color", Color.parseColor("#10B981"))
                val bgColor = widgetData.getInt("widget_bg", Color.parseColor("#E6121816"))
                val muted = widgetData.getInt("muted_color", Color.parseColor("#99FFFFFF"))
                val unit = widgetData.getString("steps_label", "steps") ?: "steps"

                views.setTextViewText(R.id.tv_steps_big, steps.toString())
                views.setTextViewText(R.id.tv_steps_unit, unit)
                views.setTextViewText(R.id.tv_steps_pct_capsule, "$pct%")
                views.setTextColor(R.id.tv_steps_big, stepsColor)
                views.setTextColor(R.id.tv_steps_unit, muted)
                views.setTextColor(R.id.tv_steps_pct_capsule, stepsColor)

                try {
                    views.setInt(R.id.widget_steps_root, "setBackgroundColor", bgColor)
                } catch (_: Exception) {
                }
                try {
                    val iconId = context.resources.getIdentifier("iv_steps_big", "id", context.packageName)
                    if (iconId != 0) views.setInt(iconId, "setColorFilter", stepsColor)
                } catch (_: Exception) {
                }

                try {
                    views.setProgressBar(R.id.bar_steps_capsule, 100, pct.coerceAtMost(100), false)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        views.setProgressTintList(
                            R.id.bar_steps_capsule,
                            ColorStateList.valueOf(stepsColor)
                        )
                    }
                } catch (_: Exception) {
                }

                appWidgetManager.updateAppWidget(id, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
