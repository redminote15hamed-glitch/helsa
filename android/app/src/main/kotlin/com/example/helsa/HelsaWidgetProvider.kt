package com.example.helsa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.content.res.ColorStateList
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Theme-aware home widget. Colors from Flutter:
 * steps_color / cal_color / time_color / widget_bg (ARGB ints).
 * ImageViews should use ids: iv_steps, iv_cal, iv_time (white vectors preferred).
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

            val stepsColor = widgetData.getInt("steps_color", Color.parseColor("#10B981"))
            val calColor = widgetData.getInt("cal_color", Color.parseColor("#FF8C42"))
            val timeColor = widgetData.getInt("time_color", Color.parseColor("#4C8DFF"))
            val bgColor = widgetData.getInt("widget_bg", Color.parseColor("#E6121816"))
            val muted = widgetData.getInt("muted_color", Color.parseColor("#99FFFFFF"))

            val stepsPct = ((steps * 100.0) / stepsGoal).toInt().coerceIn(0, 999)
            val calPct = ((cal * 100.0) / calGoal).toInt().coerceIn(0, 999)
            val minsPct = ((mins * 100.0) / minsGoal).toInt().coerceIn(0, 999)

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

            // Background for contrast
            try {
                views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)
            } catch (_: Exception) {
            }

            // Icon tints (need ImageView ids iv_steps / iv_cal / iv_time)
            tintIcon(views, "iv_steps", stepsColor, context)
            tintIcon(views, "iv_cal", calColor, context)
            tintIcon(views, "iv_time", timeColor, context)

            if (layoutId == R.layout.helsa_widget_medium ||
                layoutId == R.layout.helsa_widget_large
            ) {
                views.setTextViewText(R.id.tv_steps_frac, "$steps / $stepsGoal")
                views.setTextViewText(R.id.tv_cal_frac, "$cal / $calGoal")
                views.setTextViewText(R.id.tv_time_frac, "$mins / $minsGoal")
                views.setTextViewText(R.id.tv_steps_pct, "$stepsPct%")
                views.setTextViewText(R.id.tv_cal_pct, "$calPct%")
                views.setTextViewText(R.id.tv_time_pct, "$minsPct%")
                try {
                    views.setTextColor(R.id.tv_steps_frac, stepsColor)
                    views.setTextColor(R.id.tv_cal_frac, calColor)
                    views.setTextColor(R.id.tv_time_frac, timeColor)
                    views.setTextColor(R.id.tv_steps_pct, stepsColor)
                    views.setTextColor(R.id.tv_cal_pct, calColor)
                    views.setTextColor(R.id.tv_time_pct, timeColor)
                } catch (_: Exception) {
                }
            }

            if (layoutId == R.layout.helsa_widget_large) {
                try {
                    views.setProgressBar(R.id.bar_steps, 100, stepsPct.coerceAtMost(100), false)
                    views.setProgressBar(R.id.bar_cal, 100, calPct.coerceAtMost(100), false)
                    views.setProgressBar(R.id.bar_time, 100, minsPct.coerceAtMost(100), false)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        views.setProgressTintList(R.id.bar_steps, ColorStateList.valueOf(stepsColor))
                        views.setProgressTintList(R.id.bar_cal, ColorStateList.valueOf(calColor))
                        views.setProgressTintList(R.id.bar_time, ColorStateList.valueOf(timeColor))
                    }
                } catch (_: Exception) {
                }
            }

            appWidgetManager.updateAppWidget(id, views)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun tintIcon(views: RemoteViews, name: String, color: Int, context: Context) {
        try {
            val id = context.resources.getIdentifier(name, "id", context.packageName)
            if (id != 0) {
                views.setInt(id, "setColorFilter", color)
            }
        } catch (_: Exception) {
        }
    }
}
